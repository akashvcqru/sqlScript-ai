-- =========================================================================
-- Migration: 20260903_Update_DailyScanLimit_Is_Success_Filter.sql
-- Description: Add Is_Success = '1' filter to vendor daily scan limit check
--              in USP_ACCodeCheck_Unified_AI, USP_BLCodeCheck_Unified_AI,
--              and USP_BLCodeCheckInstantCash_AI so that only genuine /
--              successful scans count towards daily limit.
-- =========================================================================

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Update USP_ACCodeCheck_Unified_AI
PRINT 'Updating USP_ACCodeCheck_Unified_AI with Is_Success = ''1'' daily limit check...';
GO

-- (Procedure script is kept updated in StoredProcedures/USP_ACCodeCheck_Unified_AI.sql)
-- Run the procedure script or apply directly.
GO

-- 2. Update USP_BLCodeCheck_Unified_AI
PRINT 'Updating USP_BLCodeCheck_Unified_AI with Is_Success = ''1'' daily limit check...';
GO

-- 3. Update USP_BLCodeCheckInstantCash_AI
PRINT 'Updating USP_BLCodeCheckInstantCash_AI with Is_Success = ''1'' daily limit check...';
GO
