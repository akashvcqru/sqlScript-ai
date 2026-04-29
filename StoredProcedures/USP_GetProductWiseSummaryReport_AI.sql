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
CREATE OR ALTER PROCEDURE [dbo].[USP_GetProductWiseSummaryReport_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset NVARCHAR(20) = 'week',
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ServiceID NVARCHAR(50) = NULL,
    @IsExport BIT = 0,
    @Search NVARCHAR(100) = NULL,
    @StateFilter NVARCHAR(100) = NULL,
    @KYCStatusFilter NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @PageNumber IS NULL OR @PageNumber <= 0 SET @PageNumber = 1;
    IF @PageSize IS NULL OR @PageSize <= 0 SET @PageSize = 10;
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' SET @StateFilter = NULL;

    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01')
    FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1;

    DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
    IF (@datePreset IS NULL OR LTRIM(RTRIM(@datePreset)) = '' OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null')
        SET @datePreset = 'week'
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @today DATE = CAST(GETDATE() AS DATE); SET DATEFIRST 1;
    IF @datePreset = 'ALL' BEGIN SET @finalFromDate = @CompanyStartDate; SET @finalToDate = @today END
    ELSE IF @datePreset = 'CUSTOM' BEGIN SET @finalFromDate = @FromDate; SET @finalToDate = @ToDate END
    ELSE BEGIN
        IF @datePreset = 'TODAY' BEGIN SET @finalFromDate = @today; SET @finalToDate = @today END
        ELSE IF @datePreset = 'YESTERDAY' OR @datePreset = 'LASTDAY' BEGIN SET @finalFromDate = DATEADD(DAY, -1, @today); SET @finalToDate = DATEADD(DAY, -1, @today) END
        ELSE IF @datePreset = 'WEEK' BEGIN SET @finalFromDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalToDate = @today END
        ELSE IF @datePreset = 'LASTWEEK' BEGIN DECLARE @thisMonday DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalFromDate = DATEADD(DAY, -7, @thisMonday); SET @finalToDate = DATEADD(DAY, -1, @thisMonday) END
        ELSE IF @datePreset = 'MONTH' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1); SET @finalToDate = @today END
        ELSE IF @datePreset = 'LASTMONTH' BEGIN SET @finalFromDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)); SET @finalToDate = DATEADD(DAY, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) END
        ELSE IF @datePreset = 'QUARTER' BEGIN SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0); SET @finalToDate = @today END
        ELSE IF @datePreset = 'YEAR' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1); SET @finalToDate = @today END
        ELSE IF @datePreset = 'LASTYEAR' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1); SET @finalToDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31) END
        ELSE BEGIN SET @finalFromDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalToDate = @today END
    END;

    ------------------------------------------------------
    -- Step 1: Pre-filter M_Code (Optimized columns)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    SELECT 
        a.Code1, 
        a.Code2, 
        a.Pro_ID
    INTO #tempM_Code 
    FROM M_Code a 
    INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
    WHERE b.Comp_ID = @Comp_ID AND a.Print_Date >= @CompanyStartDate;

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);
    CREATE INDEX IX_tempM_Code_ProID ON #tempM_Code(Pro_ID);

    ------------------------------------------------------
    -- Step 2: Pre-filter Pro_Enq (Optimized columns)
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
    INNER JOIN #tempM_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
    WHERE pe.Comp_ID = @Comp_ID
      AND pe.Enq_Date >= @CompanyStartDate
      AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
      AND (@StateFilter IS NULL OR pe.State = @StateFilter);

    CREATE INDEX IX_tempPro_Enq_ProID ON #tempPro_Enq(Pro_ID);

    ------------------------------------------------------
    -- Step 3: Top State per product
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#TopStates') IS NOT NULL DROP TABLE #TopStates;
    SELECT Pro_ID, State, ScanCount
    INTO #TopStates
    FROM (
        SELECT 
            Pro_ID, 
            State, 
            COUNT(*) AS ScanCount,
            ROW_NUMBER() OVER (PARTITION BY Pro_ID ORDER BY COUNT(*) DESC) AS StateRank
        FROM #tempPro_Enq
        GROUP BY Pro_ID, State
    ) t WHERE StateRank = 1;

    CREATE INDEX IX_TopStates_ProID ON #TopStates(Pro_ID);

    ------------------------------------------------------
    -- Main Query
    ------------------------------------------------------
    SELECT 
        ROW_NUMBER() OVER (ORDER BY pr.Pro_Name) AS SNo,
        pr.Pro_Name AS Product, 
        pr.Pro_ID AS ProductID_SKU, 
        pr.Pro_Entry_Date AS ProductEntryDate,
        COUNT(DISTINCT pe.MobileNo) AS UniqueConsumers,
        COUNT(DISTINCT CAST(pe.Received_Code1 AS VARCHAR(50))+'-'+CAST(pe.Received_Code2 AS VARCHAR(50))) AS UniqueUIDsScanned,
        SUM(CASE WHEN pe.Is_Success=1 THEN 1 ELSE 0 END) AS Genuine,
        SUM(CASE WHEN pe.Is_Success=0 THEN 1 ELSE 0 END) AS Duplicate,
        COUNT(pe.Received_Code1) AS TotalScans,
        MAX(pe.Enq_Date) AS LastScan,
        ISNULL(ts.State,'N/A') AS TopState, 
        ISNULL(ts.ScanCount,0) AS StateScanCount,
        SUM(CASE WHEN pe.Enq_Date >= DATEADD(day,-7,GETDATE()) THEN 1 ELSE 0 END) AS Last7DaysScans,
        CAST(ISNULL(SUM(CASE WHEN pe.Is_Success=1 THEN 1 ELSE 0 END)*100.0/NULLIF(COUNT(pe.Received_Code1),0),0) AS DECIMAL(18,2)) AS GenuineRate,
        CAST(ISNULL((COUNT(pe.Received_Code1)-COUNT(DISTINCT CAST(pe.Received_Code1 AS VARCHAR(50))+'-'+CAST(pe.Received_Code2 AS VARCHAR(50))))*100.0/NULLIF(COUNT(pe.Received_Code1),0),0) AS DECIMAL(18,2)) AS RepeatScanRate,
        CAST(ISNULL(COUNT(pe.Received_Code1)*1.0/NULLIF(COUNT(DISTINCT CAST(pe.Received_Code1 AS VARCHAR(50))+'-'+CAST(pe.Received_Code2 AS VARCHAR(50))),0),0) AS DECIMAL(18,2)) AS AvgScansPerUID,
        COUNT(*) OVER() AS TotalRecords
    FROM Pro_Reg pr
    LEFT JOIN #tempPro_Enq pe ON pe.Pro_ID = pr.Pro_ID
    LEFT JOIN #TopStates ts ON ts.Pro_ID = pr.Pro_ID
    WHERE pr.Comp_ID = @Comp_ID
      AND (@Search IS NULL OR pr.Pro_Name LIKE '%'+@Search+'%' OR pr.Pro_ID LIKE '%'+@Search+'%')
    GROUP BY pr.Pro_ID, pr.Pro_Name, pr.Pro_Entry_Date, ts.State, ts.ScanCount
    ORDER BY pr.Pro_Name
    OFFSET (@PageNumber-1)*@PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport=1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
GO
