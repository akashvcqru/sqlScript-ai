SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Description: Get product-wise summary report for a specific company
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetProductWiseSummaryReport_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset NVARCHAR(20) = 'week',
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ServiceID NVARCHAR(50) = NULL,
    @IsExport BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsExport = ISNULL(@IsExport, 0);

    DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
    SET @finalToDate = GETDATE()

    IF @datePreset = 'all'
    BEGIN
        SET @finalFromDate = NULL
        SET @finalToDate = NULL
    END
    ELSE IF @datePreset = 'custom'
    BEGIN
        SET @finalFromDate = @FromDate
        SET @finalToDate = @ToDate
    END
    ELSE
    BEGIN
        IF @datePreset IS NULL OR @datePreset = '' SET @datePreset = 'week'
        
        DECLARE @today DATE = CAST(GETDATE() AS DATE)

        IF @datePreset = 'today'
        BEGIN
            SET @finalFromDate = @today
            SET @finalToDate = GETDATE()
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
            SET @finalFromDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
            SET @finalToDate = DATEADD(SECOND, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME))
        END
        ELSE IF @datePreset = 'quarter'
        BEGIN
            SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0)
            SET @finalToDate = GETDATE()
        END
        ELSE
        BEGIN
            -- Default to week
            SET @finalFromDate = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
            SET @finalToDate = GETDATE()
        END
    END;

    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;

    SELECT a.* 
    INTO #tempM_Code 
    FROM M_Code a 
    INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
    WHERE b.Comp_ID = @Comp_ID;

    IF OBJECT_ID('tempdb..#tempM_ServiceSubscription') IS NOT NULL DROP TABLE #tempM_ServiceSubscription;

    SELECT * 
    INTO #tempM_ServiceSubscription 
    FROM M_ServiceSubscription 
    WHERE Comp_ID = @Comp_ID;

    -- CTE to get counts per state per product and rank them to find the top state
    WITH StateCounts AS (
        SELECT 
            pr.Pro_ID,
            pe.State,
            COUNT(*) AS ScanCount,
            ROW_NUMBER() OVER (PARTITION BY pr.Pro_ID ORDER BY COUNT(*) DESC) AS StateRank
        FROM Pro_Enq pe
        INNER JOIN #tempM_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
        INNER JOIN Pro_Reg pr ON pr.Pro_ID = mc.Pro_ID
        INNER JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc.Pro_ID 
            --AND CONCAT(FORMAT(mc.Series_Order, '000#'), FORMAT(mc.Series_Serial, '000#')) 
            --    BETWEEN CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#')) 
            --        AND CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
        WHERE pe.Comp_ID = @Comp_ID AND pe.IsActive = 1
          AND (@ServiceID IS NULL OR sd.Service_ID = @ServiceID)
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
        COUNT(DISTINCT CAST(pe.Received_Code1 AS VARCHAR(50)) + '-' + CAST(pe.Received_Code2 AS VARCHAR(50))) AS UniqueUIDsScanned,
        SUM(CASE WHEN pe.Is_Success = 1 THEN 1 ELSE 0 END) AS Genuine,
        SUM(CASE WHEN pe.Is_Success = 0 THEN 1 ELSE 0 END) AS Duplicate,
        COUNT(pe.Received_Code1) AS TotalScans,
        MAX(pe.Enq_Date) AS LastScan,
        ISNULL(ts.State, 'N/A') AS TopState,
        ISNULL(ts.ScanCount, 0) AS StateScanCount,
        SUM(CASE WHEN pe.Enq_Date >= DATEADD(day, -7, GETDATE()) THEN 1 ELSE 0 END) AS Last7DaysScans,
        -- New Columns
        CAST(ISNULL(SUM(CASE WHEN pe.Is_Success = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(pe.Received_Code1), 0), 0) AS DECIMAL(18,2)) AS GenuineRate,
        CAST(ISNULL((COUNT(pe.Received_Code1) - COUNT(DISTINCT CAST(pe.Received_Code1 AS VARCHAR(50)) + '-' + CAST(pe.Received_Code2 AS VARCHAR(50)))) * 100.0 / NULLIF(COUNT(pe.Received_Code1), 0), 0) AS DECIMAL(18,2)) AS RepeatScanRate,
        CAST(ISNULL(COUNT(pe.Received_Code1) * 1.0 / NULLIF(COUNT(DISTINCT CAST(pe.Received_Code1 AS VARCHAR(50)) + '-' + CAST(pe.Received_Code2 AS VARCHAR(50))), 0), 0) AS DECIMAL(18,2)) AS AvgScansPerUID,
        COUNT(*) OVER() AS TotalRecords
    FROM Pro_Reg pr
    LEFT JOIN #tempM_Code mc ON mc.Pro_ID = pr.Pro_ID
    LEFT JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc.Pro_ID 
        --AND CONCAT(FORMAT(mc.Series_Order, '000#'), FORMAT(mc.Series_Serial, '000#')) 
        --    BETWEEN CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#')) 
        --        AND CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
    LEFT JOIN Pro_Enq pe ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
          AND pe.Comp_ID = @Comp_ID
          AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
          AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
    LEFT JOIN TopStates ts ON ts.Pro_ID = pr.Pro_ID
    WHERE pr.Comp_ID = @Comp_ID
      AND (@ServiceID IS NULL OR sd.Service_ID = @ServiceID)
    GROUP BY pr.Pro_ID, pr.Pro_Name, pr.Pro_Entry_Date, ts.State, ts.ScanCount
    ORDER BY pr.Pro_Name
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END

GO
