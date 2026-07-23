USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-14
-- Description: Retrieves admin-level fraud code check report (duplicate checks on valid codes) with presets.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetFraudCodeCheck_Admin_AI]
(
    @DatePreset      NVARCHAR(20) = NULL,   -- TODAY, TOMORROW, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, YEAR, ALL, CUSTOM
    @FromDate        NVARCHAR(30) = NULL,
    @ToDate          NVARCHAR(30) = NULL,
    @Search          NVARCHAR(50) = NULL,
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- DATE RANGE SETTING
    ---------------------------------------------------------
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    DECLARE @Preset NVARCHAR(20) = UPPER(ISNULL(@DatePreset, ''));
    IF (@Preset = '' OR @Preset = 'NULL') 
    BEGIN
        IF (@FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
            SET @Preset = 'CUSTOM';
        ELSE
            SET @Preset = 'ALL';
    END

    IF (@Preset = 'TODAY')
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'TOMORROW')
    BEGIN
        SET @StartDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 2, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'YESTERDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
        SET @EndDate   = CAST(GETDATE() AS DATE);
    END
    ELSE IF (@Preset = 'WEEK' OR @Preset = 'THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH' OR @Preset = 'MONTHS')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'YEAR' OR @Preset = 'THIS YEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE -- ALL or default fallback
    BEGIN
        SET @StartDate = CAST('2026-07-07 12:52:32.000' AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    -- CLEANUP TEMP TABLES
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #TempResult;

    ---------------------------------------------------------
    -- GET SUSPICIOUS DUPLICATED CODES
    -- (excl Comp-1669)
    ---------------------------------------------------------
    SELECT 
        a.comp_id,
        b.Comp_Name,
        b.Status, 
        a.Received_Code1,
        a.Received_Code2,
        a.IS_Success,
        COUNT(1) AS [TotalCheckCount]
    INTO #TempResult
    FROM Pro_enq a WITH (NOLOCK)
    INNER JOIN Comp_Reg b WITH (NOLOCK) ON a.Comp_ID = b.Comp_ID 
    WHERE a.Enq_Date >= @StartDate
      AND a.Enq_Date < @EndDate
      AND a.Comp_ID NOT IN ('comp-1669', '')
      AND a.IS_Success = '1'
      AND (
          @Search IS NULL OR @Search = ''
          OR a.Received_Code1 LIKE '%' + @Search + '%'
          OR a.Received_Code2 LIKE '%' + @Search + '%'
          OR a.Comp_ID LIKE '%' + @Search + '%'
          OR b.Comp_Name LIKE '%' + @Search + '%'
      )
    GROUP BY a.comp_id, b.Comp_Name, b.Status, a.Received_Code1, a.Received_Code2, a.IS_Success
    HAVING COUNT(1) > 1;

    ---------------------------------------------------------
    -- OUTPUT AND PAGINATION
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT 
            comp_id, 
            Comp_Name,
            Status as comp_status, 
            Received_Code1, 
            Received_Code2, 
            IS_Success,
            TotalCheckCount
        FROM #TempResult
        ORDER BY TotalCheckCount DESC, comp_id;
    END
    ELSE
    BEGIN
        SELECT 
            comp_id, 
            Comp_Name,
            Status as comp_status, 
            Received_Code1, 
            Received_Code2, 
            IS_Success,
            TotalCheckCount
        FROM #TempResult
        ORDER BY TotalCheckCount DESC, comp_id
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #TempResult;
    END

    DROP TABLE IF EXISTS #TempResult;
END
GO
