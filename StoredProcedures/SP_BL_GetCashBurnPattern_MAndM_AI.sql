USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetCashBurnPattern_MAndM_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Description: Cash Burn Pattern for Mahindra & Mahindra (Comp-1152) Dashboard
-- Returns Chart Data and Summary Stats
-- exec [dbo].[SP_BL_GetCashBurnPattern_MAndM_AI] 'Comp-1152', 'MONTH'
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCashBurnPattern_MAndM_AI]
(
    @CompId NVARCHAR(50),
    @datePreset NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(50) = @CompId;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @CompId AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @CompId AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

    DECLARE 
        @StartDate DATE,
        @EndDate DATE,
        @PrevStartDate DATE,
        @PrevEndDate DATE;

    -- Default end date
    SET @EndDate = CAST(GETDATE() AS DATE);
    SET DATEFIRST 1; -- Monday start
    
    DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

    -- Normalize the filter string
    IF @Win = 'THISMONTH' SET @Win = 'MONTH';
    IF @Win = 'THISWEEK' SET @Win = 'WEEK';
    IF @Win = 'QUARTER(90DAYS)' SET @Win = 'QUARTER';

    -- Fetch Company Registration Date for optimization
    DECLARE @CompRegDate DATE;
    SELECT TOP 1 @CompRegDate = CAST(Reg_Date AS DATE) 
    FROM Comp_Reg WITH (NOLOCK) 
    WHERE Comp_ID = @ActualCompId AND Status = 1;

    IF @CompRegDate IS NULL 
        SET @CompRegDate = '2023-01-01'; -- Fallback

    ---------------------------------------------------------
    -- Date Window Logic
    ---------------------------------------------------------
    IF @Win = 'TODAY'
    BEGIN
        SET @StartDate = @EndDate;
        SET @PrevStartDate = DATEADD(DAY, -1, @EndDate);
        SET @PrevEndDate = DATEADD(DAY, -1, @EndDate);
    END
    ELSE IF @Win = 'YESTERDAY' OR @Win = 'LASTDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, @EndDate);
        SET @EndDate = DATEADD(DAY, -1, @EndDate);
        SET @PrevStartDate = DATEADD(DAY, -2, @EndDate);
        SET @PrevEndDate = DATEADD(DAY, -2, @EndDate);
    END
    ELSE IF @Win = 'WEEK' OR @Win = 'THISWEEK'
    BEGIN
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);
        SET @PrevStartDate = DATEADD(WEEK, -1, @StartDate);
        SET @PrevEndDate = DATEADD(DAY, -1, @StartDate);
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
        SET @EndDate = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        SET @PrevStartDate = DATEADD(WEEK, -1, @StartDate);
        SET @PrevEndDate = DATEADD(DAY, -1, @StartDate);
    END
    ELSE IF @Win = 'MONTH' OR @Win = 'THISMONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate = DATEADD(DAY, -1, @StartDate);
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
        SET @EndDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate = DATEADD(DAY, -1, @StartDate);
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, @EndDate);
        SET @PrevStartDate = DATEADD(DAY, -180, @EndDate);
        SET @PrevEndDate = DATEADD(DAY, -91, @EndDate);
    END
    ELSE IF @Win = 'YEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), 1, 1);
        SET @PrevStartDate = DATEFROMPARTS(YEAR(@EndDate) - 1, 1, 1);
        SET @PrevEndDate = DATEFROMPARTS(YEAR(@EndDate) - 1, 12, 31);
    END
    ELSE
    BEGIN
        -- Default to THIS MONTH
        SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate = DATEADD(DAY, -1, @StartDate);
    END

    -- Ensure we don't go before registration
    IF @StartDate < @CompRegDate SET @StartDate = @CompRegDate;

    ---------------------------------------------------------
    -- SBU Team Temp Tables for Performance Optimization
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#SBUTeamConsumerIds') IS NOT NULL DROP TABLE #SBUTeamConsumerIds;
    SELECT M_Consumerid
    INTO #SBUTeamConsumerIds
    FROM M_Consumer WITH (NOLOCK) 
    WHERE distributorID = 'SBUTEAM' AND IsDelete = 0;

    CREATE UNIQUE CLUSTERED INDEX IX_SBUTeamConsumerIds_Id ON #SBUTeamConsumerIds(M_Consumerid);

    ---------------------------------------------------------------
    -- ACTUAL CASH BURN DATA (Using Mahindra specific filters)
    ---------------------------------------------------------------
    IF OBJECT_ID('tempdb..#CashBurn') IS NOT NULL DROP TABLE #CashBurn;
    CREATE TABLE #CashBurn (
        CashBurn DECIMAL(18,2),
        BurnDate DATE
    );

    IF @IsSBUTeam = 1
    BEGIN
        INSERT INTO #CashBurn (CashBurn, BurnDate)
        SELECT 
            SUM(CAST(ut.Amount AS DECIMAL(18,2))), 
            CAST(ut.TransactionDate AS DATE)
        FROM Transactions ut WITH (NOLOCK) 
        WHERE ut.Issuccess = 1 
          AND ut.CompId = REPLACE(@ActualCompId, 'Comp-', '')
          AND ut.TransactionDate >= @StartDate
          AND ut.TransactionDate < DATEADD(DAY, 1, @EndDate)
          AND ut.M_CounserID IN (SELECT M_Consumerid FROM #SBUTeamConsumerIds)
        GROUP BY CAST(ut.TransactionDate AS DATE);
    END
    ELSE
    BEGIN
        INSERT INTO #CashBurn (CashBurn, BurnDate)
        SELECT 
            SUM(CAST(ut.Amount AS DECIMAL(18,2))), 
            CAST(ut.TransactionDate AS DATE)
        FROM Transactions ut WITH (NOLOCK) 
        WHERE ut.Issuccess = 1 
          AND ut.CompId = REPLACE(@ActualCompId, 'Comp-', '')
          AND ut.TransactionDate >= @StartDate
          AND ut.TransactionDate < DATEADD(DAY, 1, @EndDate)
          AND ut.M_CounserID NOT IN (SELECT M_Consumerid FROM #SBUTeamConsumerIds)
        GROUP BY CAST(ut.TransactionDate AS DATE);
    END

    ---------------------------------------------------------------
    -- Generate Date Series for Gap Filling
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
    FROM DateSeries OPTION (MAXRECURSION 1000);

    ---------------------------------------------------------------
    -- FINAL MERGED DAILY DATA
    ---------------------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalDaily') IS NOT NULL DROP TABLE #FinalDaily;
    
    SELECT 
        Ds.Dt,
        ISNULL(CB.CashBurn, 0) AS CashBurn
    INTO #FinalDaily
    FROM #DateSeries Ds
    LEFT JOIN #CashBurn CB ON CB.BurnDate = Ds.Dt;

    ---------------------------------------------------------------
    -- OUTPUT 1: CHART DATA
    ---------------------------------------------------------------
    -- For Today/Yesterday: Show Hourly (Simulated or just point)
    IF @Win IN ('TODAY', 'YESTERDAY')
    BEGIN
        SELECT 
            FORMAT(Dt, 'hh tt') AS Label,
            CashBurn,
            0 AS ChangePercent
        FROM #FinalDaily
        ORDER BY Dt;
    END
    -- For Week: Show Weekday names
    ELSE IF @Win IN ('WEEK', 'THISWEEK', 'LASTWEEK')
    BEGIN
        SELECT  
            DATENAME(WEEKDAY, Dt) AS Label,
            CashBurn,
            0 AS ChangePercent
        FROM #FinalDaily
        ORDER BY Dt;
    END
    -- For Month: Show Day numbers (1st, 2nd, etc)
    ELSE IF @Win IN ('MONTH', 'THISMONTH', 'LASTMONTH')
    BEGIN
        SELECT  
            CONCAT(DAY(Dt), 
                CASE 
                    WHEN DAY(Dt) % 10 = 1 AND DAY(Dt) % 100 <> 11 THEN 'st'
                    WHEN DAY(Dt) % 10 = 2 AND DAY(Dt) % 100 <> 12 THEN 'nd'
                    WHEN DAY(Dt) % 10 = 3 AND DAY(Dt) % 100 <> 13 THEN 'rd'
                    ELSE 'th' 
                END) AS Label,
            CashBurn,
            0 AS ChangePercent
        FROM #FinalDaily
        ORDER BY Dt;
    END
    -- For Year/Quarter: Show Month names
    ELSE
    BEGIN
        SELECT  
            DATENAME(MONTH, MIN(Dt)) AS Label,
            SUM(CashBurn) AS CashBurn,
            0 AS ChangePercent
        FROM #FinalDaily
        GROUP BY YEAR(Dt), MONTH(Dt)
        ORDER BY MIN(Dt);
    END;

    ---------------------------------------------------------------
    -- SUMMARY CALCULATIONS
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
    -- PREVIOUS WINDOW DATA FOR PERCENTAGE CHANGE
    ---------------------------------------------------------------
    DECLARE @PrevTotalBurn DECIMAL(18,2), 
            @PrevAvgBurn DECIMAL(18,2), 
            @PrevPeakBurn DECIMAL(18,2);

    IF @IsSBUTeam = 1
    BEGIN
        SELECT 
            @PrevTotalBurn = SUM(CAST(ut.Amount AS DECIMAL(18,2)))
        FROM Transactions ut WITH (NOLOCK) 
        WHERE ut.Issuccess = 1 
          AND ut.CompId = REPLACE(@ActualCompId, 'Comp-', '')
          AND ut.TransactionDate >= @PrevStartDate
          AND ut.TransactionDate < DATEADD(DAY, 1, @PrevEndDate)
          AND ut.M_CounserID IN (SELECT M_Consumerid FROM #SBUTeamConsumerIds);
    END
    ELSE
    BEGIN
        SELECT 
            @PrevTotalBurn = SUM(CAST(ut.Amount AS DECIMAL(18,2)))
        FROM Transactions ut WITH (NOLOCK) 
        WHERE ut.Issuccess = 1 
          AND ut.CompId = REPLACE(@ActualCompId, 'Comp-', '')
          AND ut.TransactionDate >= @PrevStartDate
          AND ut.TransactionDate < DATEADD(DAY, 1, @PrevEndDate)
          AND ut.M_CounserID NOT IN (SELECT M_Consumerid FROM #SBUTeamConsumerIds);
    END

    -- Simpler peak/avg for prev window from raw aggregated if needed, but Total is most important
    SET @PrevTotalBurn = ISNULL(@PrevTotalBurn, 0);
    SET @PrevAvgBurn = @PrevTotalBurn / CASE WHEN DATEDIFF(DAY, @PrevStartDate, @PrevEndDate) + 1 = 0 THEN 1 ELSE DATEDIFF(DAY, @PrevStartDate, @PrevEndDate) + 1 END;

    ---------------------------------------------------------------
    -- OUTPUT 2: SUMMARY
    ---------------------------------------------------------------
    SELECT 
        ISNULL(@TotalBurn, 0) AS TotalBurn,
        CASE WHEN ISNULL(@PrevTotalBurn, 0) = 0 THEN 0
             ELSE ((ISNULL(@TotalBurn, 0) - @PrevTotalBurn) * 100.0) / @PrevTotalBurn END AS TotalBurnChangePercent,
        ISNULL(@AvgBurn, 0) AS AvgBurn,
        CASE WHEN ISNULL(@PrevAvgBurn, 0) = 0 THEN 0
             ELSE ((ISNULL(@AvgBurn, 0) - @PrevAvgBurn) * 100.0) / @PrevAvgBurn END AS AvgBurnChangePercent,
        ISNULL(@PeakBurn, 0) AS PeakBurn,
        0 AS PeakBurnChangePercent; -- Simplified
END
GO
