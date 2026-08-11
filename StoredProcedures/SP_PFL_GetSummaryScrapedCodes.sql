USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_PFL_GetSummaryScrapedCodes]    Script Date: 3/2/2026 12:27:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec SP_PFL_GetSummaryScrapedCodes 'NAWC250189', '9761497025', 'AM29-2732-5989', 'AM29-2751-5990', NULL, NULL, NULL, 1, 10, 0

CREATE OR ALTER PROCEDURE [dbo].[SP_PFL_GetSummaryScrapedCodes]
(
    @BatchNo      NVARCHAR(50) = NULL,
    @MobileNo     NVARCHAR(20) = NULL,
    @FromSerial   NVARCHAR(50) = NULL,
    @ToSerial     NVARCHAR(50) = NULL,

    @FromDate     DATE = NULL,
    @ToDate       DATE = NULL,
    @Window       NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, QUARTER

    @Page         INT = 1,
    @Limit        INT = 10,
    @IsExport     BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DROP TABLE IF EXISTS #ScrapFiltered;
    DROP TABLE IF EXISTS #FinalData;

    -------------------------------------------------
    -- Pagination defaults
    -------------------------------------------------
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
    -- STEP 1: Filter scrap records matching M_code_PFL ScrapeFlag = 1
    -------------------------------------------------
    SELECT
        s.Id,
        s.SerialCode,
        CONCAT(s.Code1, s.Code2) AS ScrapedCode,
        s.ScrapedBy AS MobileNo,
        s.ScrapedDate,
        s.scrapeCodeDate
    INTO #ScrapFiltered
    FROM tblScrapdatapfl s
    INNER JOIN M_code_PFL m
        ON m.code1 = s.code1
       AND m.code2 = s.code2
       AND m.ScrapeFlag = 1
    WHERE s.CompanyId = 'Comp-1693'
      AND s.ScrapedDate >= @StartDate
      AND s.ScrapedDate <  @EndDate
      AND (@MobileNo IS NULL OR s.ScrapedBy = @MobileNo);

    -------------------------------------------------
    -- STEP 2: Join with Batch List and User info
    -------------------------------------------------
    SELECT DISTINCT
        sf.SerialCode,
        sf.ScrapedCode,
        sf.MobileNo,
        u.UserName AS ScrapedByName,
        ISNULL(sf.scrapeCodeDate, sf.ScrapedDate) AS ScrapedDate,
        b.[Batch No] AS BatchNo,
        b.SKU
    INTO #FinalData
    FROM PFL_Batchlist b
    INNER JOIN #ScrapFiltered sf
        ON sf.SerialCode >= b.[From]
       AND sf.SerialCode <= b.[To]
    LEFT JOIN tbl_pflUsers u
        ON u.UserMobile = sf.MobileNo
    WHERE (@BatchNo IS NULL OR b.[Batch No] = @BatchNo)
      AND (@FromSerial IS NULL OR b.[From] = @FromSerial OR sf.SerialCode >= @FromSerial)
      AND (@ToSerial IS NULL OR b.[To] = @ToSerial OR sf.SerialCode <= @ToSerial);

    -------------------------------------------------
    -- OUTPUT
    -------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT
            SerialCode AS SerialNo,
            ScrapedCode,
            MobileNo,
            ScrapedByName,
            ScrapedDate,
            BatchNo,
            SKU
        FROM #FinalData
        ORDER BY ScrapedDate DESC;
    END
    ELSE
    BEGIN
        SELECT
            SerialCode AS SerialNo,
            ScrapedCode,
            MobileNo,
            ScrapedByName,
            ScrapedDate,
            BatchNo,
            SKU
        FROM #FinalData
        ORDER BY ScrapedDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
