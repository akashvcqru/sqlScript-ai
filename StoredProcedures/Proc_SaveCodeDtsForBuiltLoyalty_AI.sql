/****** Object:  StoredProcedure [dbo].[Proc_SaveCodeDtsForBuiltLoyalty_AI]    Script Date: 5/6/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[Proc_SaveCodeDtsForBuiltLoyalty_AI]  
(        
    @code1 NVARCHAR(50) = '',        
    @code2 NVARCHAR(50) = '',        
    @SST_Id INT,        
    @intM_Consumer_MCode BIGINT,
    @assignpoint INT = NULL,
    @MobileNo NVARCHAR(50) = ''
)        
AS        
BEGIN  
    SET NOCOUNT ON;
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
                @BLoyalty_PointEarnedID BIGINT,  
                @countFrequncy BIGINT,  
                @t INT;  
  
        BEGIN TRANSACTION;  
  
        SELECT @M_Consumerid = mcc.m_consumerid, @ccompid = mcc.Compid, @Pro_ID = mcc.Pro_id   
        FROM M_Consumer_M_Code mcc (NOLOCK)
        INNER JOIN M_Code mc (NOLOCK) ON mcc.M_Codeid = mc.Row_ID
        WHERE mcc.M_Consumer_MCodeid = @intM_Consumer_MCode
          AND mc.Code1 = TRY_CAST(@code1 AS NUMERIC(18,0))
          AND mc.Code2 = TRY_CAST(@code2 AS NUMERIC(18,0));  
  
        IF @M_Consumerid IS NULL AND ISNULL(@intM_Consumer_MCode, 0) > 0
        BEGIN
            SELECT TOP 1 @M_Consumerid = mc.M_Consumerid
            FROM Pro_Enq pe (NOLOCK)
            INNER JOIN m_consumer mc (NOLOCK) ON RIGHT(pe.MobileNo, 10) = RIGHT(mc.MobileNo, 10)
            WHERE pe.Row_id = @intM_Consumer_MCode AND mc.IsDelete = 0
            ORDER BY mc.Entry_Date DESC;
        END

        IF @M_Consumerid IS NULL OR @M_Consumerid = 0
        BEGIN
            SELECT TOP 1 @M_Consumerid = mc.M_Consumerid
            FROM Pro_Enq pe (NOLOCK)
            INNER JOIN m_consumer mc (NOLOCK) ON RIGHT(pe.MobileNo, 10) = RIGHT(mc.MobileNo, 10)
            WHERE pe.Received_Code1 = @code1
              AND pe.Received_Code2 = @code2
              AND mc.IsDelete = 0
            ORDER BY pe.Enq_Date DESC, mc.Entry_Date DESC;
        END

        IF (@M_Consumerid IS NULL OR @M_Consumerid = 0) AND LEN(ISNULL(@MobileNo, '')) >= 10
        BEGIN
            SELECT TOP 1 @M_Consumerid = M_Consumerid
            FROM M_Consumer (NOLOCK)
            WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
            ORDER BY Entry_Date DESC;
        END
        IF @ccompid IS NULL OR @Pro_ID IS NULL
            SELECT TOP 1 @ccompid = p.Comp_ID, @Pro_ID = c.Pro_ID 
            FROM M_Code c (NOLOCK) 
            INNER JOIN Pro_Reg p (NOLOCK) ON c.Pro_ID = p.Pro_ID
            WHERE c.Code1 = @code1 AND c.Code2 = @code2;
        INSERT INTO BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate)  
        VALUES (@SST_Id, @intM_Consumer_MCode, @M_Consumerid, GETDATE());  
  
        SET @Pkid = SCOPE_IDENTITY();  

        SELECT @chkloyalty = loyalty FROM m_code_loyalty WHERE code1 = CONVERT(NVARCHAR(5), @code1) AND code2 = CONVERT(NVARCHAR(8), @code2);  
  
        SELECT @Points = CASE WHEN @chkloyalty IS NULL OR @chkloyalty = 0 THEN ISNULL(Points, 0) ELSE @chkloyalty END,  
            @Frequency = ISNULL(Frequency, 1), 
            @IsCashConvert = ISNULL(IsCashConvert, 0),   
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

        IF @assignpoint IS NOT NULL
        BEGIN
            SET @Points = @assignpoint;
            SET @IsCash = @assignpoint;
        END

        SELECT @countFrequncy = COUNT(pkid) FROM BuiltLoyaltyMCodeCheck (NOLOCK)   
        WHERE sst_id = @SST_Id AND M_Cunsumerid = @M_Consumerid AND @M_Consumerid IS NOT NULL AND @M_Consumerid > 0;  
  
        IF (@countFrequncy <= @Frequency)  
        BEGIN  
            SET @t = @countFrequncy % @Frequency;  
  
            SELECT @Service_ID = Service_ID FROM M_Service WHERE Service_ID IN   
                (SELECT Service_ID FROM M_ServiceSubscription (NOLOCK) WHERE Subscribe_Id IN   
                    (SELECT Subscribe_Id FROM M_ServiceSubscriptionTrans (NOLOCK) WHERE SST_Id = @SST_Id));  
  
            IF (@Service_ID IN ('SRV1029', 'SRV1005') OR @IsCashConvert = 1)
            BEGIN
                IF @IsCash = 0 OR @IsCash IS NULL
                BEGIN
                    SET @IsCash = @Points;
                END
            END

            IF (@ccompid IN ('Comp-1869', 'Comp-1727', 'Comp-1900'))
            BEGIN 
                IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BLoyaltyPointsEarned_Temp]') AND type in (N'U'))
                BEGIN
                    INSERT INTO BLoyaltyPointsEarned_Temp (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, Cash, Points, ServiceName)  
                    VALUES (@Pkid, @SST_Id, @M_Consumerid, GETDATE(), @code1, @code2, @ccompid, @IsCash, @Points, @Service_ID);  
                END
            END

            INSERT INTO BLoyaltyPointsEarned (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, Points, Cash, ServiceName)  
            VALUES (@Pkid, @SST_Id, @M_Consumerid, GETDATE(), @code1, @code2, @ccompid, @Points, @IsCash, @Service_ID);  

            DECLARE @PE_ID INT = NULL;
            IF EXISTS (
                SELECT 1 FROM M_Consumer_M_Code mcc (NOLOCK)
                INNER JOIN M_Code mc (NOLOCK) ON mcc.M_Codeid = mc.Row_ID
                WHERE mcc.M_Consumer_MCodeid = @intM_Consumer_MCode
                  AND mc.Code1 = TRY_CAST(@code1 AS NUMERIC(18,0))
                  AND mc.Code2 = TRY_CAST(@code2 AS NUMERIC(18,0))
            )
            BEGIN
                DECLARE @MobileNo_val NVARCHAR(50);
                SELECT @MobileNo_val = MobileNo FROM M_Consumer (NOLOCK) WHERE M_Consumerid = @M_Consumerid;

                SELECT TOP 1 @PE_ID = Row_id
                FROM Pro_Enq (NOLOCK)
                WHERE TRY_CAST(Received_Code1 AS NUMERIC(18,0)) = TRY_CAST(@code1 AS NUMERIC(18,0)) 
                  AND TRY_CAST(Received_Code2 AS NUMERIC(18,0)) = TRY_CAST(@code2 AS NUMERIC(18,0))
                  AND RIGHT(MobileNo, 10) = RIGHT(@MobileNo_val, 10)
                ORDER BY Enq_Date DESC;
            END
            ELSE
            BEGIN
                SET @PE_ID = @intM_Consumer_MCode;
            END

            UPDATE [dbo].[ConsumerPointsCashDetails]
            SET Points = ISNULL(Points, 0) + @Points, 
                Cash = ISNULL(Cash, 0) + @IsCash,
                SST_Id = @SST_Id,
                Service_ID = @Service_ID
            WHERE PE_ID = @PE_ID;
  
            SET @BLoyalty_PointEarnedID = SCOPE_IDENTITY();  
  
            IF (@Service_ID IN ('SRV1001', 'SRV1029'))  
            BEGIN  				
                UPDATE BLoyaltyPointsEarned 
                SET ServiceName = CASE WHEN ServiceName IS NULL OR ServiceName = '' THEN 'buildloyalty' ELSE ServiceName END 
                WHERE BLoyalty_PointEarnedID = @BLoyalty_PointEarnedID;  
            END  
            ELSE IF (@Service_ID = 'SRV1005')  
            BEGIN  
                UPDATE BLoyaltyPointsEarned 
                SET ServiceName = 'cash' 
                WHERE BLoyalty_PointEarnedID = @BLoyalty_PointEarnedID;  
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
            
            SELECT @t AS ReachedFrequency, @IsCashConvert AS IsCashConvert, @Points AS Points2, @Points AS Points, @IsCash AS Iscash, @AwardNameBL AS AwardNameBL, * 
            FROM BLoyaltyPointsEarned (NOLOCK) WHERE BLoyalty_PointEarnedID = @BLoyalty_PointEarnedID;  
        END  
        ELSE  
        BEGIN  
            SELECT (@Frequency - @countFrequncy) AS ReachedFrequency, @IsCashConvert AS IsCashConvert, 0 AS Points2, 0 AS Points, @IsCash AS Iscash, @AwardNameBL AS AwardNameBL;  
            COMMIT TRANSACTION;  
        END  
    END TRY  
    BEGIN CATCH  
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;  
        DECLARE @ErrorMessage NVARCHAR(MAX), @ErrorSeverity INT, @ErrorState INT;  
        SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
        EXEC dbo.GetErrorInfo;  
        THROW;  
    END CATCH;  
END
GO
