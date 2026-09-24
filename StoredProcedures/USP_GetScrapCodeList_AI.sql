SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetScrapCodeList_AI]
    @Comp_ID VARCHAR(50) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL,
    @datePreset VARCHAR(50) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @Search VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @IsExport = ISNULL(@IsExport, 0);
    SET @Search = LTRIM(RTRIM(ISNULL(@Search, '')));

    ----------------------------------------------------
    -- Date Range Calculation based on Block_Code_Date
    ----------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate DATETIME = NULL;

    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        SET @DatePreset = UPPER(LTRIM(RTRIM(ISNULL(@DatePreset, ''))));

        IF (@DatePreset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTDAY' OR @DatePreset = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@DatePreset = 'WEEK' OR @DatePreset = 'THISWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@DatePreset = 'MONTH' OR @DatePreset = 'THISMONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@DatePreset = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@DatePreset = 'YEAR' OR @DatePreset = 'THISYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF (@DatePreset = 'LAST7DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LAST30DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    ----------------------------------------------------
    -- Filtered Data from M_Code (ScrapeFlag = 1)
    ----------------------------------------------------
    DROP TABLE IF EXISTS #FilteredScrap;
    SELECT 
        m.Row_ID,
        CONCAT(
            RIGHT('00000' + CAST(m.Code1 AS VARCHAR(5)), 5),
            RIGHT('00000000' + CAST(m.Code2 AS VARCHAR(8)), 8)
        ) AS CompleteCode,
        CASE 
            WHEN (m.Pro_ID IS NOT NULL OR p.Pro_ID IS NOT NULL) AND (m.Series_Order IS NOT NULL OR m.Series_Serial IS NOT NULL)
            THEN CONCAT(
                ISNULL(m.Pro_ID, p.Pro_ID), '-', 
                CASE 
                    WHEN LEN(CAST(ISNULL(m.Series_Order, 0) AS VARCHAR(20))) < 4 
                    THEN RIGHT('0000' + CAST(ISNULL(m.Series_Order, 0) AS VARCHAR(20)), 4) 
                    ELSE CAST(m.Series_Order AS VARCHAR(20)) 
                END, '-', 
                CASE 
                    WHEN LEN(CAST(ISNULL(m.Series_Serial, 0) AS VARCHAR(20))) < 4 
                    THEN RIGHT('0000' + CAST(ISNULL(m.Series_Serial, 0) AS VARCHAR(20)), 4) 
                    ELSE CAST(m.Series_Serial AS VARCHAR(20)) 
                END
            )
            ELSE '' 
        END AS SerialNumber,
        m.Batch_No AS BatchNo,
        m.Pro_ID AS ProId,
        p.Pro_Name AS ProductName,
        m.ScrapeFlag,
        m.Block_Code_Date AS ScrapeDate
    INTO #FilteredScrap
    FROM M_Code m WITH (NOLOCK)
    LEFT JOIN Pro_Reg p WITH (NOLOCK) ON m.Pro_ID = p.Pro_ID
    WHERE m.ScrapeFlag = 1
      AND (@Comp_ID IS NULL OR @Comp_ID = '' OR p.Comp_ID = @Comp_ID)
      AND (@StartDate IS NULL OR ISNULL(m.Block_Code_Date, m.Gen_Date) >= @StartDate)
      AND (@EndDate IS NULL OR ISNULL(m.Block_Code_Date, m.Gen_Date) < @EndDate)
      AND (
          @Search = '' 
          OR CAST(m.Code1 AS NVARCHAR(20)) LIKE '%' + @Search + '%'
          OR CAST(m.Code2 AS NVARCHAR(20)) LIKE '%' + @Search + '%'
          OR CONCAT(m.Code1, m.Code2) LIKE '%' + @Search + '%'
          OR CONCAT(m.Code1, '-', m.Code2) LIKE '%' + @Search + '%'
          OR (m.Pro_ID IS NOT NULL AND CONCAT(m.Pro_ID, '-', RIGHT('0000' + CAST(ISNULL(m.Series_Order, 0) AS VARCHAR(4)), 4), '-', RIGHT('0000' + CAST(ISNULL(m.Series_Serial, 0) AS VARCHAR(4)), 4)) LIKE '%' + @Search + '%')
          OR m.Batch_No LIKE '%' + @Search + '%'
          OR m.Pro_ID LIKE '%' + @Search + '%'
          OR p.Pro_Name LIKE '%' + @Search + '%'
      );

    ----------------------------------------------------
    -- EXPORT MODE
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            Row_ID,
            CompleteCode,
            SerialNumber,
            BatchNo,
            ProId,
            ProductName,
            ScrapeFlag,
            ScrapeDate
        FROM #FilteredScrap
        ORDER BY ScrapeDate DESC, Row_ID DESC;

        DROP TABLE #FilteredScrap;
        RETURN;
    END

    ----------------------------------------------------
    -- PAGINATION
    ----------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -- Result Set 1: Paginated Rows
    SELECT 
        Row_ID,
        CompleteCode,
        SerialNumber,
        BatchNo,
        ProId,
        ProductName,
        ScrapeFlag,
        ScrapeDate
    FROM #FilteredScrap
    ORDER BY ScrapeDate DESC, Row_ID DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    -- Result Set 2: Pagination Summary
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM #FilteredScrap;

    DROP TABLE #FilteredScrap;
END
GO
