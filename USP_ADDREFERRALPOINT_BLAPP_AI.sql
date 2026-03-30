USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_ADDREFERRALPOINT_BLAPP_AI]  
    @ReferralConsumerId INT,    
    @ReferredConsumerId INT,    
    @CompId VARCHAR(10),    
    @ReferralPoint INT,    
    @ReferredPoint INT  
AS    
BEGIN    
    SET NOCOUNT ON;
    DECLARE @CurrentDate DATETIME = GETDATE();  
  
    BEGIN TRY  
        IF (@ReferralPoint = 0 AND @ReferredPoint = 0)  
        BEGIN  
            SELECT -1 AS StatusCode, 'Both Referral and Referred Points are Zero. No action taken.' AS RefResult;  
            RETURN;  
        END  
  
        IF (@ReferralPoint > 0)  
        BEGIN  
            INSERT INTO BLoyaltyPointsEarned (M_Consumerid, Points, UpdateDate, ServiceName, compid)    
            VALUES (@ReferralConsumerId, @ReferralPoint, @CurrentDate, 'Referral', @CompId);    
        END  
  
        IF (@ReferredPoint > 0)  
        BEGIN  
            INSERT INTO BLoyaltyPointsEarned (M_Consumerid, Points, UpdateDate, ServiceName, compid)    
            VALUES (@ReferredConsumerId, @ReferredPoint, @CurrentDate, 'Referral', @CompId);    
        END  
  
        SELECT 0 AS StatusCode, 'Referral Points Added Successfully' AS RefResult;    
    END TRY  
    BEGIN CATCH  
        SELECT -1 AS StatusCode, ERROR_MESSAGE() AS ErrorMessage;    
    END CATCH  
END  
GO
