-- Migration: 20261007_Fix_Comp1669_Cash_10Percent_Multiplier_In_SPs.sql
-- Purpose: Fix Comp-1669 points calculation in all stored procedures by applying the +10% multiplier (* 1.10)
--          consistently to BOTH Points and Cash columns for scans on or before '2026-09-10 19:41:55.383'.
-- Problem: The procedures previously multiplied only BL.Points by 1.10, but took BL.Cash 1:1 without the 10% bonus.
--          Because Comp-1669 earnings are primarily recorded in BL.Cash (SRV1028 Instant Payout), reports understated
--          users' earned value while claim/redemption payouts had paid out the full 10% bonus, resulting in artificial
--          negative balances for 31+ users.
-- Stored Procedures Updated:
--   1. SP_BL_GetBeneficiariesReport
--   2. SP_BL_GetBeneficiariesReport_Admin_AI
--   3. SP_BL_GetCodesActivityReport_AI
--   4. SP_BL_GetCodesActivityReport_AI_FillData
--   5. USP_GetDashboardSummary_AI
--   6. USP_GetHighValuePaymentRequests_Admin_AI

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. SP_BL_GetBeneficiariesReport.sql
-- (Refer to sqlScript/StoredProcedures/SP_BL_GetBeneficiariesReport.sql)

-- 2. SP_BL_GetBeneficiariesReport_Admin_AI.sql
-- (Refer to sqlScript/StoredProcedures/SP_BL_GetBeneficiariesReport_Admin_AI.sql)

-- 3. SP_BL_GetCodesActivityReport_AI.sql
-- (Refer to sqlScript/StoredProcedures/SP_BL_GetCodesActivityReport_AI.sql)

-- 4. SP_BL_GetCodesActivityReport_AI_FillData.sql
-- (Refer to sqlScript/StoredProcedures/SP_BL_GetCodesActivityReport_AI_FillData.sql)

-- 5. USP_GetDashboardSummary_AI.sql
-- (Refer to sqlScript/StoredProcedures/USP_GetDashboardSummary_AI.sql)

-- 6. USP_GetHighValuePaymentRequests_Admin_AI.sql
-- (Refer to sqlScript/StoredProcedures/USP_GetHighValuePaymentRequests_Admin_AI.sql)
