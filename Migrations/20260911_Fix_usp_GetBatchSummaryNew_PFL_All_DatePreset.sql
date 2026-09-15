-- Migration: Fix usp_GetBatchSummaryNew_PFL & usp_GetBatchSummaryNew_PFL_Temp date filtering when datePreset / Window is 'ALL'
-- Problem: Records with future RequestDate were excluded because @toDateDT was restricted to tomorrow.
-- Fix: Bypass RequestDate boundary condition when @Win = 'ALL'.

CREATE OR ALTER PROCEDURE [dbo].[usp_GetBatchSummaryNew_PFL]    
    @fromdate DATETIME = NULL,
    @todate DATETIME = NULL,
    @Window NVARCHAR(20) = NULL,
    @BatchNo NVARCHAR(100) = NULL,
    @SearchText NVARCHAR(200) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
AS    
BEGIN    
    SET NOCOUNT ON;

    -------------------------------------------------
    -- Sanitize inputs
    -------------------------------------------------
    IF LTRIM(RTRIM(@SearchText)) = '' SET @SearchText = NULL;
    IF LTRIM(RTRIM(@BatchNo)) = '' SET @BatchNo = NULL;

    -------------------------------------------------
    -- Pagination defaults
    -------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -------------------------------------------------
    -- Date window calculation
    -------------------------------------------------
    DECLARE @fromDateDT DATETIME = NULL;
    DECLARE @toDateDT   DATETIME = NULL;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@Window, ''));

    -- Explicit dates have highest priority
    IF @fromdate IS NOT NULL OR @todate IS NOT NULL
    BEGIN
        SET @fromDateDT = ISNULL(@fromdate, '19000101');

        IF @todate IS NOT NULL
            SET @toDateDT = DATEADD(DAY, 1, @todate);   -- inclusive end date
        ELSE
            SET @toDateDT = '99991231';
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @fromDateDT = @Today;
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'YESTERDAY'
        BEGIN
            SET @fromDateDT = DATEADD(DAY, -1, @Today);
            SET @toDateDT   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            DECLARE @MondayThisWeek DATE =
                DATEADD(DAY, -((DATEPART(WEEKDAY,@Today) + @@DATEFIRST - 2) % 7), @Today);

            SET @fromDateDT = @MondayThisWeek;
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'LASTWEEK'
        BEGIN
            DECLARE @MondayThisWeek2 DATE =
                DATEADD(DAY, -((DATEPART(WEEKDAY,@Today) + @@DATEFIRST - 2) % 7), @Today);

            SET @fromDateDT = DATEADD(DAY, -7, @MondayThisWeek2);
            SET @toDateDT   = @MondayThisWeek2;
        END
        ELSE IF @Win = 'LASTMONTH'
        BEGIN
            DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @fromDateDT = DATEADD(MONTH, -1, @ThisMonthStart);
            SET @toDateDT   = @ThisMonthStart;
        END
        ELSE IF @Win = 'QUARTER'
        BEGIN
            SET @fromDateDT = DATEADD(DAY, -90, @Today);
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'ALL'
        BEGIN
            -- Do not restrict dates for ALL
            SET @fromDateDT = NULL;
            SET @toDateDT   = NULL;
        END
        ELSE
        BEGIN
            -- Default = current month
            DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @fromDateDT = @MonthStart;
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
    END

    -------------------------------------------------
    -- Build result into temp table
    -------------------------------------------------
    DROP TABLE IF EXISTS #FinalResult;

    SELECT
        ROW_NUMBER() OVER (ORDER BY [RequestDate] DESC) AS RowNo,
        [RequestDate] AS ReqDate,
        [Expire Date] AS ExpiryDate,
        [SKU] AS Pro_Name,
        [Batch No] AS Batch_No,
        [From] AS Serease_From,
        [To] AS Serease_To,
        [Date Of Mfg] AS mfg_date,
        [Total Use ] AS TotalUse,
        [Actual Spool Qty] AS ActualSpool,
        [Bal Qty] AS BalanceQty,
        [Diff QR V Prd] AS DiffQRVPrd,
        [Remarks],
        [Assigned By] AS AssignedBy,
        'PFL' AS Source
    INTO #FinalResult
    FROM PFL_Batchlist
    WHERE 
        (
            -- If 'ALL' is passed, don't apply date bounds
            @Win = 'ALL'
            OR
            -- If BatchNo is provided
            (@BatchNo IS NOT NULL AND [Batch No] = @BatchNo)
            OR
            -- When date range is specified
            (
                @BatchNo IS NULL
                AND (@fromDateDT IS NULL OR [RequestDate] >= @fromDateDT)
                AND (@toDateDT   IS NULL OR [RequestDate] <  @toDateDT)
            )
        )
        AND
        (
            @SearchText IS NULL
            OR
            (
                CAST([RequestDate] AS NVARCHAR(50))     LIKE '%' + @SearchText + '%'
                OR CAST([Expire Date] AS NVARCHAR(50))  LIKE '%' + @SearchText + '%'
                OR [SKU]                                LIKE '%' + @SearchText + '%'
                OR [Batch No]                           LIKE '%' + @SearchText + '%'
                OR [From]                               LIKE '%' + @SearchText + '%'
                OR [To]                                 LIKE '%' + @SearchText + '%'
                OR CAST([Date Of Mfg] AS NVARCHAR(50))  LIKE '%' + @SearchText + '%'
                OR CAST([Total Use ] AS NVARCHAR(50))   LIKE '%' + @SearchText + '%'
                OR CAST([Actual Spool Qty] AS NVARCHAR(50)) LIKE '%' + @SearchText + '%'
                OR CAST([Bal Qty] AS NVARCHAR(50))      LIKE '%' + @SearchText + '%'
                OR CAST([Diff QR V Prd] AS NVARCHAR(50))LIKE '%' + @SearchText + '%'
                OR [Remarks]                            LIKE '%' + @SearchText + '%'
            )
        );

    -------------------------------------------------
    -- Export mode
    -------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #FinalResult
        ORDER BY ReqDate DESC;

        RETURN;
    END

    -------------------------------------------------
    -- Pagination mode
    -------------------------------------------------
    DECLARE @TotalRecords INT = (SELECT COUNT(*) FROM #FinalResult);
    DECLARE @TotalPages INT = CASE 
                                WHEN @TotalRecords = 0 THEN 0 
                                ELSE CEILING(1.0 * @TotalRecords / @Limit) 
                              END;

    SELECT *
    FROM #FinalResult
    ORDER BY ReqDate DESC
    OFFSET @Offset ROWS
    FETCH NEXT @Limit ROWS ONLY;

    -------------------------------------------------
    -- Pagination meta
    -------------------------------------------------
    SELECT
        @TotalRecords AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        @TotalPages AS TotalPages;

END
GO

/****** Object:  StoredProcedure [dbo].[usp_GetBatchSummaryNew_PFL_Temp] ******/
CREATE OR ALTER PROCEDURE [dbo].[usp_GetBatchSummaryNew_PFL_Temp]    
    @fromdate DATETIME = NULL,
    @todate DATETIME = NULL,
    @Window NVARCHAR(20) = NULL,
    @BatchNo NVARCHAR(100) = NULL,
    @SearchText NVARCHAR(200) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
AS    
BEGIN    
    SET NOCOUNT ON;

    -------------------------------------------------
    -- Sanitize inputs
    -------------------------------------------------
    IF LTRIM(RTRIM(@SearchText)) = '' SET @SearchText = NULL;
    IF LTRIM(RTRIM(@BatchNo)) = '' SET @BatchNo = NULL;

    -------------------------------------------------
    -- Pagination defaults
    -------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -------------------------------------------------
    -- Date window calculation
    -------------------------------------------------
    DECLARE @fromDateDT DATETIME = NULL;
    DECLARE @toDateDT   DATETIME = NULL;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@Window, ''));

    -- Explicit dates have highest priority
    IF @fromdate IS NOT NULL OR @todate IS NOT NULL
    BEGIN
        SET @fromDateDT = ISNULL(@fromdate, '19000101');

        IF @todate IS NOT NULL
            SET @toDateDT = DATEADD(DAY, 1, @todate);   -- inclusive end date
        ELSE
            SET @toDateDT = '99991231';
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @fromDateDT = @Today;
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'YESTERDAY'
        BEGIN
            SET @fromDateDT = DATEADD(DAY, -1, @Today);
            SET @toDateDT   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            DECLARE @MondayThisWeek DATE =
                DATEADD(DAY, -((DATEPART(WEEKDAY,@Today) + @@DATEFIRST - 2) % 7), @Today);

            SET @fromDateDT = @MondayThisWeek;
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'LASTWEEK'
        BEGIN
            DECLARE @MondayThisWeek2 DATE =
                DATEADD(DAY, -((DATEPART(WEEKDAY,@Today) + @@DATEFIRST - 2) % 7), @Today);

            SET @fromDateDT = DATEADD(DAY, -7, @MondayThisWeek2);
            SET @toDateDT   = @MondayThisWeek2;
        END
        ELSE IF @Win = 'LASTMONTH'
        BEGIN
            DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @fromDateDT = DATEADD(MONTH, -1, @ThisMonthStart);
            SET @toDateDT   = @ThisMonthStart;
        END
        ELSE IF @Win = 'QUARTER'
        BEGIN
            SET @fromDateDT = DATEADD(DAY, -90, @Today);
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'ALL'
        BEGIN
            -- Do not restrict dates for ALL
            SET @fromDateDT = NULL;
            SET @toDateDT   = NULL;
        END
        ELSE
        BEGIN
            -- Default = current month
            DECLARE @MonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @fromDateDT = @MonthStart;
            SET @toDateDT   = DATEADD(DAY, 1, @Today);
        END
    END

    -------------------------------------------------
    -- Build result into temp table
    -------------------------------------------------
    DROP TABLE IF EXISTS #FinalResult;

    SELECT
        BatchListId,
        [RequestDate] AS ReqDate,
        [Expire Date] AS ExpiryDate,
        [SKU] AS Pro_Name,
        [Batch No] AS Batch_No,
        [From] AS Serease_From,
        [To] AS Serease_To,
        [Date Of Mfg] AS mfg_date,
        [Total Use ] AS TotalUse,
        [Actual Spool Qty] AS ActualSpool,
        [Bal Qty] AS BalanceQty,
        [Diff QR V Prd] AS DiffQRVPrd,
        [Remarks],
        [RequestStatus],
        [AssignedBy] AS AssignedBy,
        'PFL' AS Source,
        AssignRequestDate
    INTO #FinalResult
    FROM PFL_Batchlist_Temp
    WHERE 
        (
            -- If 'ALL' is passed, don't apply date bounds
            @Win = 'ALL'
            OR
            -- If BatchNo is provided
            (@BatchNo IS NOT NULL AND [Batch No] = @BatchNo)
            OR
            -- When date range is specified
            (
                @BatchNo IS NULL
                AND (@fromDateDT IS NULL OR [RequestDate] >= @fromDateDT)
                AND (@toDateDT   IS NULL OR [RequestDate] <  @toDateDT)
            )
        )
        AND
        (
            @SearchText IS NULL
            OR
            (
                CAST(BatchListId AS NVARCHAR(50))        LIKE '%' + @SearchText + '%'
                OR CAST([RequestDate] AS NVARCHAR(50))  LIKE '%' + @SearchText + '%'
                OR CAST([Expire Date] AS NVARCHAR(50))  LIKE '%' + @SearchText + '%'
                OR [SKU]                                LIKE '%' + @SearchText + '%'
                OR [Batch No]                           LIKE '%' + @SearchText + '%'
                OR [From]                               LIKE '%' + @SearchText + '%'
                OR [To]                                 LIKE '%' + @SearchText + '%'
                OR CAST([Date Of Mfg] AS NVARCHAR(50))  LIKE '%' + @SearchText + '%'
                OR CAST([Total Use ] AS NVARCHAR(50))   LIKE '%' + @SearchText + '%'
                OR CAST([Actual Spool Qty] AS NVARCHAR(50)) LIKE '%' + @SearchText + '%'
                OR CAST([Bal Qty] AS NVARCHAR(50))      LIKE '%' + @SearchText + '%'
                OR CAST([Diff QR V Prd] AS NVARCHAR(50))LIKE '%' + @SearchText + '%'
                OR [Remarks]                            LIKE '%' + @SearchText + '%'
                OR [RequestStatus]                      LIKE '%' + @SearchText + '%'
            )
        );

    -------------------------------------------------
    -- Export mode
    -------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #FinalResult
        ORDER BY ReqDate DESC;

        RETURN;
    END

    -------------------------------------------------
    -- Pagination mode
    -------------------------------------------------
    DECLARE @TotalRecords INT = (SELECT COUNT(*) FROM #FinalResult);
    DECLARE @TotalPages INT = CASE 
                                WHEN @TotalRecords = 0 THEN 0 
                                ELSE CEILING(1.0 * @TotalRecords / @Limit) 
                              END;

    SELECT *
    FROM #FinalResult
    ORDER BY ReqDate DESC
    OFFSET @Offset ROWS
    FETCH NEXT @Limit ROWS ONLY;

    -------------------------------------------------
    -- Pagination meta
    -------------------------------------------------
    SELECT
        @TotalRecords AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        @TotalPages AS TotalPages;

END
GO

-------------------------------------------------
-- Data Fix: Swap Day & Month for records where 11-09-2026 was parsed as 2026-11-09
-------------------------------------------------
-- Fix PFL_Batchlist
UPDATE PFL_Batchlist
SET [RequestDate] = DATEADD(
    day, 
    DATEDIFF(day, CAST([RequestDate] AS DATE), DATEFROMPARTS(YEAR([RequestDate]), DAY([RequestDate]), MONTH([RequestDate]))),
    [RequestDate]
)
WHERE [RequestDate] >= DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
  AND DAY([RequestDate]) <= 12;

-- Fix PFL_Batchlist_Temp (if applicable)
UPDATE PFL_Batchlist_Temp
SET [RequestDate] = DATEADD(
    day, 
    DATEDIFF(day, CAST([RequestDate] AS DATE), DATEFROMPARTS(YEAR([RequestDate]), DAY([RequestDate]), MONTH([RequestDate]))),
    [RequestDate]
)
WHERE [RequestDate] >= DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
  AND DAY([RequestDate]) <= 12;
GO

