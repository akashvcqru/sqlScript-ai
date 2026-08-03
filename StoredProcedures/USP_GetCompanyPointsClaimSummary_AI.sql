ALTER   PROCEDURE [dbo].[USP_GetCompanyPointsClaimSummary_AI]
(
    @DatePreset NVARCHAR(50) = 'ALL',
    @FromDate NVARCHAR(30) = NULL,
    @ToDate NVARCHAR(30) = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------------
    -- Date Range
    -----------------------------------------
    DECLARE @StartDate DATETIME = NULL,
            @EndDate   DATETIME = NULL,
            @Preset    NVARCHAR(50);

    IF @FromDate IS NOT NULL AND LTRIM(RTRIM(@FromDate)) <> '' 
       AND @ToDate IS NOT NULL AND LTRIM(RTRIM(@ToDate)) <> ''
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
    BEGIN
        SET @Preset = UPPER(LTRIM(RTRIM(@DatePreset)));

        IF @Preset = 'TODAY'
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('YESTERDAY', 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF @Preset IN ('WEEK', 'THIS WEEK', 'THISWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTWEEK', 'LAST WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('MONTH', 'THIS MONTH', 'THISMONTH', 'MONTHS')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTMONTH', 'LAST MONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('QUARTER', 'THIS QUARTER', 'THISQUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTQUARTER', 'LAST QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('YEAR', 'THIS YEAR', 'THISYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTYEAR', 'LAST YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF @Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> ''
        BEGIN
            SET @StartDate = CAST(@FromDate AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
        END
        ELSE IF @Preset IN ('ALL', 'NULL')
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    -- Temporary table to capture output of USP_GetNegativeBalancePendingUsers_AI
    CREATE TABLE #UserSummary (
        MobileNo NVARCHAR(50),
        ConsumerName NVARCHAR(150),
        TotalPoints DECIMAL(18,2),
        AssingedPoints DECIMAL(18,2),
        TotalClaimAmount DECIMAL(18,2),
        AvailableBalance DECIMAL(18,2),
        PaidAmount DECIMAL(18,2),
        TDS DECIMAL(18,2),
        LastCodeCheckDate DATETIME,
        LastPaymentDate DATETIME,
        LastFraudClaimDate DATETIME
    );

    -- Temporary table to hold aggregated company summaries
    CREATE TABLE #CompanySummary (
        Comp_ID NVARCHAR(50),
        Comp_Name NVARCHAR(150),
        TotalPoints DECIMAL(18,2),
        AssingedPoints DECIMAL(18,2),
        TotalClaimAmount DECIMAL(18,2),
        AvailableBalance DECIMAL(18,2),
        PaidAmount DECIMAL(18,2),
        TDS DECIMAL(18,2),
        TotalUsers INT
    );

    -- Cursor to iterate through each distinct Comp_ID in TempCodesActivityReport
    DECLARE @CurrentComp_ID NVARCHAR(50);
    DECLARE comp_cursor CURSOR LOCAL FAST_FORWARD FOR 
    SELECT DISTINCT t.Comp_ID 
    FROM dbo.TempCodesActivityReport t
    LEFT JOIN dbo.comp_reg c ON t.Comp_ID = c.Comp_ID
    WHERE t.Comp_ID IS NOT NULL AND t.Comp_ID <> ''
      AND (
          @Search IS NULL
          OR @Search = ''
          OR t.Comp_ID LIKE '%' + @Search + '%'
          OR c.comp_name LIKE '%' + @Search + '%'
      );

    OPEN comp_cursor;
    FETCH NEXT FROM comp_cursor INTO @CurrentComp_ID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        TRUNCATE TABLE #UserSummary;

        -- Execute USP_GetNegativeBalancePendingUsers_AI for this company
        -- We pass IsExport = 1 to skip pagination inside the SP and fetch all user records
        INSERT INTO #UserSummary (MobileNo, ConsumerName, TotalPoints, AssingedPoints, TotalClaimAmount, AvailableBalance, PaidAmount, TDS, LastCodeCheckDate, LastPaymentDate, LastFraudClaimDate)
        EXEC [dbo].[USP_GetNegativeBalancePendingUsers_AI] 
            @Comp_ID = @CurrentComp_ID, 
            @DatePreset = 'ALL', 
            @FromDate = NULL, 
            @ToDate = NULL, 
            @Page = 1, 
            @Limit = 10000000, 
            @Search = NULL, 
            @IsExport = 1;

        -- Check if any negative balance users exist for this company
        IF EXISTS (SELECT 1 FROM #UserSummary)
        BEGIN
            DECLARE @CompName NVARCHAR(150) = NULL;
            SELECT TOP 1 @CompName = comp_name FROM dbo.comp_reg WHERE Comp_ID = @CurrentComp_ID;

            -- Aggregate the user statistics to company level
            INSERT INTO #CompanySummary (Comp_ID, Comp_Name, TotalPoints, AssingedPoints, TotalClaimAmount, AvailableBalance, PaidAmount, TDS, TotalUsers)
            SELECT 
                @CurrentComp_ID,
                ISNULL(@CompName, @CurrentComp_ID),
                SUM(TotalPoints),
                SUM(AssingedPoints),
                SUM(TotalClaimAmount),
                SUM(AvailableBalance),
                SUM(PaidAmount),
                SUM(TDS),
                COUNT(1)
            FROM #UserSummary
            WHERE (@StartDate IS NULL OR LastPaymentDate >= @StartDate)
              AND (@EndDate IS NULL OR LastPaymentDate < @EndDate)
            HAVING COUNT(1) > 0;
        END

        FETCH NEXT FROM comp_cursor INTO @CurrentComp_ID;
    END;

    CLOSE comp_cursor;
    DEALLOCATE comp_cursor;

    -- Apply search filter
    IF OBJECT_ID('tempdb..#FinalSummary') IS NOT NULL
        DROP TABLE #FinalSummary;

    SELECT *
    INTO #FinalSummary
    FROM #CompanySummary
    WHERE
        @Search IS NULL
        OR @Search = ''
        OR Comp_ID LIKE '%' + @Search + '%'
        OR Comp_Name LIKE '%' + @Search + '%';

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #FinalSummary;

    -- Return the output with pagination support
    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #FinalSummary
        ORDER BY Comp_ID;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #FinalSummary
        ORDER BY Comp_ID
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        SELECT
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(@TotalRecords * 1.0 / @Limit) AS TotalPages;
    END

    -- Clean up temp tables
    DROP TABLE IF EXISTS #UserSummary;
    DROP TABLE IF EXISTS #CompanySummary;
    DROP TABLE IF EXISTS #FinalSummary;
END
