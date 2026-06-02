USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetProductWiseSummaryReport_AI]    Script Date: 4/28/2026 4:32:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Modified:    2026-04-29
-- Description: Highly optimized Product-wise Summary Report.
-- =============================================
ALTER   PROCEDURE [dbo].[USP_GetProductWiseSummaryReport_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset NVARCHAR(20) = 'ALL',
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @IsExport BIT = 0,
    @Search NVARCHAR(100) = NULL,
    @StateFilter NVARCHAR(100) = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,
    @DialModeFilter NVARCHAR(50) = NULL,
    @ProductID NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @PageNumber IS NULL OR @PageNumber <= 0 SET @PageNumber = 1;
    IF @PageSize IS NULL OR @PageSize <= 0 SET @PageSize = 10;
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' SET @CodeStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' SET @DialModeFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@ProductID, ''))) = '' SET @ProductID = NULL;

    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01')
    FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1;

    -------------------------------------------------
    -- 2. Construct Date Range
    -------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset,''))));
    
    IF @Win = '' OR @Win = 'NULL' SET @Win = 'ALL';

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
        SET DATEFIRST 1; -- Monday
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
    ELSE IF @Win = 'YEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTYEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(@Today), 1, 1);
    END
    ELSE IF @Win = 'ALL'
    BEGIN
        SET @StartDate = '1900-01-01';
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'CUSTOM'
    BEGIN
        SET @StartDate = ISNULL(CAST(@FromDate AS DATE), '1900-01-01');
        SET @EndDate   = DATEADD(DAY, 1, ISNULL(CAST(@ToDate AS DATE), @Today));
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END

    ------------------------------------------------------
    -- Step 1: Pre-filter M_Code (Deduplicated per code pair)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    
    IF @Comp_ID <> 'Comp-1693'
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_ID 
              AND a.Use_Count > 0
        )
        SELECT Code1, Code2, Pro_ID, Use_Count
        INTO #tempM_Code 
        FROM DistinctCodes
        WHERE rn = 1;

        CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);
        CREATE INDEX IX_tempM_Code_ProID ON #tempM_Code(Pro_ID);
    END

    ------------------------------------------------------
    -- Step 2: Pre-filter Pro_Enq (Definitive list of scans)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;

    CREATE TABLE #tempPro_Enq (
        Received_Code1 VARCHAR(100),
        Received_Code2 VARCHAR(100),
        MobileNo VARCHAR(50),
        Is_Success INT,
        Enq_Date DATETIME,
        State NVARCHAR(100),
        Pro_ID VARCHAR(50),
        Use_Count INT
    );

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        INSERT INTO #tempPro_Enq (Received_Code1, Received_Code2, MobileNo, Is_Success, Enq_Date, State, Pro_ID, Use_Count)
        SELECT 
            pe.UniqueCode AS Received_Code1, 
            '' AS Received_Code2, 
            pe.MobileNo, 
            CASE 
                WHEN pe.Status = 'Authenticate' THEN 1 
                WHEN pe.Status = 'Re-Authenticate' THEN 2 
                ELSE 0 
            END AS Is_Success, 
            pe.Enq_Date, 
            pe.State,
            COALESCE(pr.Pro_ID, pe.Pro_ID) AS Pro_ID,
            pe.Use_Count
        FROM pfl_codecheckData pe WITH (NOLOCK)
        LEFT JOIN Pro_Reg pr WITH (NOLOCK) ON LTRIM(RTRIM(pr.Pro_Name)) = LTRIM(RTRIM(pe.Pro_Name)) AND pr.Comp_ID = @Comp_ID
        WHERE pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND pe.Pro_Name IS NOT NULL
          AND pe.Pro_Name <> 'Not Assigned'
          AND (@CompanyStartDate IS NULL OR pe.Enq_Date >= @CompanyStartDate)
          AND (@StateFilter IS NULL OR pe.State = @StateFilter)
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
          AND (
              @CodeStatusFilter IS NULL OR
              (@CodeStatusFilter = 'Verified' AND pe.Status = 'Authenticate') OR
              (@CodeStatusFilter = 'Already Scanned' AND pe.Status = 'Re-Authenticate') OR
              (@CodeStatusFilter = 'Invalid' AND pe.Status = 'Failed')
          );
    END
    ELSE
    BEGIN
        INSERT INTO #tempPro_Enq (Received_Code1, Received_Code2, MobileNo, Is_Success, Enq_Date, State, Pro_ID, Use_Count)
        SELECT 
            pe.Received_Code1, 
            pe.Received_Code2, 
            pe.MobileNo, 
            pe.Is_Success, 
            pe.Enq_Date, 
            pe.State,
            mc.Pro_ID,
            mc.Use_Count
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN #tempM_Code mc ON CAST(mc.Code1 AS VARCHAR(50)) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
              AND CAST(mc.Code2 AS VARCHAR(50)) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
        WHERE pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND (@CompanyStartDate IS NULL OR pe.Enq_Date >= @CompanyStartDate)
          AND (@StateFilter IS NULL OR pe.State = @StateFilter)
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
          AND (
              @CodeStatusFilter IS NULL OR
              (@CodeStatusFilter = 'Verified' AND pe.Is_Success = 1) OR
              (@CodeStatusFilter = 'Already Scanned' AND pe.Is_Success = 2) OR
              (@CodeStatusFilter = 'Invalid' AND pe.Is_Success NOT IN (1, 2))
          );
    END;

    CREATE INDEX IX_tempPro_Enq_ProID ON #tempPro_Enq(Pro_ID);

    ------------------------------------------------------
    -- Step 3: Top State per product (From temp table)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#TopStates') IS NOT NULL DROP TABLE #TopStates;
    
    ;WITH StateCounts AS (
        SELECT 
            Pro_ID, 
            State, 
            COUNT(*) AS ScanCount,
            ROW_NUMBER() OVER (PARTITION BY Pro_ID ORDER BY COUNT(*) DESC) AS StateRank
        FROM #tempPro_Enq
        GROUP BY Pro_ID, State
    ),
    TopStatesCTE AS (
        SELECT Pro_ID, State, ScanCount
        FROM StateCounts
        WHERE StateRank = 1
    )
    SELECT Pro_ID, State, ScanCount
    INTO #TopStates
    FROM TopStatesCTE;

    CREATE INDEX IX_TopStates_ProID ON #TopStates(Pro_ID);

    ------------------------------------------------------
    -- Step 4: Aggregate Metrics per product
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#ProductMetrics') IS NOT NULL DROP TABLE #ProductMetrics;
    
    CREATE TABLE #ProductMetrics (
        Pro_ID VARCHAR(50),
        UniqueConsumers INT,
        UniqueUIDsScanned INT,
        Genuine INT,
        Duplicate INT,
        TotalScans INT,
        LastScan DATETIME,
        Last7DaysScans INT
    );

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        INSERT INTO #ProductMetrics (Pro_ID, UniqueConsumers, UniqueUIDsScanned, Genuine, Duplicate, TotalScans, LastScan, Last7DaysScans)
        SELECT 
            Pro_ID,
            COUNT(DISTINCT MobileNo) AS UniqueConsumers,
            COUNT(DISTINCT CAST(Received_Code1 AS VARCHAR(50))+'-'+CAST(Received_Code2 AS VARCHAR(50))) AS UniqueUIDsScanned,
            SUM(CASE WHEN Is_Success IN (1, 2) THEN 1 ELSE 0 END) AS Genuine,
            SUM(CASE WHEN Is_Success = 0 THEN 1 ELSE 0 END) AS Duplicate,
            COUNT(*) AS TotalScans,
            MAX(Enq_Date) AS LastScan,
            SUM(CASE WHEN Enq_Date >= DATEADD(day,-7,GETDATE()) THEN 1 ELSE 0 END) AS Last7DaysScans
        FROM #tempPro_Enq
        GROUP BY Pro_ID;
    END
    ELSE
    BEGIN
        INSERT INTO #ProductMetrics (Pro_ID, UniqueConsumers, UniqueUIDsScanned, Genuine, Duplicate, TotalScans, LastScan, Last7DaysScans)
        SELECT 
            Pro_ID,
            COUNT(DISTINCT MobileNo) AS UniqueConsumers,
            COUNT(DISTINCT CAST(Received_Code1 AS VARCHAR(50))+'-'+CAST(Received_Code2 AS VARCHAR(50))) AS UniqueUIDsScanned,
            SUM(CASE WHEN Use_Count = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS Genuine,
            SUM(CASE WHEN Is_Success<>1 THEN 1 ELSE 0 END) AS Duplicate,
            SUM(CASE WHEN Use_Count = 1 AND Is_Success = 1 THEN 1 ELSE 0 END)
            + SUM(CASE WHEN Is_Success<>1 THEN 1 ELSE 0 END) AS TotalScans,
            MAX(Enq_Date) AS LastScan,
            SUM(CASE WHEN Enq_Date >= DATEADD(day,-7,GETDATE()) THEN 1 ELSE 0 END) AS Last7DaysScans
        FROM #tempPro_Enq
        GROUP BY Pro_ID;
    END;

    CREATE INDEX IX_ProductMetrics_ProID ON #ProductMetrics(Pro_ID);

    ------------------------------------------------------
    -- Step 5: Final Result Projection
    ------------------------------------------------------
    SELECT 
        ROW_NUMBER() OVER (ORDER BY pr.Pro_Name) AS SNo,
        pr.Pro_Name AS Product, 
        pr.Pro_ID AS ProductID_SKU, 
        pr.Pro_Entry_Date AS ProductEntryDate,
        ISNULL(pm.UniqueConsumers, 0) AS UniqueConsumers,
        ISNULL(pm.UniqueUIDsScanned, 0) AS UniqueUIDsScanned,
        ISNULL(pm.Genuine, 0) AS Genuine,
        ISNULL(pm.Duplicate, 0) AS Duplicate,
        ISNULL(pm.TotalScans, 0) AS TotalScans,
        pm.LastScan,
        ISNULL(ts.State,'N/A') AS TopState, 
        ISNULL(ts.ScanCount,0) AS StateScanCount,
        ISNULL(pm.Last7DaysScans, 0) AS Last7DaysScans,
        CAST(ISNULL(pm.Genuine*100.0/NULLIF(pm.TotalScans,0),0) AS DECIMAL(18,2)) AS GenuineRate,
        CAST(ISNULL(pm.Duplicate*100.0/NULLIF(pm.TotalScans,0),0) AS DECIMAL(18,2)) AS RepeatScanRate,
        CAST(ISNULL(pm.TotalScans*1.0/NULLIF(pm.UniqueUIDsScanned,0),0) AS DECIMAL(18,2)) AS AvgScansPerUID,
        COUNT(*) OVER() AS TotalRecords
    FROM Pro_Reg pr
    INNER JOIN #ProductMetrics pm ON pm.Pro_ID = pr.Pro_ID
    LEFT JOIN #TopStates ts ON ts.Pro_ID = pr.Pro_ID
    WHERE pr.Comp_ID = @Comp_ID
      AND (@ProductID IS NULL OR pr.Pro_ID = @ProductID)
      AND (@Search IS NULL OR pr.Pro_Name LIKE '%' + @Search + '%' OR pr.Pro_ID LIKE '%' + @Search + '%')
    ORDER BY pr.Pro_Name
    OFFSET (@PageNumber-1)*@PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport=1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END

