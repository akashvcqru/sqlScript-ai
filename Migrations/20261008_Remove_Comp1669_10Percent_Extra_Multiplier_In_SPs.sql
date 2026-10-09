-- Migration: 20261008_Remove_Comp1669_10Percent_Extra_Multiplier_In_SPs.sql
-- Purpose: Remove the +10% extra multiplier (* 1.10) for Comp-1669 from all stored procedures,
--          while preserving the date cutoff condition (BL.UpdateDate <= '2026-09-10 19:41:55.383').
--          Both Points and Cash are taken as-is (TRY_CAST without * 1.10 and without fnPointSp).
--          All other companies (including Comp-1274 * 1.10) remain completely untouched.
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
