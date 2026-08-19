USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[sp_codescraperequest]    Script Date: 2026-08-19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_codescraperequest]
(
    @DatePreset   VARCHAR(50) = NULL,
    @FromDate     VARCHAR(50) = NULL,
    @ToDate       VARCHAR(50) = NULL,
    @Search       NVARCHAR(100) = NULL,
    @SerialCode   NVARCHAR(100) = NULL,
    @Code         NVARCHAR(100) = NULL,
    @Page         INT = 1,
    @Limit        INT = 10,
    @IsExport     BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    ----------------------------------------------------
    -- Pagination Defaults
    ----------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ----------------------------------------------------
    -- Date Range Calculation
    ----------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Clean parameters
    SET @DatePreset = NULLIF(LTRIM(RTRIM(@DatePreset)), '');
    SET @FromDate   = NULLIF(LTRIM(RTRIM(@FromDate)), '');
    SET @ToDate     = NULLIF(LTRIM(RTRIM(@ToDate)), '');
    SET @Search     = NULLIF(LTRIM(RTRIM(@Search)), '');
    SET @SerialCode = NULLIF(LTRIM(RTRIM(@SerialCode)), '');
    SET @Code       = NULLIF(LTRIM(RTRIM(@Code)), '');

    IF (@DatePreset IS NOT NULL)
    BEGIN
        DECLARE @NormalizedPreset VARCHAR(50) = LOWER(REPLACE(@DatePreset, ' ', ''));

        IF (@NormalizedPreset = 'today')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME)));
        END
        ELSE IF (@NormalizedPreset = 'yesterday' OR @NormalizedPreset = 'lastday')
        BEGIN
            SET @StartDate = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
            SET @EndDate   = DATEADD(SECOND, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        END
        ELSE IF (@NormalizedPreset = 'week' OR @NormalizedPreset = 'currentweek')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), GETDATE()) AS DATE);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@NormalizedPreset = 'lastweek')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = CAST(DATEADD(DAY, -(DATEPART(WEEKDAY, GETDATE()) + 6), GETDATE()) AS DATE);
            SET @EndDate   = DATEADD(SECOND, -1, CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME));
        END
        ELSE IF (@NormalizedPreset = 'month' OR @NormalizedPreset = 'currentmonth')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@NormalizedPreset = 'lastmonth')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) AS DATETIME));
        END
        ELSE IF (@NormalizedPreset = 'quarter')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@NormalizedPreset = 'year' OR @NormalizedPreset = 'currentyear')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@NormalizedPreset = 'lastyear')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME));
        END
        ELSE IF (@NormalizedPreset = 'last7days')
        BEGIN
            SET @StartDate = CAST(DATEADD(DAY, -7, GETDATE()) AS DATE);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@NormalizedPreset = 'last30days')
        BEGIN
            SET @StartDate = CAST(DATEADD(DAY, -30, GETDATE()) AS DATE);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@NormalizedPreset = 'custom')
        BEGIN
            IF (@FromDate IS NOT NULL AND ISDATE(@FromDate) = 1)
                SET @StartDate = CAST(@FromDate AS DATETIME);
            IF (@ToDate IS NOT NULL AND ISDATE(@ToDate) = 1)
                SET @EndDate = CASE WHEN CAST(@ToDate AS DATETIME) = CAST(CAST(@ToDate AS DATE) AS DATETIME) 
                                    THEN DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(CAST(@ToDate AS DATE) AS DATETIME))) 
                                    ELSE CAST(@ToDate AS DATETIME) END;
        END
    END
    ELSE IF (@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
    BEGIN
        IF (@FromDate IS NOT NULL AND ISDATE(@FromDate) = 1)
            SET @StartDate = CAST(@FromDate AS DATETIME);
        IF (@ToDate IS NOT NULL AND ISDATE(@ToDate) = 1)
            SET @EndDate = CASE WHEN CAST(@ToDate AS DATETIME) = CAST(CAST(@ToDate AS DATE) AS DATETIME) 
                                THEN DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(CAST(@ToDate AS DATE) AS DATETIME))) 
                                ELSE CAST(@ToDate AS DATETIME) END;
    END

    ----------------------------------------------------
    -- Filter and Output
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#ScrapData') IS NOT NULL DROP TABLE #ScrapData;

    SELECT 
        id,
        Code1,
        Code2,
        SerialCode,
        ScrapedBy,
        scrapeCodeDate AS ScrapeDateRequest
    INTO #ScrapData
    FROM tblScrapdatapfl WITH (NOLOCK)
    WHERE 
        (@StartDate IS NULL OR scrapeCodeDate >= @StartDate)
        AND (@EndDate IS NULL OR scrapeCodeDate <= @EndDate)
        AND (
            @Search IS NULL 
            OR SerialCode LIKE '%' + @Search + '%'
            OR Code1 LIKE '%' + @Search + '%'
            OR Code2 LIKE '%' + @Search + '%'
            OR (ISNULL(Code1, '') + ISNULL(Code2, '')) LIKE '%' + @Search + '%'
            OR ScrapedBy LIKE '%' + @Search + '%'
        )
        AND (
            @SerialCode IS NULL 
            OR SerialCode LIKE '%' + @SerialCode + '%'
        )
        AND (
            @Code IS NULL 
            OR Code1 LIKE '%' + @Code + '%'
            OR Code2 LIKE '%' + @Code + '%'
            OR (ISNULL(Code1, '') + ISNULL(Code2, '')) LIKE '%' + @Code + '%'
        );

    IF (@IsExport = 1)
    BEGIN
        SELECT 
            id,
            Code1,
            Code2,
            SerialCode,
            ScrapedBy,
            ScrapeDateRequest
        FROM #ScrapData
        ORDER BY id DESC;
    END
    ELSE
    BEGIN
        -- Result 1: Paginated Rows
        SELECT 
            id,
            Code1,
            Code2,
            SerialCode,
            ScrapedBy,
            ScrapeDateRequest
        FROM #ScrapData
        ORDER BY id DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Result 2: Pagination Meta
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #ScrapData;
    END
END
GO
