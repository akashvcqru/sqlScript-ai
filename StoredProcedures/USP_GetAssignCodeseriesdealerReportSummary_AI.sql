USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetAssignCodeseriesdealerReportSummary_AI]    Script Date: 10-09-2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 10-09-2026
-- Description: Get Assign Code Series Dealer Report Summary (Grouped View) with Pagination, Filters, and Export
-- Reference:   USP_viewassignSerieslocation_sp / tbl_assigncodelocation
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetAssignCodeseriesdealerReportSummary_AI]
(
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @DealerName NVARCHAR(100) = NULL,
    @FromSeries NVARCHAR(50) = NULL,
    @ToSeries NVARCHAR(50) = NULL,
    @Passcode NVARCHAR(20) = NULL,
    @IsExport BIT = 0
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
    IF @IsExport IS NULL SET @IsExport = 0;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------
    -- Clean & Normalize Input Parameters
    ------------------------------------------------------
    SET @DealerName = LTRIM(RTRIM(REPLACE(ISNULL(@DealerName, ''), '%20', ' ')));
    SET @FromSeries = LTRIM(RTRIM(REPLACE(ISNULL(@FromSeries, ''), '%20', ' ')));
    SET @ToSeries = LTRIM(RTRIM(REPLACE(ISNULL(@ToSeries, ''), '%20', ' ')));
    SET @Passcode = LTRIM(RTRIM(REPLACE(ISNULL(@Passcode, ''), '%20', ' ')));
    SET @Search = LTRIM(RTRIM(REPLACE(ISNULL(@Search, ''), '%20', ' ')));

    -- Strip leading/trailing double quotes if passed by caller e.g. "MP-Rashid Khan (Devas) "
    IF LEN(@DealerName) >= 2 AND LEFT(@DealerName, 1) = '"' AND RIGHT(@DealerName, 1) = '"'
        SET @DealerName = SUBSTRING(@DealerName, 2, LEN(@DealerName) - 2);

    ------------------------------------------------------
    -- Date Range Logic
    ------------------------------------------------------
    DECLARE @StartDate DATETIME = @FromDate;
    DECLARE @EndDate   DATETIME = @ToDate;

    IF (@datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null' AND LOWER(@datePreset) <> 'all')
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'WEEK')
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, DATEADD(DAY, 6, @StartDate)));
        END
        ELSE IF (@Win = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1));
        END
    END
    ELSE IF (@StartDate IS NOT NULL AND @EndDate IS NOT NULL)
    BEGIN
        -- Ensure entire end date is covered
        IF CAST(@EndDate AS TIME) = '00:00:00'
            SET @EndDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, @EndDate));
    END

    ------------------------------------------------------
    -- Search Pattern
    ------------------------------------------------------
    DECLARE @SearchParam NVARCHAR(102) = NULL;
    IF @Search IS NOT NULL AND @Search <> ''
        SET @SearchParam = '%' + @Search + '%';

    ------------------------------------------------------
    -- 1. Main Grouped Data Query
    ------------------------------------------------------
    ;WITH FilteredBase AS (
        SELECT 
            a.fromseries,
            a.toseries,
            a.Passcode,
            a.dealer_name,
            a.Comp_ID,
            a.Pro_ID,
            a.entry_date,
            pr.Pro_Name AS ProductName
        FROM [dbo].[tbl_assigncodelocation] a WITH (NOLOCK)
        LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) ON pr.Pro_ID = a.Pro_ID AND pr.Comp_ID = a.Comp_ID
        WHERE a.Comp_ID = @Comp_Id
          AND (@StartDate IS NULL OR a.entry_date >= @StartDate)
          AND (@EndDate IS NULL OR a.entry_date <= @EndDate)
          AND (@Passcode IS NULL OR @Passcode = '' OR a.Passcode = @Passcode)
          AND (@DealerName IS NULL OR @DealerName = '' OR a.dealer_name = @DealerName OR a.dealer_name LIKE '%' + @DealerName + '%')
          AND (@FromSeries IS NULL OR @FromSeries = '' OR a.fromseries = @FromSeries OR a.fromseries LIKE '%' + @FromSeries + '%')
          AND (@ToSeries IS NULL OR @ToSeries = '' OR a.toseries = @ToSeries OR a.toseries LIKE '%' + @ToSeries + '%')
          AND (@SearchParam IS NULL 
               OR a.Passcode LIKE @SearchParam 
               OR a.dealer_name LIKE @SearchParam 
               OR a.fromseries LIKE @SearchParam 
               OR a.toseries LIKE @SearchParam 
               OR pr.Pro_Name LIKE @SearchParam)
    ),
    GroupedResult AS (
        SELECT 
            fromseries AS FromSeries,
            toseries AS ToSeries,
            COUNT(1) AS Quantity,
            Passcode AS Passcode,
            dealer_name AS DealerName,
            MAX(entry_date) AS EntryDate,
            Pro_ID AS ProId,
            ProductName AS ProductName
        FROM FilteredBase
        GROUP BY fromseries, toseries, Passcode, dealer_name, Pro_ID, ProductName
    )
    SELECT * 
    FROM GroupedResult
    ORDER BY EntryDate DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS 
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 1000000 ELSE @Limit END ROWS ONLY;

    ------------------------------------------------------
    -- 2. Pagination Meta
    ------------------------------------------------------
    IF @IsExport = 0
    BEGIN
        ;WITH FilteredBase AS (
            SELECT 
                a.fromseries,
                a.toseries,
                a.Passcode,
                a.dealer_name,
                a.Comp_ID,
                a.Pro_ID,
                pr.Pro_Name AS ProductName
            FROM [dbo].[tbl_assigncodelocation] a WITH (NOLOCK)
            LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) ON pr.Pro_ID = a.Pro_ID AND pr.Comp_ID = a.Comp_ID
            WHERE a.Comp_ID = @Comp_Id
              AND (@StartDate IS NULL OR a.entry_date >= @StartDate)
              AND (@EndDate IS NULL OR a.entry_date <= @EndDate)
              AND (@Passcode IS NULL OR @Passcode = '' OR a.Passcode = @Passcode)
              AND (@DealerName IS NULL OR @DealerName = '' OR a.dealer_name = @DealerName OR a.dealer_name LIKE '%' + @DealerName + '%')
              AND (@FromSeries IS NULL OR @FromSeries = '' OR a.fromseries = @FromSeries OR a.fromseries LIKE '%' + @FromSeries + '%')
              AND (@ToSeries IS NULL OR @ToSeries = '' OR a.toseries = @ToSeries OR a.toseries LIKE '%' + @ToSeries + '%')
              AND (@SearchParam IS NULL 
                   OR a.Passcode LIKE @SearchParam 
                   OR a.dealer_name LIKE @SearchParam 
                   OR a.fromseries LIKE @SearchParam 
                   OR a.toseries LIKE @SearchParam 
                   OR pr.Pro_Name LIKE @SearchParam)
            GROUP BY a.fromseries, a.toseries, a.Passcode, a.dealer_name, a.Comp_ID, a.Pro_ID, pr.Pro_Name
        )
        SELECT 
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM FilteredBase;
    END
END
GO
