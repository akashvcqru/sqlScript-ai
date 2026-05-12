-- ====================================================================
-- Stored Procedure: USP_GetFailedTransactionList_AI
-- Purpose: Retrieves detailed list of failed transactions for reporting.
-- Used By: ReprocessTransactionService (Failed Transaction List API)
-- ====================================================================
CREATE OR ALTER PROCEDURE USP_GetFailedTransactionList_AI
    @Comp_ID VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Id, 
        Comp_Id, 
        M_Consumerid, 
        MobileNo, 
        ConsumerName, 
        ConsumerEmailId, 
        Code1, 
        Code2, 
        Amount, 
        UPI_Id, 
        account_no, 
        ifsc_code, 
        benef_name, 
        ReqDate, 
        FinalRemarks 
    FROM tblUPITransactionDetails 
    WHERE Status = 'Failed'
      AND (@Comp_ID IS NULL OR Comp_Id = @Comp_ID)
    ORDER BY ReqDate DESC, Id DESC;
END;
GO
