USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_GetUserPayOut_ByMobile_AI]    Script Date: 6/10/2026 11:32:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SP_GetUserPayOut_ByMobile_AI]  
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
      --  payStatus AS TransactionStatus,  

CASE
    WHEN status = 'Success' THEN CAST(1 AS BIT)
    ELSE CAST(0 AS BIT)
END AS TransactionStatus,
        ISNULL(CONVERT(VARCHAR(19), enquiry_date, 120), '') AS TransactionDate  ,completecode
    FROM TBL_M_Star_Codeverification  
    WHERE Mobile_Number = @MobileNumber  
      AND Comp_Id = @CompId;  
END