USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 14-Jul-2026
-- Description: Get Warranty Code Check Report for Company Dashboard with Pagination, TimeWindow, and filters
-- Reference:   frmManfEnquiryW.aspx.cs
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_WarrantyCodeCheckReport_AI]
(
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    ------------------------------------------------------
    -- Pagination Defaults
    ------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------
    -- Date Range Logic
    ------------------------------------------------------
    DECLARE @StartDate DATETIME = @FromDate;
    DECLARE @EndDate   DATETIME = @ToDate;

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
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0));
        END
        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END
            
        IF @EndDate IS NULL SET @EndDate = GETDATE();
    END

    ------------------------------------------------------
    -- Search & Filter Params
    ------------------------------------------------------
    DECLARE @SearchParam NVARCHAR(102) = NULL;
    IF @Search IS NOT NULL AND @Search <> ''
        SET @SearchParam = '%' + @Search + '%';

    ------------------------------------------------------
    -- Main Query
    ------------------------------------------------------
    ;WITH MainResult AS (
        SELECT    
            war.[id] AS id,
            war.[PurchaseDate] AS PurchaseDate,
            pr.[Pro_Name] AS Pro_Name,
            pr.[Pro_ID] AS Pro_ID,
            CAST(Mc.[Code1] AS VARCHAR(20)) + CAST(Mc.[Code2] AS VARCHAR(20)) AS Code,
            war.[Serialno] AS SerialNo,
            war.[Email] AS Email,
            war.[Mobile] AS MobileNo,
            war.[WarrantyPeriod] AS WarrantyDurationMonth,
            war.[ExpirationDate] AS Exp_Date,
            war.[BillNo] AS BillNumber,
            war.[ImagePath] AS ProductImage,
            war.[ImagePathBill] AS BillInvoice,
            war.[Comment] AS UserComment,
            war.[Battary_volt] AS Battary_volt,
            war.[Brand] AS Brand,
            war.[Ratting] AS Ratting,
            war.[batryType] AS batryType,
            war.[Model] AS Model
        FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
        INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]    
        INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]    
        WHERE pr.[Comp_ID] = @Comp_Id
          -- Date filtering on PurchaseDate (reference page load/filtering logic uses PurchaseDate)
          AND (@StartDate IS NULL OR war.PurchaseDate >= @StartDate)
          AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate)
          -- General Search filter (includes Code search without hyphen)
          AND (@SearchParam IS NULL OR 
               war.Mobile LIKE @SearchParam OR 
               war.BillNo LIKE @SearchParam OR 
               war.Serialno LIKE @SearchParam OR 
               war.Email LIKE @SearchParam OR
               pr.Pro_Name LIKE @SearchParam OR
               (CAST(Mc.[Code1] AS VARCHAR(20)) + CAST(Mc.[Code2] AS VARCHAR(20))) LIKE @SearchParam OR
               war.[Code] LIKE @SearchParam)
    )
    SELECT * FROM MainResult
    ORDER BY id DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ------------------------------------------------------
    -- Pagination Meta
    ------------------------------------------------------
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]    
    INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]    
    WHERE pr.[Comp_ID] = @Comp_Id
      -- Date filtering on PurchaseDate
      AND (@StartDate IS NULL OR war.PurchaseDate >= @StartDate)
      AND (@EndDate IS NULL OR war.PurchaseDate <= @EndDate)
      -- General Search filter (includes Code search without hyphen)
      AND (@SearchParam IS NULL OR 
           war.Mobile LIKE @SearchParam OR 
           war.BillNo LIKE @SearchParam OR 
           war.Serialno LIKE @SearchParam OR 
           war.Email LIKE @SearchParam OR
           pr.Pro_Name LIKE @SearchParam OR
           (CAST(Mc.[Code1] AS VARCHAR(20)) + CAST(Mc.[Code2] AS VARCHAR(20))) LIKE @SearchParam OR
           war.[Code] LIKE @SearchParam);
END
GO
