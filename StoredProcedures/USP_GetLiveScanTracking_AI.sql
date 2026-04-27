USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetLiveScanTracking_AI]    Script Date: 4/27/2026 4:25:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Description: Get live scan tracking report for the last 30 days
-- =============================================
ALTER   PROCEDURE [dbo].[USP_GetLiveScanTracking_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset NVARCHAR(20) = 'month',
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
        pe.Enq_Date AS ScanTimestamp,
        pr.Pro_Name AS Product,
        pr.Pro_ID AS VariantSKU,
        mc.Batch_No AS BatchNo,
        ISNULL(pe.Received_Code1, '') + ISNULL(pe.Received_Code2, '') AS UniqueCode,
        CASE 
            WHEN mc.Code1 IS NULL THEN 'Invalid'
            WHEN pe.Is_Success = 2 THEN 'Duplicate'
            WHEN pe.Is_Success = 1 THEN 'Genuine'
            ELSE 'Invalid' 
        END AS ScanResult,
        CASE WHEN mc.Use_Count <= 1 THEN 'First' ELSE 'Repeat' END AS FirstOrRepeat,
        ISNULL(mc.Use_Count, 0) AS TotalScansForUID,
        ISNULL(pe.City, '') AS City,
        ISNULL(pe.state, '') AS State,
        ISNULL(pe.PinCode, '') AS PinCode,
        ISNULL(pe.Dial_Mode, 'Web') AS Channel,
        ISNULL(mcn.FirmName, mcn.SellerName) AS DistributorRetailer,
        NULL AS ManufacturingDate, -- To be updated if table found
        NULL AS ExpiryDate,        -- To be updated if table found
        CASE 
            WHEN mc.Use_Count > 10 THEN 'High Risk' 
            WHEN mc.Use_Count > 5 THEN 'Medium Risk' 
            ELSE 'Low Risk' 
        END AS RiskAbuseFlag,
        NULL AS ClaimID,           -- To be joined with Claim table if needed
        pe.MobileNo AS ConsumerMobile,
        pe.Latitude,
        pe.Longitude,
        COUNT(*) OVER() AS TotalRecords
    FROM Pro_Enq pe
    LEFT JOIN #tempM_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
    LEFT JOIN Pro_Reg pr ON pr.Pro_ID = mc.Pro_ID
    --LEFT JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc.Pro_ID 
     --   AND CONCAT(FORMAT(mc.Series_Order, '000#'), FORMAT(mc.Series_Serial, '000#')) 
     --       BETWEEN CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#')) 
     --           AND CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
    LEFT JOIN M_Consumer mcn ON mcn.MobileNo = pe.MobileNo
    WHERE pe.Comp_ID = @Comp_ID and mcn.IsDelete = 0
     -- AND (@ServiceID IS NULL OR sd.Service_ID = @ServiceID)
      AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date <= @finalToDate)
    ORDER BY pe.Enq_Date DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
