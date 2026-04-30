USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetProductWiseSummaryReport_AI]    Script Date: 4/24/2026 10:49:15 AM ******/
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

    DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
    IF (@datePreset IS NULL OR LTRIM(RTRIM(@datePreset)) = '' OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null' OR @datePreset = 'All')
        SET @datePreset = 'ALL'
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @today DATE = CAST(GETDATE() AS DATE); 
    SET DATEFIRST 1; -- Monday as first day of week

    IF @datePreset = 'ALL' 
    BEGIN 
        SET @finalFromDate = NULL; 
        SET @finalToDate = GETDATE(); 
    END
    ELSE IF @datePreset = 'CUSTOM' 
    BEGIN 
        SET @finalFromDate = @FromDate; 
        SET @finalToDate = @ToDate; 
    END
    ELSE IF @datePreset = 'TODAY' 
    BEGIN 
        SET @finalFromDate = CAST(@today AS DATETIME); 
        SET @finalToDate = GETDATE(); 
    END
    ELSE IF @datePreset = 'YESTERDAY' OR @datePreset = 'LASTDAY' 
    BEGIN 
        SET @finalFromDate = CAST(DATEADD(DAY, -1, @today) AS DATETIME); 
        SET @finalToDate = CAST(DATEADD(SECOND, -1, CAST(@today AS DATETIME)) AS DATETIME); 
    END
    ELSE IF @datePreset = 'WEEK' 
    BEGIN 
        SET @finalFromDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today) AS DATETIME); 
        SET @finalToDate = GETDATE(); 
    END
    ELSE IF @datePreset = 'LASTWEEK' 
    BEGIN 
        DECLARE @lastMonday DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); 
        SET @finalFromDate = CAST(DATEADD(DAY, -7, @lastMonday) AS DATETIME); 
        SET @finalToDate = CAST(DATEADD(SECOND, -1, CAST(@lastMonday AS DATETIME)) AS DATETIME); 
    END
    ELSE IF @datePreset = 'MONTH' 
    BEGIN 
        SET @finalFromDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME); 
        SET @finalToDate = GETDATE(); 
    END
    ELSE IF @datePreset = 'LASTMONTH' 
    BEGIN 
        DECLARE @firstOfThisMonth DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @finalFromDate = CAST(DATEADD(MONTH, -1, @firstOfThisMonth) AS DATETIME); 
        SET @finalToDate = CAST(DATEADD(SECOND, -1, CAST(@firstOfThisMonth AS DATETIME)) AS DATETIME); 
    END
    ELSE IF @datePreset = 'QUARTER' 
    BEGIN 
        SET @finalFromDate = CAST(DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0) AS DATETIME); 
        SET @finalToDate = GETDATE(); 
    END
    ELSE IF @datePreset = 'YEAR' 
    BEGIN 
        SET @finalFromDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME); 
        SET @finalToDate = GETDATE(); 
    END
    ELSE IF @datePreset = 'LASTYEAR' 
    BEGIN 
        SET @finalFromDate = CAST(DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1) AS DATETIME); 
        SET @finalToDate = CAST(DATEADD(SECOND, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME)) AS DATETIME); 
    END
    ELSE 
    BEGIN 
        SET @finalFromDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today) AS DATETIME); 
        SET @finalToDate = GETDATE(); 
    END

    ------------------------------------------------------
    -- Step 1: Pre-filter M_Code (Optimized columns)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    SELECT DISTINCT
        a.Code1, 
        a.Code2, 
        a.Pro_ID
    INTO #tempM_Code 
    FROM M_Code a 
    INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
    WHERE b.Comp_ID = @Comp_ID 
      AND a.Use_Count > 0;

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);
    CREATE INDEX IX_tempM_Code_ProID ON #tempM_Code(Pro_ID);

    ------------------------------------------------------
    -- Step 2: Pre-filter Pro_Enq (Definitive list of scans)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
    SELECT 
        pe.Received_Code1, 
        pe.Received_Code2, 
        pe.MobileNo, 
        pe.Is_Success, 
        pe.Enq_Date, 
        pe.State,
        mc.Pro_ID
    INTO #tempPro_Enq
    FROM Pro_Enq pe
    INNER JOIN #tempM_Code mc ON CAST(mc.Code1 AS VARCHAR(50)) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
          AND CAST(mc.Code2 AS VARCHAR(50)) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
    WHERE (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
      AND (@StateFilter IS NULL OR pe.State = @StateFilter)
      AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          (@CodeStatusFilter = 'Verified' AND pe.Is_Success = 1) OR
          (@CodeStatusFilter = 'Already Scanned' AND pe.Is_Success = 2) OR
          (@CodeStatusFilter = 'Invalid' AND pe.Is_Success NOT IN (1, 2))
      );

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
    SELECT 
        Pro_ID,
        COUNT(DISTINCT MobileNo) AS UniqueConsumers,
        COUNT(DISTINCT CAST(Received_Code1 AS VARCHAR(50))+'-'+CAST(Received_Code2 AS VARCHAR(50))) AS UniqueUIDsScanned,
        SUM(CASE WHEN Is_Success=1 THEN 1 ELSE 0 END) AS Genuine,
        SUM(CASE WHEN Is_Success<>1 THEN 1 ELSE 0 END) AS Duplicate,
        COUNT(*) AS TotalScans,
        MAX(Enq_Date) AS LastScan,
        SUM(CASE WHEN Enq_Date >= DATEADD(day,-7,GETDATE()) THEN 1 ELSE 0 END) AS Last7DaysScans
    INTO #ProductMetrics
    FROM #tempPro_Enq
    GROUP BY Pro_ID;

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
    LEFT JOIN #ProductMetrics pm ON pm.Pro_ID = pr.Pro_ID
    LEFT JOIN #TopStates ts ON ts.Pro_ID = pr.Pro_ID
    WHERE pr.Comp_ID = @Comp_ID
      AND (@ProductID IS NULL OR pr.Pro_ID = @ProductID)
    ORDER BY pr.Pro_Name
    OFFSET (@PageNumber-1)*@PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport=1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END

