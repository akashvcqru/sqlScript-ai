CREATE PROCEDURE [dbo].[SP_GetUserPayOut_ByMobile_AI]  
(  
    @CompId NVARCHAR(15),  
    @MobileNumber NVARCHAR(20)  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE @ActualCompId NVARCHAR(15);  
  
    SET @ActualCompId = REPLACE(@CompId, 'Comp-', '');  
  
    SELECT  
        Account_no as AccountNumber,  
        ifsc_code as  IFSCCode,  
  amount_won,  
        NetPaid,  
  tdsAmount,  
        payStatus AS TransactionStatus,  
        ISNULL(CONVERT(VARCHAR(19), TransactionDate, 120), '') AS TransactionDate  
    FROM TBL_M_Star_Codeverification  
    WHERE Mobile_Number = @MobileNumber  
      AND Comp_Id = @CompId;  
END
