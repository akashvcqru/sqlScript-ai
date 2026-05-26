USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [dbo].[USP_GetDailyActivities_AI] 'Comp-1599','quarter'
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDailyActivities_AI]       
    @Comp_Id varchar(20),
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
    -- Prepare valid scans
    ------------------------------------------------------
    DROP TABLE IF EXISTS #ValidScans;
    CREATE TABLE #ValidScans (
        ScanDate DATE,
        MobileNo VARCHAR(50),
        FullCode NVARCHAR(100)
    );

    IF @Comp_Id = 'Comp-1693'
    BEGIN
        INSERT INTO #ValidScans (ScanDate, MobileNo, FullCode)
        SELECT
            CAST(pe.Enq_Date AS DATE) AS ScanDate,
            pe.MobileNo,
            (CAST(mc.Code1 AS NVARCHAR(20)) + CAST(mc.Code2 AS NVARCHAR(20))) AS FullCode
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_Code_PFL mc WITH (NOLOCK)
            ON (CAST(mc.Code1 AS NVARCHAR(20)) + CAST(mc.Code2 AS NVARCHAR(20)))
             = (pe.Received_Code1 + pe.Received_Code2)
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = mc.Pro_ID
           AND pr.Comp_ID = @Comp_Id
        WHERE pe.Is_Success = 1
          AND mc.Use_Count = 1
          AND pe.Enq_Date >= @StartDate
          AND pe.Enq_Date <  @EndDate
          AND mc.Gen_Date >= @CompanyStartDate;
    END
    ELSE
    BEGIN
        INSERT INTO #ValidScans (ScanDate, MobileNo, FullCode)
        SELECT
            CAST(pe.Enq_Date AS DATE) AS ScanDate,
            pe.MobileNo,
            (CAST(mc.Code1 AS NVARCHAR(20)) + CAST(mc.Code2 AS NVARCHAR(20))) AS FullCode
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_Code mc WITH (NOLOCK)
            ON (CAST(mc.Code1 AS NVARCHAR(20)) + CAST(mc.Code2 AS NVARCHAR(20)))
             = (pe.Received_Code1 + pe.Received_Code2)
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = mc.Pro_ID
           AND pr.Comp_ID = @Comp_Id
        WHERE pe.Is_Success = 1
          AND mc.Use_Count = 1
          AND pe.Enq_Date >= @StartDate
          AND pe.Enq_Date <  @EndDate
          AND mc.Gen_Date >= @CompanyStartDate;
    END

    ------------------------------------------------------
    -- First scan per user
    ------------------------------------------------------
    DROP TABLE IF EXISTS #FirstScanUser;

    SELECT MobileNo, MIN(ScanDate) AS FirstScanDate
    INTO #FirstScanUser
    FROM #ValidScans
    GROUP BY MobileNo;

    ------------------------------------------------------
    -- MONTH / LASTMONTH → Week-wise
    ------------------------------------------------------
    IF @Win IN ('MONTH', 'LASTMONTH', '')
    BEGIN
        DROP TABLE IF EXISTS #WeekSummary;

        SELECT
            DATEDIFF(WEEK,
                DATEADD(MONTH, DATEDIFF(MONTH, 0, v.ScanDate), 0),
                v.ScanDate
            ) + 1 AS WeekNumber,

            COUNT(DISTINCT v.FullCode) AS UniqueCodesScanned,

            COUNT(DISTINCT CASE
                WHEN f.FirstScanDate = v.ScanDate THEN v.MobileNo
            END) AS NewUsers
        INTO #WeekSummary
        FROM #ValidScans v
        LEFT JOIN #FirstScanUser f ON v.MobileNo = f.MobileNo
        GROUP BY
            DATEDIFF(WEEK,
                DATEADD(MONTH, DATEDIFF(MONTH, 0, v.ScanDate), 0),
                v.ScanDate
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
            ISNULL(s.UniqueCodesScanned, 0) AS UniqueCodesScanned,
            ISNULL(s.NewUsers, 0) AS NewUsers
        FROM WeekNums w
        LEFT JOIN #WeekSummary s ON s.WeekNumber = w.WeekNo
        ORDER BY w.WeekNo
        OPTION (MAXRECURSION 10);

        SELECT
            SUM(UniqueCodesScanned) AS TotalCodesChecked,
            SUM(NewUsers) AS TotalNewUsers
        FROM #WeekSummary;

        DROP TABLE IF EXISTS #WeekSummary;
    END

    ------------------------------------------------------
    -- QUARTER → Month-wise
    ------------------------------------------------------
    ELSE IF @Win = 'QUARTER'
    BEGIN
        DROP TABLE IF EXISTS #MonthSummary;

        SELECT
            DATENAME(MONTH, v.ScanDate) + ' ' + CAST(YEAR(v.ScanDate) AS VARCHAR(4)) AS Label,
            YEAR(v.ScanDate) AS Yr,
            MONTH(v.ScanDate) AS Mn,

            COUNT(DISTINCT v.FullCode) AS UniqueCodesScanned,

            COUNT(DISTINCT CASE
                WHEN f.FirstScanDate = v.ScanDate THEN v.MobileNo
            END) AS NewUsers
        INTO #MonthSummary
        FROM #ValidScans v
        LEFT JOIN #FirstScanUser f ON v.MobileNo = f.MobileNo
        GROUP BY YEAR(v.ScanDate), MONTH(v.ScanDate), DATENAME(MONTH, v.ScanDate);

        SELECT Label, UniqueCodesScanned, NewUsers
        FROM #MonthSummary
        ORDER BY Yr, Mn;

        SELECT
            SUM(UniqueCodesScanned) AS TotalCodesChecked,
            SUM(NewUsers) AS TotalNewUsers
        FROM #MonthSummary;

        DROP TABLE IF EXISTS #MonthSummary;
    END

    ------------------------------------------------------
    -- WEEK / LASTWEEK / TODAY → Weekday-wise (Mon–Sun)
    ------------------------------------------------------
    ELSE
    BEGIN
        DROP TABLE IF EXISTS #WeekdaySummary;

        SET DATEFIRST 1;

        SELECT
            DATEPART(WEEKDAY, v.ScanDate) AS WeekDayNumber,
            DATENAME(WEEKDAY, v.ScanDate) AS Label,

            COUNT(DISTINCT v.FullCode) AS UniqueCodesScanned,

            COUNT(DISTINCT CASE
                WHEN f.FirstScanDate = v.ScanDate THEN v.MobileNo
            END) AS NewUsers
        INTO #WeekdaySummary
        FROM #ValidScans v
        LEFT JOIN #FirstScanUser f ON v.MobileNo = f.MobileNo
        GROUP BY DATEPART(WEEKDAY, v.ScanDate), DATENAME(WEEKDAY, v.ScanDate);

        ;WITH WeekDays AS
        (
            SELECT 1 AS DayNo, 'Mon' AS Label UNION ALL
            SELECT 2, 'Tue' UNION ALL
            SELECT 3, 'Wed' UNION ALL
            SELECT 4, 'Thu' UNION ALL
            SELECT 5, 'Fri' UNION ALL
            SELECT 6, 'Sat' UNION ALL
            SELECT 7, 'Sun'
        )
        SELECT
            w.Label,
            ISNULL(s.UniqueCodesScanned, 0) AS UniqueCodesScanned,
            ISNULL(s.NewUsers, 0) AS NewUsers
        FROM WeekDays w
        LEFT JOIN #WeekdaySummary s
            ON s.WeekDayNumber = w.DayNo
        WHERE
            (@Win = 'WEEK' AND w.DayNo <= DATEPART(WEEKDAY, @Today))
            OR @Win <> 'WEEK'
        ORDER BY w.DayNo;

        SELECT
            SUM(ISNULL(UniqueCodesScanned, 0)) AS TotalCodesChecked,
            SUM(ISNULL(NewUsers, 0)) AS TotalNewUsers
        FROM #WeekdaySummary;

        DROP TABLE IF EXISTS #WeekdaySummary;
    END

    ------------------------------------------------------
    -- Cleanup
    ------------------------------------------------------
    DROP TABLE IF EXISTS #FirstScanUser;
    DROP TABLE IF EXISTS #ValidScans;
END
GO
