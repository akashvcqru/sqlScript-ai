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
    DROP TABLE IF EXISTS #Pro_enq;
    DROP TABLE IF EXISTS #FinalResult;

    ---------------------------------------------------------
    -- GET SUSPICIOUS DUPLICATED CODES
    ---------------------------------------------------------
    SELECT Received_Code1, Received_Code2
    INTO #Pro_enq
    FROM Pro_enq WITH (NOLOCK)
    WHERE Enq_Date >= @StartDate
      AND Enq_Date < @EndDate
      AND is_success = 1
    GROUP BY Received_Code1, Received_Code2
    HAVING COUNT(Enq_date) > 1;

    CREATE CLUSTERED INDEX IX_Pro_enq_codes ON #Pro_enq(Received_Code1, Received_Code2);

    ---------------------------------------------------------
    -- COMPILE COMPREHENSIVE FRAUD CHECK DETAILS
    -- (excl Comp-1669)
    ---------------------------------------------------------
    SELECT DISTINCT
        a.Received_Code1,
        a.Received_Code2,
        aa.Enq_Date,
        aa.MobileNo,
        c.comp_id,
        c.Pro_Name
    INTO #FinalResult
    FROM #Pro_enq a
    INNER JOIN M_Code b WITH (NOLOCK)
        ON a.Received_Code1 = CAST(b.code1 AS VARCHAR(50))
       AND a.Received_Code2 = CAST(b.code2 AS VARCHAR(50))
    INNER JOIN Pro_enq aa WITH (NOLOCK)
        ON a.Received_Code1 = aa.Received_Code1
       AND a.Received_Code2 = aa.Received_Code2
    INNER JOIN Pro_reg c WITH (NOLOCK)
        ON b.Pro_id = c.Pro_id
    WHERE c.comp_id <> 'Comp-1669'
      AND (
          @Search IS NULL OR @Search = ''
          OR a.Received_Code1 LIKE '%' + @Search + '%'
          OR a.Received_Code2 LIKE '%' + @Search + '%'
          OR aa.MobileNo LIKE '%' + @Search + '%'
          OR c.comp_id LIKE '%' + @Search + '%'
          OR c.Pro_Name LIKE '%' + @Search + '%'
      );

    ---------------------------------------------------------
    -- OUTPUT AND PAGINATION
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT Received_Code1, Received_Code2, Enq_Date, MobileNo, comp_id, Pro_Name
        FROM #FinalResult
        ORDER BY Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT Received_Code1, Received_Code2, Enq_Date, MobileNo, comp_id, Pro_Name
        FROM #FinalResult
        ORDER BY Enq_Date DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalResult;
    END
END
GO
