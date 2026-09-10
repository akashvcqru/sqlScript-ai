-- =============================================
-- Migration: 20260910_Create_USP_GetPFLCodeBankHistory_AI
-- Description: Creates stored procedure USP_GetPFLCodeBankHistory_AI to retrieve code generation report from M_Code_PFL
-- =============================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetPFLCodeBankHistory_AI]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ISNULL(SUM(CASE WHEN ISNULL(Use_Count, 0) = 0 THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END), 0) AS FreshCode,
        ISNULL(SUM(CASE WHEN ISNULL(Use_Count, 0) > 0 THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END), 0) AS UseCode,
        ISNULL(SUM(CASE WHEN Print_Date IS NOT NULL THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END), 0) AS PrintCode,
        ISNULL(SUM(CASE WHEN Pro_ID IS NOT NULL AND ISNULL(Use_Count, 0) = 0 THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END), 0) AS UnusedCode
    FROM [dbo].[M_Code_PFL] WITH (NOLOCK)
    OPTION (MAXDOP 0);
END
GO
