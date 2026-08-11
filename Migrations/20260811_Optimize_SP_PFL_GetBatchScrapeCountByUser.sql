-- Migration: Optimize SP_PFL_GetBatchScrapeCountByUser
-- Date: 2026-08-11

-- 1. Create index on PFL_Batchlist for From, To ranges if not exists
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.PFL_Batchlist') AND name = 'IDX_PFL_Batchlist_From_To')
BEGIN
    CREATE NONCLUSTERED INDEX [IDX_PFL_Batchlist_From_To]
    ON [dbo].[PFL_Batchlist] ([From], [To])
    INCLUDE ([Batch No], [SKU]);
END
GO

-- 3. Deploy optimized stored procedure SP_PFL_GetBatchScrapeCountByUser
CREATE OR ALTER PROCEDURE [dbo].[SP_PFL_GetBatchScrapeCountByUser]
(
    @FromDate   DATE = NULL,
    @ToDate     DATE = NULL,
    @Window     NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, QUARTER
    @Page       INT = NULL,
    @Limit      INT = NULL,
    @IsExport   BIT = NULL,
    @Search     NVARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -------------------------------------------------
    -- Sanitize search input & pagination defaults
    -------------------------------------------------
    IF LTRIM(RTRIM(@Search)) = '' SET @Search = NULL;
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -------------------------------------------------
    -- Date window logic
    -------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@Window,''));

    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = DATEADD(DAY, 1, @ToDate);
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'YESTERDAY'
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @Today);
            SET @EndDate   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'LASTWEEK'
        BEGIN
            SET DATEFIRST 1;
            DECLARE @ThisWeekStart DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
            SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
            SET @EndDate   = @ThisWeekStart;
        END
        ELSE IF @Win = 'MONTH'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'LASTMONTH'
        BEGIN
            DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @StartDate = DATEADD(MONTH, -1, @ThisMonthStart);
            SET @EndDate   = @ThisMonthStart;
        END
        ELSE IF @Win = 'QUARTER'
        BEGIN
            SET @StartDate = DATEADD(DAY, -90, @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE
        BEGIN
            SET @StartDate = '1900-01-01';
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
    END

    -------------------------------------------------
    -- Temp tables cleanup
    -------------------------------------------------
    DROP TABLE IF EXISTS #ScrapFiltered;
    DROP TABLE IF EXISTS #Data;

    -------------------------------------------------
    -- STEP 1: Pre-filter scrap records by Date, CompId, and ScrapeFlag
    -------------------------------------------------
    SELECT
        s.Id,
        s.SerialCode,
        s.ScrapedBy,
        s.ScrapedDate
    INTO #ScrapFiltered
    FROM tblScrapdatapfl s WITH (NOLOCK)
    WHERE s.CompanyId = 'Comp-1693'
      AND s.ScrapedDate >= @StartDate
      AND s.ScrapedDate <  @EndDate
      AND NOT EXISTS (
           SELECT 1
           FROM M_code_PFL m WITH (NOLOCK)
           WHERE m.code1 = s.code1
             AND m.code2 = s.code2
             AND m.ScrapeFlag = 1
      );

    CREATE NONCLUSTERED INDEX IX_ScrapFiltered_Serial ON #ScrapFiltered (SerialCode)
    INCLUDE (Id, ScrapedBy, ScrapedDate);

    -------------------------------------------------
    -- STEP 2: Aggregate matching batch records
    -------------------------------------------------
    CREATE TABLE #Data
    (
        ID BIGINT,
        BatchNo NVARCHAR(100),
        SKU NVARCHAR(100),
        [From] NVARCHAR(100),
        [To] NVARCHAR(100),
        MobileNo NVARCHAR(50),
        UserName NVARCHAR(200),
        ScrapedCount INT,
        RequestDate DATETIME
    );

    INSERT INTO #Data (ID, BatchNo, SKU, [From], [To], MobileNo, UserName, ScrapedCount, RequestDate)
    SELECT
        MIN(sf.Id) AS ID,
        b.[Batch No] AS BatchNo,
        b.SKU,
        b.[From],
        b.[To],
        sf.ScrapedBy AS MobileNo,
        u.UserName,
        COUNT(DISTINCT sf.SerialCode) AS ScrapedCount,
        MAX(sf.ScrapedDate) AS RequestDate
    FROM PFL_Batchlist b WITH (NOLOCK)
    INNER JOIN #ScrapFiltered sf
        ON sf.SerialCode >= b.[From]
       AND sf.SerialCode <= b.[To]
    LEFT JOIN tbl_pflUsers u WITH (NOLOCK)
        ON u.UserMobile = sf.ScrapedBy
    WHERE (
        @Search IS NULL 
        OR b.[Batch No] LIKE '%' + @Search + '%'
        OR b.SKU LIKE '%' + @Search + '%'
        OR sf.SerialCode LIKE '%' + @Search + '%'
        OR sf.ScrapedBy LIKE '%' + @Search + '%'
        OR u.UserName LIKE '%' + @Search + '%'
        OR b.[From] LIKE '%' + @Search + '%'
        OR b.[To] LIKE '%' + @Search + '%'
    )
    GROUP BY
        b.[Batch No],
        b.SKU,
        b.[From],
        b.[To],
        sf.ScrapedBy,
        u.UserName;

    -------------------------------------------------
    -- STEP 3: Return Output
    -------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #Data
        ORDER BY RequestDate DESC;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #Data
        ORDER BY RequestDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #Data;
    END
END
GO
