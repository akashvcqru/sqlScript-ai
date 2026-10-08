-- Migration: 20261008_Fix_CodesActivityReport_Orphan_Points_Mismatch.sql
-- Purpose: Remove 'OR P.MobileNo IS NULL' from the join between #Points and #Enq
--          in SP_BL_GetCodesActivityReport_AI and USP_GetDashboardSummary_AI.
--          Previously, if points were credited to an unmapped/orphaned consumer ID (e.g. 124294)
--          whose MobileNo was NULL, those points incorrectly attached to other users who scanned the code.
--          Removing 'OR P.MobileNo IS NULL' ensures points only attach to scans matching the beneficiary's mobile.
-- Stored Procedures Updated:
--   1. SP_BL_GetCodesActivityReport_AI
--   2. USP_GetDashboardSummary_AI

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. SP_BL_GetCodesActivityReport_AI.sql
-- (Refer to sqlScript/StoredProcedures/SP_BL_GetCodesActivityReport_AI.sql)

-- 2. USP_GetDashboardSummary_AI.sql
-- (Refer to sqlScript/StoredProcedures/USP_GetDashboardSummary_AI.sql)
