-- USP_GetPancardList_AI
-- Fetch all pancard details for consumers under a given company where pancard is not null/empty
-- Supports pagination, date preset/range, isExport, keyword search (including status match)
ALTER PROCEDURE [dbo].[USP_GetPancardList_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset VARCHAR(20) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL,
    @Search NVARCHAR(100) = NULL,
    @IspanOperative INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Pagination Defaults
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Date Range Setup
    ---------------------------------------------------------
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize datePreset
    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @Win NVARCHAR(50) = @datePreset;

    -- Explicit date range overrides TimeWindow
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1; -- Monday start

        IF (@Win = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@Win = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@Win = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);
            
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
    END

    ---------------------------------------------------------
    -- Select Results with total count
    ---------------------------------------------------------
    SELECT 
        mc.M_Consumerid,
        mc.MobileNo,
        mc.pancard_number,
        CASE WHEN mc.IspanOperative = 1 THEN 'In Operative' ELSE 'Operative' END AS IspanOperative,
        COUNT(1) OVER() AS TotalRecords
    FROM M_Consumer mc WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus tvk WITH (NOLOCK)
        ON mc.M_Consumerid = tvk.M_consumerId
    WHERE tvk.Comp_id = @Comp_ID
      AND ISNULL(mc.pancard_number, '') <> ''
      AND (
          (@StartDate IS NULL OR @EndDate IS NULL)
          OR CAST(mc.Entry_Date AS DATE) BETWEEN @StartDate AND @EndDate
      )
      AND (
          @IspanOperative IS NULL
          OR mc.IspanOperative = @IspanOperative
      )
      AND (
          @Search IS NULL
          OR LTRIM(RTRIM(@Search)) = ''
          OR REPLACE(mc.MobileNo, ' ', '') LIKE '%' + REPLACE(@Search, ' ', '') + '%'
          OR mc.ConsumerName LIKE '%' + @Search + '%'
          OR mc.pancard_number LIKE '%' + @Search + '%'
          -- Status match
          OR (REPLACE(LOWER(LTRIM(RTRIM(@Search))), ' ', '') = 'inoperative' AND mc.IspanOperative = 1)
          OR (REPLACE(LOWER(LTRIM(RTRIM(@Search))), ' ', '') = 'operative' AND ISNULL(mc.IspanOperative, 0) = 0)
      )
    ORDER BY mc.Entry_Date DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END ROWS ONLY;
END
GO
