/****** Object:  StoredProcedure [dbo].[Proc_SaveCodeDtsForBuiltLoyalty_BL_AI]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[Proc_SaveCodeDtsForBuiltLoyalty_BL_AI]  
(        
    @code1 NVARCHAR(50) = '',        
    @code2 NVARCHAR(50) = '',        
    @SST_Id INT,        
    @intM_Consumer_MCode BIGINT        
)        
AS        
BEGIN  
    BEGIN TRY  
        DECLARE @AwardNameBL NVARCHAR(50),   
                @AwardName_RowID NVARCHAR(50),   
                @Service_ID NVARCHAR(50) = '',   
                @ccompid NVARCHAR(50),   
                @Pro_ID VARCHAR(20),   
                @M_Consumerid BIGINT,  
                @Pkid BIGINT,   
                @chkloyalty INT,  
                @Points INT = 0,  
                @Frequency INT = 1,  
                @IsCashConvert INT = 0,  
                @IsCash INT = 0,  
                @totalecodes INT,  
                @usedcode INT,  
                @sub_id NVARCHAR(MAX),  
                @BLoyalty_PointEarnedID BIGINT,  
                @countFrequncy BIGINT,  
                @t INT,  
                @t3 INT;  
  
        BEGIN TRANSACTION;  
  
        SELECT @M_Consumerid = m_consumerid, @ccompid = Compid, @Pro_ID = Pro_id   
        FROM M_Consumer_M_Code (NOLOCK) WHERE M_Consumer_MCodeid = @intM_Consumer_MCode;  
  
        INSERT INTO BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate)  
        VALUES (@SST_Id, @intM_Consumer_MCode, @M_Consumerid, GETDATE());  
  
        SELECT @chkloyalty = loyalty FROM m_code_loyalty WHERE code1 = CONVERT(NVARCHAR(5), @code1) AND code2 = CONVERT(NVARCHAR(8), @code2);  
  
        SET @Pkid = SCOPE_IDENTITY();  
  
        -- Get Points from configuration
        SELECT @Points = CASE WHEN @chkloyalty IS NULL OR @chkloyalty = 0 THEN ISNULL(Points, 0) ELSE @chkloyalty END,  
            @Frequency = ISNULL(Frequency, 1), @IsCashConvert = ISNULL(IsCashConvert, 0),   
            @IsCash = CASE WHEN @chkloyalty IS NULL OR @chkloyalty = 0 THEN ISNULL(IsCash, 0) ELSE @Points END  
        FROM M_ServiceSubscriptionTrans (NOLOCK) WHERE SST_Id = @SST_Id;  
  
        -- Get Consumer's UserType and UserTypeId
        DECLARE @CurrentUserType NVARCHAR(100) = 'User';
        DECLARE @CurrentUserTypeId INT = NULL;
        DECLARE @OtherRole NVARCHAR(100) = NULL;

        SELECT TOP 1 
            @CurrentUserType = COALESCE(ut.User_Type, mc.Other_Role, 'User'),
            @OtherRole = mc.Other_Role,
            @CurrentUserTypeId = COALESCE(vk.Vrkabel_User_Type, mc.Vrkabel_User_Type)
        FROM dbo.M_Consumer mc WITH (NOLOCK)
        LEFT JOIN dbo.tbl_Vendorvisekycstatus vk WITH (NOLOCK) 
            ON mc.M_Consumerid = vk.M_consumerid AND vk.Comp_id = @ccompid
        LEFT JOIN dbo.User_Type ut WITH (NOLOCK) 
            ON CAST(COALESCE(vk.Vrkabel_User_Type, mc.Vrkabel_User_Type) AS VARCHAR) = CAST(ut.Row_ID AS VARCHAR) 
            AND ut.Comp_ID = @ccompid
        WHERE mc.M_Consumerid = @M_Consumerid AND mc.IsDelete = 0;

        -- 1. Check tbl_M_Code_USERFrequency first for role-specific points and frequency
        DECLARE @UserFreqPoints INT = NULL;
        DECLARE @UserFreqCount INT = NULL;

        SELECT TOP 1 
            @UserFreqPoints = AssignPoint,
            @UserFreqCount = Frequency
        FROM dbo.tbl_M_Code_USERFrequency WITH (NOLOCK)
        WHERE Code1 = TRY_CAST(@code1 AS INT) 
          AND Code2 = TRY_CAST(@code2 AS INT)
          AND (Comp_id = @ccompid OR Comp_id IS NULL OR @ccompid IS NULL)
          AND (
              LOWER(TRIM(UserTypeRole)) = LOWER(TRIM(@CurrentUserType))
              OR CAST(UserTypeRole AS VARCHAR) = CAST(@CurrentUserTypeId AS VARCHAR)
          )
          AND ISNULL(Isdelete, 0) = 0;

        IF @UserFreqPoints IS NOT NULL
        BEGIN
            SET @Points = @UserFreqPoints;
            SET @IsCash = @UserFreqPoints;
            IF @UserFreqCount IS NOT NULL AND @UserFreqCount > 0
            BEGIN
                SET @Frequency = @UserFreqCount;
            END
        END
  
        SELECT @countFrequncy = COUNT(pkid) FROM BuiltLoyaltyMCodeCheck (NOLOCK)   
        WHERE sst_id = @SST_Id AND M_Cunsumerid = @M_Consumerid;  
  
        IF (@countFrequncy <= @Frequency)  
        BEGIN  
            SET @t = @countFrequncy % @Frequency;  
  
            IF (@Service_ID = '')  
            BEGIN  
                SELECT @Service_ID = Service_ID FROM M_Service WHERE Service_ID IN   
                    (SELECT Service_ID FROM M_ServiceSubscription (NOLOCK) WHERE Subscribe_Id IN   
                        (SELECT Subscribe_Id FROM M_ServiceSubscriptionTrans (NOLOCK) WHERE SST_Id = @SST_Id));  
            END  
  
			 IF (@ccompid = 'Comp-1869' OR @ccompid = 'Comp-1727' OR @ccompid = 'Comp-1900')
			 BEGIN 
				 INSERT INTO BLoyaltyPointsEarned_Temp (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, Cash,Points, ServiceName)  
				 VALUES (@Pkid, @SST_Id, @M_Consumerid, GETDATE(), @code1, @code2, @ccompid, @IsCash, @Points, @Service_ID);  
			 END

            INSERT INTO BLoyaltyPointsEarned (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, Points, Cash, ServiceName)  
            VALUES (@Pkid, @SST_Id, @M_Consumerid, GETDATE(), @code1, @code2, @ccompid, @Points, @IsCash, @Service_ID);  
  
            SET @BLoyalty_PointEarnedID = SCOPE_IDENTITY();  
  
            IF (@Service_ID IN ('SRV1001', 'SRV1029'))  
            BEGIN  				
                UPDATE BLoyaltyPointsEarned 
                SET ServiceName = CASE WHEN ServiceName IS NULL OR ServiceName = '' THEN 'buildloyalty' ELSE ServiceName END
                WHERE BLoyalty_PointEarnedID = @BLoyalty_PointEarnedID;  
  
                IF (@ccompid = 'Comp-1232' AND @Pro_ID IN ('AG02', 'AG49', 'AG51'))  
                BEGIN  
                    EXEC Sp_InsupdWalletbalance @M_Consumerid = @M_Consumerid, @Points = @Points, @TransactionType = 'Credit';  
                END  
  
				IF EXISTS (SELECT 1 FROM tbl_pointmultiplier WITH (NOLOCK) WHERE Comp_Id = @ccompid  AND IsActive = 1 AND CodeScanCount >0)
				BEGIN 
					EXEC Sp_InsupdExtraPointBL @M_Consumerid = @M_Consumerid, @Points = @Points, @BLoyalty_PointEarnedID = @BLoyalty_PointEarnedID,@ccompid=@ccompid,@code1=@code1,@code2=@code2
				END 
            END  
            ELSE IF (@Service_ID = 'SRV1005')  
            BEGIN  
                UPDATE BLoyaltyPointsEarned SET Cash = ISNULL(Cash, 0) + @IsCash, ServiceName = 'cash' WHERE BLoyalty_PointEarnedID = @BLoyalty_PointEarnedID;  
            END  
  
            UPDATE BuiltLoyaltyMCodeCheck SET IsPointsAssigned = 1 WHERE pkid = @Pkid;

            UPDATE tbl_M_Code_USERFrequency
            SET Use_count = ISNULL(Use_count, 0) + 1
            WHERE Code1 = TRY_CAST(@code1 AS INT)
              AND Code2 = TRY_CAST(@code2 AS INT)
              AND (
                  LOWER(TRIM(UserTypeRole)) = LOWER(TRIM(@CurrentUserType))
                  OR CAST(UserTypeRole AS VARCHAR) = CAST(@CurrentUserTypeId AS VARCHAR)
              );  
            COMMIT TRANSACTION;  
            SELECT @t AS ReachedFrequency, @IsCashConvert AS IsCashConvert, @Points AS Points2, @Points AS Points, @IsCash AS Iscash, @AwardNameBL AS AwardNameBL, * FROM BLoyaltyPointsEarned (NOLOCK) WHERE BLoyalty_PointEarnedID = @BLoyalty_PointEarnedID;  
        END  
        ELSE  
        BEGIN  
            SELECT (@Frequency - @countFrequncy) AS ReachedFrequency, @IsCashConvert AS IsCashConvert, 0 AS Points2, 0 AS Points, @IsCash AS Iscash, @AwardNameBL AS AwardNameBL;  
            COMMIT TRANSACTION;  
        END  
    END TRY  
    BEGIN CATCH  
        ROLLBACK TRANSACTION;  
        DECLARE @ErrorMessage NVARCHAR(MAX), @ErrorSeverity INT, @ErrorState INT;  
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
        EXEC dbo.GetErrorInfo;  
        THROW;  
    END CATCH;  
END
GO
