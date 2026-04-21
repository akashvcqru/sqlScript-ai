/****** Object:  StoredProcedure [dbo].[SP_Get_CodeVerificationReportMNM_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Get_CodeVerificationReportMNM_AI]
(
    @CompId VARCHAR(50),
    @TimeWindow VARCHAR(20) = NULL,
    @FromDate   DATETIME = NULL,
    @ToDate     DATETIME = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
     @IsExport BIT = NULL,
      @Search NVARCHAR(20) = NULL
)
AS
BEGIN
  SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Defaults
    ---------------------------------------------------------
    IF @IsExport IS NULL SET @IsExport = 0;
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 20;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- DATE RANGE CALCULATION
    ---------------------------------------------------------
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize TimeWindow
    IF (
           @TimeWindow IS NULL
        OR LTRIM(RTRIM(@TimeWindow)) = ''
        OR LOWER(LTRIM(RTRIM(@TimeWindow))) = 'null'
    )
        SET @TimeWindow = NULL;
    ELSE
        SET @TimeWindow = UPPER(LTRIM(RTRIM(@TimeWindow)));

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

        IF (@TimeWindow = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@TimeWindow = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@TimeWindow = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@TimeWindow = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@TimeWindow = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);

        ELSE -- ALL / NULL
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    ---------------------------------------------------------
    -- EXPORT → FULL DATA
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT
            C.MobileNo,
            (C.Code1 + C.Code2) AS UniqueCode,
            C.Enq_Date,
            C.Points,
            C.Cash,
            C.Pro_id,
            C.Is_Success,
            CASE 
                WHEN C.Is_Success = 1 THEN 'Verified'
                WHEN C.Is_Success = 2 THEN 'Already Scanned'
                ELSE 'Invalid'
            END AS VerificationStatus,
            C.Pro_Name,
            C.Latitude,
            C.Longitude,
            C.Dial_Mode
        FROM ConsumerPointsCashDetails C
        WHERE C.Comp_id = @CompId
          AND C.Enq_Date >= @StartDate
          AND C.Enq_Date <  DATEADD(DAY, 1, @EndDate)
          AND (
       @Search IS NULL
    OR LTRIM(RTRIM(@Search)) = ''
    OR REPLACE(C.MobileNo,' ','') LIKE '%' + RIGHT(REPLACE(@Search,' ',''), 10) + '%'
)
        ORDER BY C.Enq_Date DESC;

        RETURN;
    END

    ---------------------------------------------------------
    -- PAGINATED DATA
    ---------------------------------------------------------
    SELECT
        C.MobileNo,
        (C.Code1 + C.Code2) AS UniqueCode,
        C.Enq_Date,
        C.Points,
        C.Cash,
        C.Pro_id,
        C.Is_Success,
        CASE 
            WHEN C.Is_Success = 1 THEN 'Verified'
            WHEN C.Is_Success = 2 THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS VerificationStatus,
        C.Pro_Name,
        C.Latitude,
        C.Longitude,
        C.Dial_Mode
    FROM ConsumerPointsCashDetails C
    WHERE C.Comp_id = @CompId
      AND C.Enq_Date >= @StartDate
      AND C.Enq_Date <  DATEADD(DAY, 1, @EndDate)
      AND (
       @Search IS NULL
    OR LTRIM(RTRIM(@Search)) = ''
    OR REPLACE(C.MobileNo,' ','') LIKE '%' + RIGHT(REPLACE(@Search,' ',''), 10) + '%'
)
    ORDER BY C.Enq_Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ---------------------------------------------------------
    -- PAGINATION META
    ---------------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page    AS CurrentPage,
        @Limit   AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM ConsumerPointsCashDetails
    WHERE Comp_id = @CompId
      AND Enq_Date >= @StartDate
      AND Enq_Date <  DATEADD(DAY, 1, @EndDate)
       AND (
        @Search IS NULL
     OR LTRIM(RTRIM(@Search)) = ''
     OR REPLACE(MobileNo,' ','') LIKE '%' + RIGHT(REPLACE(@Search,' ',''), 10) + '%'
  );
END
GO
