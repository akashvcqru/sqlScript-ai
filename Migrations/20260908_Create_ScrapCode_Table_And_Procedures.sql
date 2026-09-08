-- Migration: 20260908_Create_ScrapCode_Table_And_Procedures.sql
-- Description: Stored procedures for bulk scraping and listing scraped codes using M_Code table (ScrapeFlag and Block_Code_Date)

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Create or Alter USP_ScrapCodes_ExcelUpload_AI
CREATE OR ALTER PROCEDURE [dbo].[USP_ScrapCodes_ExcelUpload_AI]
    @Comp_ID VARCHAR(50) = NULL,
    @ScrapedBy NVARCHAR(100) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @JsonData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalUploaded INT = 0;
    DECLARE @ScrappedCount INT = 0;
    DECLARE @AlreadyScrappedCount INT = 0;
    DECLARE @NotFoundCount INT = 0;

    -- Temp table for input data
    DROP TABLE IF EXISTS #InputCodes;
    CREATE TABLE #InputCodes (
        RowId INT IDENTITY(1,1) PRIMARY KEY,
        Code1 NUMERIC(5,0),
        Code2 NUMERIC(8,0),
        CompleteCode NVARCHAR(50)
    );

    BEGIN TRY
        INSERT INTO #InputCodes (Code1, Code2, CompleteCode)
        SELECT 
            TRY_CAST(Code1 AS NUMERIC(5,0)),
            TRY_CAST(Code2 AS NUMERIC(8,0)),
            CompleteCode
        FROM OPENJSON(@JsonData) WITH (
            Code1 NVARCHAR(20) '$.Code1',
            Code2 NVARCHAR(20) '$.Code2',
            CompleteCode NVARCHAR(50) '$.CompleteCode'
        )
        WHERE TRY_CAST(Code1 AS NUMERIC(5,0)) IS NOT NULL
          AND TRY_CAST(Code2 AS NUMERIC(8,0)) IS NOT NULL;

        SELECT @TotalUploaded = COUNT(1) FROM #InputCodes;

        IF @TotalUploaded = 0
        BEGIN
            SELECT 
                0 AS Success,
                'No valid codes found in payload.' AS Message,
                0 AS TotalUploaded,
                0 AS ScrappedCount,
                0 AS AlreadyScrappedCount,
                0 AS NotFoundCount;
            RETURN;
        END

        -- Temp table to capture existing code status in M_Code
        DROP TABLE IF EXISTS #CodesToUpdate;
        CREATE TABLE #CodesToUpdate (
            Code1 NUMERIC(5,0),
            Code2 NUMERIC(8,0),
            ExistingScrapeFlag TINYINT
        );

        INSERT INTO #CodesToUpdate (Code1, Code2, ExistingScrapeFlag)
        SELECT 
            i.Code1, 
            i.Code2, 
            m.ScrapeFlag
        FROM #InputCodes i
        INNER JOIN M_Code m WITH (NOLOCK) ON m.Code1 = i.Code1 AND m.Code2 = i.Code2;

        -- 1. Perform update on M_Code (setting ScrapeFlag = 1 and Block_Code_Date = GETDATE())
        UPDATE m
        SET m.ScrapeFlag = 1,
            m.Block_Code_Date = GETDATE()
        FROM M_Code m
        INNER JOIN #CodesToUpdate u
            ON m.Code1 = u.Code1
           AND m.Code2 = u.Code2
        WHERE ISNULL(m.ScrapeFlag, 0) <> 1;

        SET @ScrappedCount = @@ROWCOUNT;

        SELECT @AlreadyScrappedCount = COUNT(1) 
        FROM #CodesToUpdate 
        WHERE ExistingScrapeFlag = 1;

        SELECT @NotFoundCount = COUNT(1)
        FROM #InputCodes i
        WHERE NOT EXISTS (
            SELECT 1 FROM #CodesToUpdate u 
            WHERE u.Code1 = i.Code1 AND u.Code2 = i.Code2
        );

        SELECT 
            1 AS Success,
            CONCAT('Processing completed: ', @ScrappedCount, ' newly scrapped, ', @AlreadyScrappedCount, ' previously scrapped, ', @NotFoundCount, ' not found.') AS Message,
            @TotalUploaded AS TotalUploaded,
            @ScrappedCount AS ScrappedCount,
            @AlreadyScrappedCount AS AlreadyScrappedCount,
            @NotFoundCount AS NotFoundCount;

        DROP TABLE IF EXISTS #InputCodes;
        DROP TABLE IF EXISTS #CodesToUpdate;
    END TRY
    BEGIN CATCH
        DROP TABLE IF EXISTS #InputCodes;
        DROP TABLE IF EXISTS #CodesToUpdate;

        SELECT 
            0 AS Success,
            ERROR_MESSAGE() AS Message,
            0 AS TotalUploaded,
            0 AS ScrappedCount,
            0 AS AlreadyScrappedCount,
            0 AS NotFoundCount;
    END CATCH
END
GO

-- 2. Create or Alter USP_GetScrapCodeList_AI
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
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
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
