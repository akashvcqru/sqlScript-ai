USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Migration: 20260903_Drop_USP_GetFailedTransactionSummaryAdmin_AI.sql
-- Purpose: Remove USP_GetFailedTransactionSummaryAdmin_AI and 
--          SP_FailedTransactionSummaryAdmin_AI.
--          /api/AdminVendorReport/FailedTransactionSummary now uses
--          USP_GetFailedTransactionList_AI (the same SP used by
--          /api/vendor/failedTransactions/FailedtransactionList).
-- ====================================================================

IF OBJECT_ID('dbo.USP_GetFailedTransactionSummaryAdmin_AI', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[USP_GetFailedTransactionSummaryAdmin_AI];
END
GO

IF OBJECT_ID('dbo.SP_FailedTransactionSummaryAdmin_AI', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[SP_FailedTransactionSummaryAdmin_AI];
END
GO
