-- ====================================================================
-- Stored Procedure: USP_GetFailedTransactionsForReprocess_AI
-- Purpose: Retrieves failed transaction records waiting to be reprocessed.
-- Used By: ReprocessTransactionService (Scenario 1 Execution)
-- ====================================================================
CREATE OR ALTER PROCEDURE USP_GetFailedTransactionsForReprocess_AI
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
        benef_name 
    FROM tblUPITransactionDetails 
    WHERE Status = 'Failed'
      AND (@Comp_ID IS NULL OR Comp_Id = @Comp_ID)
    ORDER BY Id ASC;
END;
GO
