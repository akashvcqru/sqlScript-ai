USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_PFL_GetBatchScrapeCountByUser]    Script Date: 3/2/2026 12:27:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
        SET @EndDate   = DATEADD(DAY,1,@ToDate);
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
            SELECT @StartDate=@Today, @EndDate=DATEADD(DAY,1,@Today);
        ELSE IF @Win = 'YESTERDAY'
            SELECT @StartDate=DATEADD(DAY,-1,@Today), @EndDate=@Today;
        ELSE IF @Win = 'MONTH'
            SELECT @StartDate=DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1),
                   @EndDate=DATEADD(DAY,1,@Today);
        ELSE
            SELECT @StartDate='19000101', @EndDate=DATEADD(DAY,1,@Today);
    END

    -------------------------------------------------
    -- Temp table
    -------------------------------------------------
    DROP TABLE IF EXISTS #Data;

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

    -------------------------------------------------
    -- Insert aggregated data
    -------------------------------------------------
    INSERT INTO #Data
    SELECT
        MIN(s.Id),
        b.[Batch No],
        b.SKU,
        b.[From],
        b.[To],
        s.ScrapedBy,
        u.UserName,
        COUNT(DISTINCT s.SerialCode) AS ScrapedCount,
        MAX(s.ScrapedDate) AS RequestDate
    FROM PFL_Batchlist b
    INNER JOIN tblScrapdatapfl s
        ON s.SerialCode BETWEEN b.[From] AND b.[To]
       AND s.CompanyId = 'Comp-1693'
       AND s.ScrapedDate >= @StartDate
       AND s.ScrapedDate <  @EndDate
       AND NOT EXISTS (
            SELECT 1
            FROM M_code_PFL m
            WHERE m.code1 = s.code1
              AND m.code2 = s.code2
              AND m.ScrapeFlag = 1
       )
    LEFT JOIN tbl_pflUsers u
        ON u.UserMobile = s.ScrapedBy
    WHERE (
        @Search IS NULL 
        OR @Search = ''
        OR b.[Batch No] LIKE '%' + @Search + '%'
        OR b.SKU LIKE '%' + @Search + '%'
        OR s.SerialCode LIKE '%' + @Search + '%'
        OR b.[From] LIKE '%' + @Search + '%'
        OR b.[To] LIKE '%' + @Search + '%'
    )
    GROUP BY
        b.[Batch No],
        b.SKU,
        b.[From],
        b.[To],
        s.ScrapedBy,
        u.UserName;

    -------------------------------------------------
    -- Output
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
            COUNT(*) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #Data;
    END
END
GO
