USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- DEPRECATED: Stored Procedure SP_FailedTransactionSummaryAdmin_AI
-- This procedure has been deprecated and removed.
-- /api/AdminVendorReport/FailedTransactionSummary now uses
-- USP_GetFailedTransactionList_AI (the SP used by
-- /api/vendor/failedTransactions/FailedtransactionList).
-- ====================================================================
IF OBJECT_ID('dbo.SP_FailedTransactionSummaryAdmin_AI', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[SP_FailedTransactionSummaryAdmin_AI];
END
GO
