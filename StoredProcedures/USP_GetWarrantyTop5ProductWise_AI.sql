USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 15-Jul-2026
-- Description: Get Top 5 Product-wise warranty registrations distribution share
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWarrantyTop5ProductWise_AI]
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
    -- Temporary Merged Table of Registrations in period
    ------------------------------------------------------
    DROP TABLE IF EXISTS #ProductRegistrations;
    
    SELECT 
        pr.Pro_Name AS ProductName,
        COUNT(1) AS Registrations
    INTO #ProductRegistrations
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
    INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]
    WHERE pr.[Comp_ID] = @Comp_Id
      AND (@StartDate IS NULL OR war.PurchaseDate >= @StartDate)
      AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate)
    GROUP BY pr.Pro_Name;

    DECLARE @TotalRegistrations INT = 0;
    SELECT @TotalRegistrations = SUM(Registrations) FROM #ProductRegistrations;
    IF @TotalRegistrations IS NULL SET @TotalRegistrations = 0;

    DECLARE @TotalProducts INT = 0;
    SELECT @TotalProducts = COUNT(1) FROM #ProductRegistrations;

    ------------------------------------------------------
    -- Top Product Info
    ------------------------------------------------------
    DECLARE @TopProductName NVARCHAR(200) = NULL;
    DECLARE @TopProductRegistrations INT = 0;
    
    SELECT TOP 1 
        @TopProductName = ProductName, 
        @TopProductRegistrations = Registrations 
    FROM #ProductRegistrations 
    ORDER BY Registrations DESC, ProductName ASC;

    ------------------------------------------------------
    -- ResultSet 1: Products
    ------------------------------------------------------
    SELECT TOP 5
        ProductName,
        Registrations,
        CASE WHEN @TotalRegistrations > 0 
             THEN CAST((Registrations * 100.0) / @TotalRegistrations AS DECIMAL(18, 2))
             ELSE 0.00 
        END AS Percentage
    FROM #ProductRegistrations
    ORDER BY Registrations DESC, ProductName ASC;

    ------------------------------------------------------
    -- ResultSet 2: Summary
    ------------------------------------------------------
    SELECT 
        @TotalRegistrations AS TotalRegistrations,
        @TotalProducts AS TotalProducts,
        @TopProductName AS TopProductName,
        @TopProductRegistrations AS TopProductRegistrations;

    DROP TABLE IF EXISTS #ProductRegistrations;
END
GO
