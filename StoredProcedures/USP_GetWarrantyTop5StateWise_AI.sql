USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 15-Jul-2026
-- Description: Get Top 5 State-wise warranty registrations and claims distribution share
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWarrantyTop5StateWise_AI]
(
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    ------------------------------------------------------
    -- Date Range Logic
    ------------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    IF (@datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null')
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
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
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0));
        END
        ELSE IF (@Win = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
            SET @EndDate = DATEFROMPARTS(YEAR(@Today) - 1, 12, 31);
        END
    END

    ------------------------------------------------------
    -- Temporary Merged Table of State-wise Metrics in period
    ------------------------------------------------------
    DROP TABLE IF EXISTS #StateMetrics;
    
    SELECT 
        ISNULL(NULLIF(LTRIM(RTRIM(war.[State])), ''), 'Unknown') AS StateName,
        
        COUNT(CASE WHEN (@StartDate IS NULL OR war.PurchaseDate >= @StartDate) AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate) THEN 1 END) AS Registrations,
        
        COUNT(CASE WHEN war.IsWarrantyClaimed = 1 AND (@StartDate IS NULL OR war.claimdate >= @StartDate) AND (@EndDate IS NULL OR war.claimdate <= @EndDate) THEN 1 END) AS Claims
        
    INTO #StateMetrics
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
    INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]
    WHERE pr.[Comp_ID] = @Comp_Id
      -- We must include records where either PurchaseDate (for Registrations) or claimdate (for Claims) is within the period
      AND (
          ((@StartDate IS NULL OR war.PurchaseDate >= @StartDate) AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate))
          OR
          (war.IsWarrantyClaimed = 1 AND (@StartDate IS NULL OR war.claimdate >= @StartDate) AND (@EndDate IS NULL OR war.claimdate <= @EndDate))
      )
    GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(war.[State])), ''), 'Unknown');

    -- Calculate grand totals
    DECLARE @TotalRegistrations INT = 0;
    SELECT @TotalRegistrations = SUM(Registrations) FROM #StateMetrics;
    IF @TotalRegistrations IS NULL SET @TotalRegistrations = 0;

    DECLARE @TotalClaims INT = 0;
    SELECT @TotalClaims = SUM(Claims) FROM #StateMetrics;
    IF @TotalClaims IS NULL SET @TotalClaims = 0;

    ------------------------------------------------------
    -- Select Top 5 States and Group others
    ------------------------------------------------------
    DROP TABLE IF EXISTS #TopStates;
    SELECT TOP 5 StateName
    INTO #TopStates
    FROM #StateMetrics
    ORDER BY Registrations DESC, Claims DESC, StateName ASC;

    -- ResultSet 1: Top 5 States + Other States (if any)
    ;WITH CombinedStates AS (
        SELECT 
            CASE WHEN ts.StateName IS NOT NULL THEN sm.StateName ELSE 'Other States' END AS StateName,
            sm.Registrations,
            sm.Claims
        FROM #StateMetrics sm
        LEFT JOIN #TopStates ts ON ts.StateName = sm.StateName
    )
    SELECT 
        StateName,
        SUM(Registrations) AS Registrations,
        SUM(Claims) AS Claims
    FROM CombinedStates
    GROUP BY StateName
    ORDER BY 
        CASE WHEN StateName = 'Other States' THEN 1 ELSE 0 END, -- Put 'Other States' at the bottom
        Registrations DESC, 
        Claims DESC, 
        StateName ASC;

    -- ResultSet 2: Summary
    SELECT 
        @TotalRegistrations AS TotalRegistrations,
        @TotalClaims AS TotalClaims;

    DROP TABLE IF EXISTS #TopStates;
    DROP TABLE IF EXISTS #StateMetrics;
END
GO
