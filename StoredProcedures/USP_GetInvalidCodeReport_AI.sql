USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetInvalidCodeReport_AI]    Script Date: 4/28/2026 4:48:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[USP_GetInvalidCodeReport_AI]
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
    END

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

    SELECT 
        ROW_NUMBER() OVER (ORDER BY pe.Enq_Date DESC) AS SNo,
        pe.MobileNo AS MobileNo,
        pe.Received_Code1 AS ReceivedCode1,
        pe.Received_Code2 AS ReceivedCode2,
        pe.Enq_Date AS ScanTimestamp,
        ISNULL(pe.Dial_Mode, 'Web') AS Channel,
        COUNT(*) OVER() AS TotalRecords
    FROM Pro_Enq pe
    LEFT JOIN #tempM_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
    LEFT JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc.Pro_ID 
        --AND CONCAT(FORMAT(mc.Series_Order, '000#'), FORMAT(mc.Series_Serial, '000#')) 
        --    BETWEEN CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#')) 
        --        AND CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
    WHERE pe.Comp_ID = @Comp_ID
      AND (@ServiceID IS NULL OR sd.Service_ID = @ServiceID)
      AND pe.Is_Success = 0 -- Logic: Is_Success = 0 typically denotes invalid/failed scans
      AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
    ORDER BY pe.Enq_Date DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
