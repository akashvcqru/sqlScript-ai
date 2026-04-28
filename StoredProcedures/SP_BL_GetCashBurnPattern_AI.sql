USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetCashBurnPattern_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCashBurnPattern_AI]
(
    @CompId NVARCHAR(50),
    @datePreset NVARCHAR(20)= NULL
)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE 
    @StartDate DATE,
    @EndDate DATE,
    @PrevStartDate DATE;

-- Default end date
SET @EndDate = CAST(GETDATE() AS DATE);
SET DATEFIRST 1;
DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

-- Normalize the filter string
SET @Win = REPLACE(@Win, ' ', '');
IF @Win = 'THISMONTH' SET @Win = 'MONTH';
IF @Win = 'THISWEEK' SET @Win = 'WEEK';
IF @Win = 'QUARTER(90DAYS)' SET @Win = 'QUARTER';

-- Fetch Company Registration Date for optimization
DECLARE @CompRegDate DATE;
SELECT TOP 1 @CompRegDate = CAST(Reg_Date AS DATE) 
FROM Comp_Reg WITH (NOLOCK) 
WHERE Comp_ID = @CompId AND Status = 1;

IF @CompRegDate IS NULL 
    SET @CompRegDate = '2000-01-01';

IF @Win = 'WEEK' OR @Win = 'THISWEEK'
BEGIN
    SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0); -- Monday
    SET @EndDate = CAST(GETDATE() AS DATE);
END
ELSE IF @Win = 'LASTWEEK'
BEGIN
    SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0); -- Prev Monday
    SET @EndDate = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)); -- Prev Sunday
END
ELSE IF @Win = 'MONTH' OR @Win = 'THISMONTH'
BEGIN
    SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    SET @EndDate = CAST(GETDATE() AS DATE);
END
ELSE IF @Win = 'LASTMONTH'
BEGIN
    SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
    SET @EndDate = EOMONTH(DATEADD(MONTH, -1, GETDATE()));
END
ELSE IF @Win = 'QUARTER'
BEGIN
    SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
    SET @EndDate = DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0));
END
ELSE
BEGIN
    -- Default to THIS WEEK
    SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    SET @EndDate = CAST(GETDATE() AS DATE);
END

SET @PrevStartDate = DATEADD(DAY, -DATEDIFF(DAY, @StartDate, DATEADD(DAY, 1, @EndDate)), @StartDate);

    ---------------------------------------------------------------
    -- ACTUAL CASH BURN DATA
    ---------------------------------------------------------------
    IF OBJECT_ID('tempdb..#CashBurn') IS NOT NULL DROP TABLE #CashBurn;

	 SELECT SUM(ut.Amount) AS CashBurn, CAST(ut.ReqDate AS DATE) AS BurnDate
     INTO #CashBurn
     FROM tblUPITransactionDetails ut WITH (NOLOCK) 
     WHERE ut.Status = 'Success' AND Comp_Id=@CompId
       AND ut.ReqDate >= @CompRegDate
	   AND CAST(ut.ReqDate AS DATE) BETWEEN @StartDate AND @EndDate
     GROUP BY CAST(ut.ReqDate AS DATE);
		
    ---------------------------------------------------------------
    -- Generate Date Series
    ---------------------------------------------------------------
    IF OBJECT_ID('tempdb..#DateSeries') IS NOT NULL DROP TABLE #DateSeries;

    ;WITH DateSeries AS (
        SELECT @StartDate AS Dt
        UNION ALL
        SELECT DATEADD(DAY, 1, Dt)
        FROM DateSeries
        WHERE Dt < @EndDate
    )
    SELECT Dt INTO #DateSeries
    FROM DateSeries OPTION (MAXRECURSION 5000);

    ---------------------------------------------------------------
    -- FINAL MERGED DAILY DATA
    ---------------------------------------------------------------
    SELECT 
        Ds.Dt,
        ISNULL(CB.CashBurn, 0) AS CashBurn
    INTO #FinalDaily
    FROM #DateSeries Ds
    LEFT JOIN #CashBurn CB ON CB.BurnDate = Ds.Dt;

    ---------------------------------------------------------------
    -- LABEL HANDLING AND OUTPUT 1 (CHART DATA)
    ---------------------------------------------------------------
    IF @Win IN ('WEEK','LASTWEEK')
    BEGIN
        SELECT  
            DATENAME(WEEKDAY, Dt) AS Label,
            CashBurn,
            0 AS ChangePercent
        FROM #FinalDaily
        ORDER BY Dt;
    END
    ELSE IF @Win IN ('TODAY','YESTERDAY','MONTH','LASTMONTH','YEAR','LASTYEAR')
    BEGIN
        SELECT  
            CONVERT(VARCHAR(10), Dt, 120) AS Label,
            CashBurn,
            0 AS ChangePercent
        FROM #FinalDaily
        ORDER BY Dt;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        ;WITH Monthly AS 
        (
            SELECT  
                DATEFROMPARTS(YEAR(Dt), MONTH(Dt), 1) AS MonthDate,
                SUM(CashBurn) AS CashBurn
            FROM #FinalDaily
            GROUP BY YEAR(Dt), MONTH(Dt)
        ),
        Ordered AS
        (
            SELECT 
                MonthDate,
                CashBurn,
                LAG(CashBurn, 1, 0) OVER (ORDER BY MonthDate) AS PrevBurn
            FROM Monthly
        )
        SELECT  
            CONCAT(DATENAME(MONTH, MonthDate), ' ', YEAR(MonthDate)) AS Label,
            CashBurn,
            CASE WHEN PrevBurn = 0 THEN 0
                 ELSE ((CashBurn - PrevBurn) * 100.0) / PrevBurn END AS ChangePercent
        FROM Ordered
        ORDER BY MonthDate;
    END
    ELSE
    BEGIN
        SELECT  
            CONCAT(DATENAME(MONTH, Dt), ' ', YEAR(Dt)) AS Label,
            SUM(CashBurn) AS CashBurn,
            0 AS ChangePercent
        FROM #FinalDaily
        GROUP BY YEAR(Dt), MONTH(Dt), DATENAME(MONTH, Dt)
        ORDER BY MIN(Dt);
    END

    ---------------------------------------------------------------
    -- SUMMARY TOTALS
    ---------------------------------------------------------------
    DECLARE @TotalBurn DECIMAL(18,2), 
            @AvgBurn DECIMAL(18,2), 
            @PeakBurn DECIMAL(18,2);

    SELECT 
        @TotalBurn = SUM(CashBurn),
        @AvgBurn = AVG(CashBurn),
        @PeakBurn = MAX(CashBurn)
    FROM #FinalDaily;

    ---------------------------------------------------------------
    -- PREVIOUS WINDOW SUMMARY
    ---------------------------------------------------------------
	 SELECT SUM(ut.Amount) AS CashBurn, CAST(ut.ReqDate AS DATE) AS BurnDate
     INTO #CashBurnPrev
     FROM tblUPITransactionDetails ut WITH (NOLOCK) 
     WHERE ut.Status = 'Success' AND Comp_Id=@CompId
       AND ut.ReqDate >= @CompRegDate
	   AND CAST(ut.ReqDate AS DATE) BETWEEN @PrevStartDate AND DATEADD(DAY, -1, @StartDate)
     GROUP BY CAST(ut.ReqDate AS DATE);

    DECLARE @PrevTotalBurn DECIMAL(18,2), 
            @PrevAvgBurn DECIMAL(18,2), 
            @PrevPeakBurn DECIMAL(18,2);

    SELECT 
        @PrevTotalBurn = SUM(CashBurn),
        @PrevAvgBurn = AVG(CashBurn),
        @PrevPeakBurn = MAX(CashBurn)
    FROM #CashBurnPrev;

    ---------------------------------------------------------------
    -- RETURN SUMMARY
    ---------------------------------------------------------------
    SELECT 
        ISNULL(@TotalBurn, 0) AS TotalBurn,
        CASE WHEN ISNULL(@PrevTotalBurn, 0) = 0 THEN 0
             ELSE ((ISNULL(@TotalBurn, 0) - @PrevTotalBurn) * 100.0) / @PrevTotalBurn END AS TotalBurnChangePercent,
        ISNULL(@AvgBurn, 0) AS AvgBurn,
        CASE WHEN ISNULL(@PrevAvgBurn, 0) = 0 THEN 0
             ELSE ((ISNULL(@AvgBurn, 0) - @PrevAvgBurn) * 100.0) / @PrevAvgBurn END AS AvgBurnChangePercent,
        ISNULL(@PeakBurn, 0) AS PeakBurn,
        CASE WHEN ISNULL(@PrevPeakBurn, 0) = 0 THEN 0
             ELSE ((ISNULL(@PeakBurn, 0) - @PrevPeakBurn) * 100.0) / @PrevPeakBurn END AS PeakBurnChangePercent;
END
