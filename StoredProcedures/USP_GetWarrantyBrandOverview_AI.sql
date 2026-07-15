USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 15-Jul-2026
-- Description: Get Warranty Brand Overview metrics for Company Dashboard
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWarrantyBrandOverview_AI]
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
    -- Overview Calculations
    ------------------------------------------------------
    SELECT 
        COUNT(CASE WHEN (@StartDate IS NULL OR war.PurchaseDate >= @StartDate) AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate) THEN 1 END) AS TotalRegistrations,
        
        COUNT(CASE WHEN war.IsWarrantyClaimed IS NOT NULL AND war.IsWarrantyClaimed IN (0, 1, 2) AND (@StartDate IS NULL OR war.claimdate >= @StartDate) AND (@EndDate IS NULL OR war.claimdate <= @EndDate) THEN 1 END) AS TotalClaims,
        
        COUNT(CASE WHEN war.IsWarrantyClaimed = 1 AND (@StartDate IS NULL OR war.claimdate >= @StartDate) AND (@EndDate IS NULL OR war.claimdate <= @EndDate) THEN 1 END) AS ApprovedClaims,
        
        COUNT(CASE WHEN war.IsWarrantyClaimed = 2 AND (@StartDate IS NULL OR war.claimdate >= @StartDate) AND (@EndDate IS NULL OR war.claimdate <= @EndDate) THEN 1 END) AS RejectedClaims,
        
        COUNT(CASE WHEN war.IsWarrantyClaimed = 0 AND (@StartDate IS NULL OR war.claimdate >= @StartDate) AND (@EndDate IS NULL OR war.claimdate <= @EndDate) THEN 1 END) AS PendingClaims,
        
        COUNT(CASE WHEN (@StartDate IS NULL OR war.PurchaseDate >= @StartDate) AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate) AND war.ExpirationDate >= GETDATE() THEN 1 END) AS ActiveWarrantyCount
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
    INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]
    WHERE pr.[Comp_ID] = @Comp_Id;
END
GO
