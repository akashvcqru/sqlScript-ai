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
    @assignpoint INT = NULL  
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
  
        SELECT @M_Consumerid = m_consumerid, @ccompid = Compid, @Pro_ID = Pro_id   
        FROM M_Consumer_M_Code (NOLOCK) WHERE M_Consumer_MCodeid = @intM_Consumer_MCode;  
  
        INSERT INTO BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate)  
        VALUES (@SST_Id, @intM_Consumer_MCode, @M_Consumerid, GETDATE());  
  
        SET @Pkid = SCOPE_IDENTITY();  

        SELECT @chkloyalty = loyalty FROM m_code_loyalty WHERE code1 = CONVERT(NVARCHAR(5), @code1) AND code2 = CONVERT(NVARCHAR(8), @code2);  
  
        SELECT @Points = CASE WHEN @chkloyalty IS NULL OR @chkloyalty = 0 THEN ISNULL(Points, 0) ELSE @chkloyalty END,  
            @Frequency = ISNULL(Frequency, 1), 
            @IsCashConvert = ISNULL(IsCashConvert, 0),   
            @IsCash = CASE WHEN @chkloyalty IS NULL OR @chkloyalty = 0 THEN ISNULL(IsCash, 0) ELSE @Points END  
        FROM M_ServiceSubscriptionTrans (NOLOCK) WHERE SST_Id = @SST_Id;  
  
        IF @assignpoint IS NOT NULL
        BEGIN
            SET @Points = @assignpoint;
        END

        SELECT @countFrequncy = COUNT(pkid) FROM BuiltLoyaltyMCodeCheck (NOLOCK)   
        WHERE sst_id = @SST_Id AND M_Cunsumerid = @M_Consumerid AND ISNULL(IsPointsAssigned, 0) = 0;  
  
        IF (@countFrequncy <= @Frequency)  
        BEGIN  
            SET @t = @countFrequncy % @Frequency;  
  
            SELECT @Service_ID = Service_ID FROM M_Service WHERE Service_ID IN   
                (SELECT Service_ID FROM M_ServiceSubscription (NOLOCK) WHERE Subscribe_Id IN   
                    (SELECT Subscribe_Id FROM M_ServiceSubscriptionTrans (NOLOCK) WHERE SST_Id = @SST_Id));  
  
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

            UPDATE [dbo].[ConsumerPointsCashDetails]
            SET Points = @Points, Cash = @IsCash
            WHERE PE_ID = @intM_Consumer_MCode;
  
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
  
            UPDATE BuiltLoyaltyMCodeCheck SET IsPointsAssigned = 1 WHERE sst_id = @SST_Id AND M_Cunsumerid = @M_Consumerid;  
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
