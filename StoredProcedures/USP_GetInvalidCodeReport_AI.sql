SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Description: Get invalid code report for a specific company
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetInvalidCodeReport_AI]
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
            SET @finalFromDate = DATEADD(DAY, -7, @today)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'month' OR @datePreset = 'last30days'
        BEGIN
            SET @finalFromDate = DATEADD(DAY, -30, @today)
            SET @finalToDate = GETDATE()
        END
        ELSE
        BEGIN
            -- Default to last 7 days
            SET @finalFromDate = DATEADD(DAY, -7, @today)
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
GO
