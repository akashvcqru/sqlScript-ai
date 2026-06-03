USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_AntiCounterFeitSolutions_AI]    Script Date: 4/7/2026 12:16:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI Assistant
-- Create date: 2026-04-07
-- Description: Get Anti-Counterfeit solutions data (Success vs Unsuccess scans)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_AntiCounterFeitSolutions_AI]
    @Comp_Id VARCHAR(20),
    @datePreset NVARCHAR(20) = NULL
AS      
BEGIN      
    SET NOCOUNT ON;

    ------------------------------------------------------
    -- Company start date
    ------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;

    SELECT @CompanyStartDate = Reg_Date
    FROM Comp_Reg
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    ------------------------------------------------------
    -- Calendar based Date Window
    ------------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

    IF @Win = 'TODAY'
    BEGIN
        SET @StartDate = @Today;
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YESTERDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, @Today);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'WEEK'
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE =
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);

        SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
        SET @EndDate   = @ThisWeekStart;
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE =
            DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);

        SET @StartDate = DATEADD(MONTH, -1, @ThisMonthStart);
        SET @EndDate   = @ThisMonthStart;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTYEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(@Today), 1, 1);
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END

    ------------------------------------------------------
    -- Step 1: Pre-filter M_Code (Deduplicated per code pair)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    CREATE TABLE #tempM_Code (
        Code1 VARCHAR(100),
        Code2 VARCHAR(100),
        Pro_ID VARCHAR(50)
    );

    IF @Comp_Id = 'Comp-1693'
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code_PFL a 
            INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_Id 
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID)
        SELECT Code1, Code2, Pro_ID
        FROM DistinctCodes
        WHERE rn = 1;
    END
    ELSE
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code a 
            INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_Id 
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID)
        SELECT Code1, Code2, Pro_ID
        FROM DistinctCodes
        WHERE rn = 1;
    END

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);

    ------------------------------------------------------
    -- Step 2: Prepare scan data
    ------------------------------------------------------
    DROP TABLE IF EXISTS #ValidScans;

    SELECT
        CAST(pe.Enq_Date AS DATE) AS ScanDate,
        pe.Is_Success,
        CASE WHEN mc.Pro_ID IS NOT NULL THEN 1 ELSE 0 END AS CodeExists
    INTO #ValidScans
    FROM Pro_Enq pe WITH (NOLOCK)
    LEFT JOIN #tempM_Code mc ON LTRIM(RTRIM(CAST(mc.Code1 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
          AND LTRIM(RTRIM(CAST(mc.Code2 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
    WHERE pe.Comp_ID = @Comp_Id
      AND pe.Enq_Date >= @StartDate
      AND pe.Enq_Date <  @EndDate
      AND pe.Enq_Date >= @CompanyStartDate;

    ------------------------------------------------------
    -- Result Set 1: Periodic Data
    ------------------------------------------------------
    IF @Win IN ('MONTH', 'LASTMONTH', '')
    BEGIN
        DROP TABLE IF EXISTS #WeekSummary;

        SELECT
            DATEDIFF(WEEK,
                DATEADD(MONTH, DATEDIFF(MONTH, 0, ScanDate), 0),
                ScanDate
            ) + 1 AS WeekNumber,
            SUM(CASE WHEN CodeExists = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS Success,
            SUM(CASE WHEN CodeExists = 0 OR Is_Success <> 1 THEN 1 ELSE 0 END) AS UnSuccess
        INTO #WeekSummary
        FROM #ValidScans
        GROUP BY
            DATEDIFF(WEEK,
                DATEADD(MONTH, DATEDIFF(MONTH, 0, ScanDate), 0),
                ScanDate
            ) + 1;

        DECLARE @MaxWeek INT;

        IF @Win = 'MONTH' OR @Win = ''
            SET @MaxWeek =
                DATEDIFF(WEEK,
                    DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0),
                    @Today
                ) + 1;
        ELSE
            SET @MaxWeek =
                DATEDIFF(WEEK,
                    DATEADD(MONTH, DATEDIFF(MONTH, 0, @StartDate), 0),
                    DATEADD(DAY, -1, @EndDate)
                ) + 1;

        ;WITH WeekNums AS
        (
            SELECT 1 AS WeekNo
            UNION ALL
            SELECT WeekNo + 1 FROM WeekNums WHERE WeekNo < @MaxWeek
        )
        SELECT
            'Week ' + CAST(w.WeekNo AS VARCHAR(2)) AS Label,
            ISNULL(s.Success, 0)   AS Success,
            ISNULL(s.UnSuccess, 0) AS UnSuccess
        FROM WeekNums w
        LEFT JOIN #WeekSummary s ON s.WeekNumber = w.WeekNo
        ORDER BY w.WeekNo
        OPTION (MAXRECURSION 10);

        -- Result Set 2: Total Summary
        SELECT
            ISNULL(SUM(Success), 0)   AS TotalSuccess,
            ISNULL(SUM(UnSuccess), 0) AS TotalUnSuccess
        FROM #WeekSummary;

        DROP TABLE IF EXISTS #WeekSummary;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        DROP TABLE IF EXISTS #MonthSummary;

        SELECT
            DATENAME(MONTH, ScanDate) + ' ' + CAST(YEAR(ScanDate) AS VARCHAR(4)) AS Label,
            YEAR(ScanDate)  AS Yr,
            MONTH(ScanDate) AS Mn,
            SUM(CASE WHEN CodeExists = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS Success,
            SUM(CASE WHEN CodeExists = 0 OR Is_Success <> 1 THEN 1 ELSE 0 END) AS UnSuccess
        INTO #MonthSummary
        FROM #ValidScans
        GROUP BY YEAR(ScanDate), MONTH(ScanDate), DATENAME(MONTH, ScanDate);

        SELECT Label, Success, UnSuccess
        FROM #MonthSummary
        ORDER BY Yr, Mn;

        -- Result Set 2: Total Summary
        SELECT
            ISNULL(SUM(Success), 0)   AS TotalSuccess,
            ISNULL(SUM(UnSuccess), 0) AS TotalUnSuccess
        FROM #MonthSummary;

        DROP TABLE IF EXISTS #MonthSummary;
    END
    ELSE
    BEGIN
        DROP TABLE IF EXISTS #WeekdaySummary;

        SET DATEFIRST 1;

        SELECT 
            DATEPART(WEEKDAY, ScanDate) AS WeekDayNumber,
            DATENAME(WEEKDAY, ScanDate) AS Label,
            SUM(CASE WHEN CodeExists = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS Success,
            SUM(CASE WHEN CodeExists = 0 OR Is_Success <> 1 THEN 1 ELSE 0 END) AS UnSuccess
        INTO #WeekdaySummary
        FROM #ValidScans
        GROUP BY DATEPART(WEEKDAY, ScanDate), DATENAME(WEEKDAY, ScanDate);

        ;WITH WeekDays (DayNo, Label) AS
        (
            SELECT 1, 'Mon' UNION ALL
            SELECT 2, 'Tue' UNION ALL
            SELECT 3, 'Wed' UNION ALL
            SELECT 4, 'Thu' UNION ALL
            SELECT 5, 'Fri' UNION ALL
            SELECT 6, 'Sat' UNION ALL
            SELECT 7, 'Sun'
        )
        SELECT
            w.Label,
            ISNULL(s.Success, 0) AS Success,
            ISNULL(s.UnSuccess, 0) AS UnSuccess
        FROM WeekDays w
        LEFT JOIN #WeekdaySummary s
            ON s.WeekDayNumber = w.DayNo
        WHERE
            (@Win = 'WEEK' AND w.DayNo <= DATEPART(WEEKDAY, @Today))
            OR @Win <> 'WEEK'
        ORDER BY w.DayNo;

        -- Result Set 2: Total Summary
        SELECT
            ISNULL(SUM(Success), 0)   AS TotalSuccess,
            ISNULL(SUM(UnSuccess), 0) AS TotalUnSuccess
        FROM #WeekdaySummary;

        DROP TABLE IF EXISTS #WeekdaySummary;
    END

    ------------------------------------------------------
    -- Cleanup
    ------------------------------------------------------
    DROP TABLE IF EXISTS #ValidScans;
END
GO
