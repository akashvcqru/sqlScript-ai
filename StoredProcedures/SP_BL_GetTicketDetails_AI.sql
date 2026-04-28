SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec [dbo].[SP_BL_GetTicketDetails_AI] 'Comp-1926','WEEK',NULL,NULL,NULL,1,10,1,'919649977182'
CREATE PROCEDURE [dbo].[SP_BL_GetTicketDetails_AI]
    @Comp_Id VARCHAR(50),
    @datePreset VARCHAR(20) = NULL, -- e.g., TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
     @FromDate DATE = NULL,            -- NEW
    @ToDate DATE = NULL,              -- NEW
    @TicketStatus VARCHAR(20) = NULL,  -- NEW (Failed, Closed, Open)
     @Page INT = NULL,                   -- ✅ NEW
    @Limit INT = NULL,
     @IsExport BIT =NULL,
       @Search NVARCHAR(30) = NULL 
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
    -- Date Range
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

    ELSE -- ALL / NULL
    BEGIN
        SET @StartDate = NULL;
        SET @EndDate   = NULL;
    END
END

    ---------------------------------------------------------
    -- Deduplicate UPI Transactions (Exclude SUCCESS)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#DedupUPI') IS NOT NULL DROP TABLE #DedupUPI;

    SELECT
        UPI.ID AS TicketID,
        UPI.Comp_ID,
        UPI.Points_Val,
        UPI.Amount,
        UPI.tdsAmount,
        UPI.tdsper,
        UPI.ConsumerName,
        UPI.MobileNo,
        UPI.UPI_Id,
        UPI.Status,
        UPI.Code1,
        UPI.Code2,
        UPI.ConsumerEmailId,
        UPI.ReqDate,
        UPI.Remarks,
        UPI.OrderId,
        UPI.M_Consumerid,
        ROW_NUMBER() OVER
        (
            PARTITION BY UPI.OrderId
            ORDER BY UPI.ReqDate DESC
        ) AS rn
    INTO #DedupUPI
    FROM tblUPITransactionDetails UPI
    INNER JOIN ClaimDetails CD
        ON CD.Mobileno = UPI.MobileNo
    WHERE
        UPI.Comp_ID = @Comp_Id
        AND UPI.Status <> 'Success'     -- ✅ KEY CONDITION
        AND (@TicketStatus IS NULL OR UPI.Status = @TicketStatus)
        AND UPI.Remarks IS NOT NULL
        AND CAST(UPI.ReqDate AS DATE) BETWEEN @StartDate AND @EndDate
        AND (
                @Search IS NULL
             OR LTRIM(RTRIM(@Search)) = ''
             OR REPLACE(UPI.MobileNo,' ','') LIKE '%' + REPLACE(@Search,' ','') + '%'
            );

    ---------------------------------------------------------
    -- RESULT SET 1 : DATA
    ---------------------------------------------------------
    SELECT
        TicketID,
        Amount,
        tdsAmount,
        tdsper,
        M_Consumerid,
        ConsumerName,
        MobileNo,
        UPI_Id,
        Status,
        Code1,
        Code2,
        ConsumerEmailId,
        ReqDate,
        Remarks
    FROM #DedupUPI
    WHERE rn = 1
    ORDER BY ReqDate DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END ROWS ONLY;

    ---------------------------------------------------------
    -- RESULT SET 2 : META
    ---------------------------------------------------------
    IF (@IsExport = 0)
    BEGIN
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #DedupUPI
        WHERE rn = 1;
    END
END
GO
