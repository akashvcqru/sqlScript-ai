USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 15-Jul-2026
-- Description: Get Warranty Registration and Claim Activity Graph data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWarrantyRegClaimActivityGraph_AI]
(
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    ------------------------------------------------------
    -- Date Range Logic for Current Period
    ------------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;
    DECLARE @Interval  VARCHAR(10) = 'DAY';

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
    SET DATEFIRST 1;

    IF (@Win = 'TODAY')
    BEGIN
        SET @StartDate = CAST(@Today AS DATETIME);
        SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
    END
    ELSE IF (@Win = 'YESTERDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
        SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
    END
    ELSE IF (@Win = 'WEEK')
    BEGIN
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
        SET @EndDate   = GETDATE();
    END
    ELSE IF (@Win = 'LASTWEEK')
    BEGIN
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
        SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0));
    END
    ELSE IF (@Win = 'MONTH' OR @Win = '')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = GETDATE();
    END
    ELSE IF (@Win = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
        SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
    END
    ELSE IF (@Win = 'QUARTER')
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
        SET @EndDate   = GETDATE();
    END
    ELSE IF (@Win = 'YEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
        SET @EndDate   = GETDATE();
        SET @Interval  = 'MONTH';
    END
    ELSE IF (@Win = 'LASTYEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(@Today) - 1, 12, 31);
        SET @Interval  = 'MONTH';
    END
    ELSE
    BEGIN
        -- Default to MONTH
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = GETDATE();
    END

    ------------------------------------------------------
    -- Date Range Logic for Previous Period
    ------------------------------------------------------
    DECLARE @Duration INT = DATEDIFF(DAY, @StartDate, @EndDate);
    IF @Duration <= 0 SET @Duration = 1;

    DECLARE @PrevStartDate DATETIME = NULL;
    DECLARE @PrevEndDate DATETIME = NULL;

    IF (@Win = 'TODAY' OR @Win = 'YESTERDAY')
    BEGIN
        SET @PrevStartDate = DATEADD(DAY, -1, @StartDate);
        SET @PrevEndDate   = DATEADD(SECOND, -1, @StartDate);
    END
    ELSE IF (@Win = 'WEEK' OR @Win = 'LASTWEEK')
    BEGIN
        SET @PrevStartDate = DATEADD(WEEK, -1, @StartDate);
        SET @PrevEndDate   = DATEADD(WEEK, -1, @EndDate);
    END
    ELSE IF (@Win = 'MONTH' OR @Win = 'LASTMONTH' OR @Win = '')
    BEGIN
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate   = DATEADD(MONTH, -1, @EndDate);
    END
    ELSE IF (@Win = 'QUARTER')
    BEGIN
        SET @PrevStartDate = DATEADD(DAY, -90, @StartDate);
        SET @PrevEndDate   = DATEADD(DAY, -90, @EndDate);
    END
    ELSE IF (@Win = 'YEAR' OR @Win = 'LASTYEAR')
    BEGIN
        SET @PrevStartDate = DATEADD(YEAR, -1, @StartDate);
        SET @PrevEndDate   = DATEADD(YEAR, -1, @EndDate);
    END

    ------------------------------------------------------
    -- Step 1: ResultSet 1 - Graph Data Points
    ------------------------------------------------------
    IF @Interval = 'DAY'
    BEGIN
        ;WITH DateCalendar AS (
            SELECT CAST(@StartDate AS DATE) AS CalendarDate
            UNION ALL
            SELECT DATEADD(DAY, 1, CalendarDate)
            FROM DateCalendar
            WHERE CalendarDate < CAST(@EndDate AS DATE)
        )
        SELECT 
            FORMAT(c.CalendarDate, 'dd MMM') AS Label,
            ISNULL(SUM(CASE WHEN pr.Comp_ID = @Comp_Id THEN 1 END), 0) AS Registrations,
            ISNULL(SUM(CASE WHEN pr.Comp_ID = @Comp_Id AND war.IsWarrantyClaimed = 1 THEN 1 END), 0) AS ClaimsApproved
        FROM DateCalendar c
        LEFT JOIN [dbo].[WarrentyDetails] war WITH (NOLOCK) 
            ON CAST(war.PurchaseDate AS DATE) = c.CalendarDate
        LEFT JOIN [dbo].[M_code] Mc WITH (NOLOCK) 
            ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
        LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) 
            ON pr.[Pro_ID] = Mc.[Pro_ID] AND pr.[Comp_ID] = @Comp_Id
        GROUP BY c.CalendarDate
        ORDER BY c.CalendarDate
        OPTION (MAXRECURSION 366);
    END
    ELSE
    BEGIN
        ;WITH MonthCalendar AS (
            SELECT DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AS CalendarMonth
            UNION ALL
            SELECT DATEADD(MONTH, 1, CalendarMonth)
            FROM MonthCalendar
            WHERE CalendarMonth < DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1)
        )
        SELECT 
            FORMAT(c.CalendarMonth, 'MMM yyyy') AS Label,
            ISNULL(SUM(CASE WHEN pr.Comp_ID = @Comp_Id THEN 1 END), 0) AS Registrations,
            ISNULL(SUM(CASE WHEN pr.Comp_ID = @Comp_Id AND war.IsWarrantyClaimed = 1 THEN 1 END), 0) AS ClaimsApproved
        FROM MonthCalendar c
        LEFT JOIN [dbo].[WarrentyDetails] war WITH (NOLOCK) 
            ON YEAR(war.PurchaseDate) = YEAR(c.CalendarMonth) AND MONTH(war.PurchaseDate) = MONTH(c.CalendarMonth)
        LEFT JOIN [dbo].[M_code] Mc WITH (NOLOCK) 
            ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
        LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) 
            ON pr.[Pro_ID] = Mc.[Pro_ID] AND pr.[Comp_ID] = @Comp_Id
        GROUP BY c.CalendarMonth
        ORDER BY c.CalendarMonth
        OPTION (MAXRECURSION 12);
    END

    ------------------------------------------------------
    -- Step 2: ResultSet 2 - Bottom Summary Metrics
    ------------------------------------------------------
    SELECT
        -- Current Period Counts
        COUNT(CASE WHEN (@StartDate IS NULL OR war.PurchaseDate >= @StartDate) AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate) THEN 1 END) AS TotalRegistrations,
        COUNT(CASE WHEN war.IsWarrantyClaimed = 1 AND (@StartDate IS NULL OR war.claimdate >= @StartDate) AND (@EndDate IS NULL OR war.claimdate <= @EndDate) THEN 1 END) AS TotalClaimsApproved,
        
        -- Previous Period Counts
        COUNT(CASE WHEN (@PrevStartDate IS NULL OR war.PurchaseDate >= @PrevStartDate) AND (@PrevEndDate IS NULL OR war.PurchaseDate <= @PrevEndDate) THEN 1 END) AS PrevTotalRegistrations,
        COUNT(CASE WHEN war.IsWarrantyClaimed = 1 AND (@PrevStartDate IS NULL OR war.claimdate >= @PrevStartDate) AND (@PrevEndDate IS NULL OR war.claimdate <= @PrevEndDate) THEN 1 END) AS PrevTotalClaimsApproved
        
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
    INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]
    WHERE pr.[Comp_ID] = @Comp_Id;
END
GO
