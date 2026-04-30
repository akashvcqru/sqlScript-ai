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
    @datePreset NVARCHAR(20) = 'week',
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ServiceID NVARCHAR(50) = NULL,
    @IsExport BIT = 0,
    @Search NVARCHAR(100) = NULL,
    @StateFilter NVARCHAR(100) = NULL,
    @KYCStatusFilter NVARCHAR(50) = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,
    @DialModeFilter NVARCHAR(50) = NULL
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

    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01')
    FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1;

    DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
    IF (@datePreset IS NULL OR LTRIM(RTRIM(@datePreset)) = '' OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null')
        SET @datePreset = 'week'
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

        IF @datePreset = 'today'
        BEGIN
            SET @finalFromDate = @today
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastday'
        BEGIN
            SET @finalFromDate = DATEADD(DAY, -1, @today)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(@today AS DATETIME))
        END
        ELSE IF @datePreset = 'week'
        BEGIN
            -- Start of current week (Monday)
            SET @finalFromDate = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastweek'
        BEGIN
            -- Start of last week (Monday)
            DECLARE @thisMonday DATE = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
            SET @finalFromDate = DATEADD(DAY, -7, @thisMonday)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(@thisMonday AS DATETIME))
        END
        ELSE IF @datePreset = 'month'
        BEGIN
            SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastmonth'
        BEGIN
            DECLARE @firstOfThisMonth DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
            SET @finalFromDate = DATEADD(MONTH, -1, @firstOfThisMonth)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(@firstOfThisMonth AS DATETIME))
        END
        ELSE IF @datePreset = 'quarter'
        BEGIN
            SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'year'
        BEGIN
            SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastyear'
        BEGIN
            SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME))
        END
        ELSE
        BEGIN
            -- Default to week
            SET @finalFromDate = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
            SET @finalToDate = GETDATE()
        END
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
            ROW_NUMBER() OVER (PARTITION BY pr.Pro_ID ORDER BY COUNT(*) DESC) AS StateRank
        FROM Pro_Enq pe
        INNER JOIN #tempM_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
        INNER JOIN Pro_Reg pr ON pr.Pro_ID = mc.Pro_ID
        --INNER JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc.Pro_ID 
            --AND CONCAT(FORMAT(mc.Series_Order, '000#'), FORMAT(mc.Series_Serial, '000#')) 
            --    BETWEEN CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#')) 
            --        AND CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
        WHERE pe.Comp_ID = @Comp_ID AND pe.IsActive = 1
        --  AND (@ServiceID IS NULL OR sd.Service_ID = @ServiceID)
          AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
          AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
        GROUP BY pr.Pro_ID, pe.State
    ),
    TopStates AS (
        SELECT Pro_ID, State, ScanCount
        FROM StateCounts
        WHERE StateRank = 1
    )
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
    LEFT JOIN #tempM_Code mc ON mc.Pro_ID = pr.Pro_ID
    --LEFT JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc.Pro_ID 
        --AND CONCAT(FORMAT(mc.Series_Order, '000#'), FORMAT(mc.Series_Serial, '000#')) 
        --    BETWEEN CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#')) 
        --        AND CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
    LEFT JOIN Pro_Enq pe ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
          AND pe.Comp_ID = @Comp_ID
          AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
          AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
    LEFT JOIN TopStates ts ON ts.Pro_ID = pr.Pro_ID
    WHERE pr.Comp_ID = @Comp_ID
     -- AND (@ServiceID IS NULL OR sd.Service_ID = @ServiceID)
    GROUP BY pr.Pro_ID, pr.Pro_Name, pr.Pro_Entry_Date, ts.State, ts.ScanCount
    ORDER BY pr.Pro_Name
    OFFSET (@PageNumber-1)*@PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport=1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END

