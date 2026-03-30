CREATE PROCEDURE [dbo].[USP_CheckUPILimit_AI]  
    @CompId VARCHAR(50),  
    @ServiceId VARCHAR(50),  
    @ClaimAmount FLOAT  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE   
        @DailyLimit FLOAT,  
        @UsedLimit FLOAT,  
        @AvailableLimit FLOAT;  
  
    -- Get used limit for today  
    SELECT @UsedLimit = ISNULL(SUM(Amount), 0)  
    FROM tblUPITransactionDetails  
    WHERE Comp_Id = @CompId  
      AND Status = 'Success'  
      AND CAST(ReqDate AS DATE) = CAST(GETDATE() AS DATE);  
  
    -- Get daily limit from master table  
    SELECT @DailyLimit = ISNULL(Daily_Limit, 0)  
    FROM tbl_UPILimitDetails  
    WHERE Comp_ID = @CompId  
      AND Service_ID = @ServiceId  
      AND IsClaimReq = 1  
      AND IsApprovalReq = 0;  
  
    -- Calculate available limit  
    SET @AvailableLimit = @DailyLimit - @UsedLimit;  
  
    -- Compare with requested claim amount  
    IF (@AvailableLimit < @ClaimAmount)  
    BEGIN  
        select  'Limit not available';  
    END  
    ELSE  
    BEGIN  
        select   '1';  
    END  
END;  
GO
