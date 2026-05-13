USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetFailedTransactionsForReprocess_AI]    Script Date: 5/13/2026 4:45:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================================================
-- Stored Procedure: USP_GetFailedTransactionsForReprocess_AI
-- Purpose: Retrieves failed transaction records waiting to be reprocessed.
-- Used By: ReprocessTransactionService (Scenario 1 Execution)
-- ====================================================================
ALTER   PROCEDURE [dbo].[USP_GetFailedTransactionsForReprocess_AI]
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
		Remarks,
		FinalRemarks,
		FinalStatus
    FROM tblUPITransactionDetails 
    WHERE Status = 'Failed' and Remarks in(
	'Insufficient wallet balance for debit'
	,'Service Provider Downtime'
	,'Insufficient Wallet Balance'
	,'BENEFICIARY BANK IS DOWN',
	'Beneficiary Bank is not responding, try again later'
	,'TRANSACTION TYPE NOT SUPPORTED'
	) and LEN(Code1)=5 and LEN(Code2)=8
	and Comp_Id=@Comp_ID
      AND ReqDate >'2026-05-10 00:00:17.100'
    ORDER BY Id ASC;
END;
