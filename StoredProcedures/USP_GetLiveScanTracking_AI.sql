SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GetLiveScanTracking_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset NVARCHAR(20) = 'month',
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
        SET @datePreset = 'month'
    ELSE
        SET @datePreset = LOWER(LTRIM(RTRIM(@datePreset)));

    IF @datePreset = 'all'
    BEGIN
        SET @finalFromDate = @CompanyStartDate
        SET @finalToDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
    END
    ELSE IF @datePreset = 'custom'
    BEGIN
        SET @finalFromDate = @FromDate
        SET @finalToDate = @ToDate
    END
    ELSE
    BEGIN
        DECLARE @today DATE = CAST(GETDATE() AS DATE)
        SET DATEFIRST 1;

        IF @datePreset = 'today'
        BEGIN SET @finalFromDate = @today; SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastday'
        BEGIN SET @finalFromDate = DATEADD(DAY,-1,@today); SET @finalToDate = DATEADD(SECOND,-1,CAST(@today AS DATETIME)) END
        ELSE IF @datePreset = 'week'
        BEGIN SET @finalFromDate = DATEADD(DAY,1-DATEPART(WEEKDAY,@today),@today); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastweek'
        BEGIN
            DECLARE @thisMonday DATE = DATEADD(DAY,1-DATEPART(WEEKDAY,@today),@today)
            SET @finalFromDate = DATEADD(DAY,-7,@thisMonday); SET @finalToDate = DATEADD(SECOND,-1,CAST(@thisMonday AS DATETIME))
        END
        ELSE IF @datePreset = 'month' OR @datePreset = 'last30days'
        BEGIN SET @finalFromDate = DATEADD(DAY,-30,@today); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastmonth'
        BEGIN SET @finalFromDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)); SET @finalToDate = DATEADD(SECOND,-1,CAST(DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1) AS DATETIME)) END
        ELSE IF @datePreset = 'quarter'
        BEGIN SET @finalFromDate = DATEADD(QUARTER,DATEDIFF(QUARTER,0,GETDATE()),0); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'year'
        BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()),1,1); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastyear'
        BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE())-1,1,1); SET @finalToDate = DATEFROMPARTS(YEAR(GETDATE())-1,12,31) END
        ELSE
        BEGIN SET @finalFromDate = DATEADD(DAY,-30,@today); SET @finalToDate = GETDATE() END
    END

    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    SELECT a.* INTO #tempM_Code FROM M_Code a 
    INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
    WHERE b.Comp_ID = @Comp_ID AND a.Print_Date >= @CompanyStartDate;

    IF OBJECT_ID('tempdb..#tempM_ServiceSubscription') IS NOT NULL DROP TABLE #tempM_ServiceSubscription;
    SELECT * INTO #tempM_ServiceSubscription FROM M_ServiceSubscription WHERE Comp_ID = @Comp_ID;

    SELECT 
        ROW_NUMBER() OVER (ORDER BY pe.Enq_Date DESC) AS SNo,
        pe.Enq_Date AS ScanTimestamp,
        pr.Pro_Name AS Product,
        pr.Pro_ID AS VariantSKU,
        mc.Batch_No AS BatchNo,
        ISNULL(pe.Received_Code1, '') + ISNULL(pe.Received_Code2, '') AS UniqueCode,
        CASE WHEN pe.Is_Success = 1 THEN 'Genuine' ELSE 'Duplicate/Invalid' END AS ScanResult,
        CASE WHEN mc.Use_Count <= 1 THEN 'First' ELSE 'Repeat' END AS FirstOrRepeat,
        ISNULL(mc.Use_Count, 0) AS TotalScansForUID,
        ISNULL(pe.City, '') AS City,
        ISNULL(pe.state, '') AS State,
        ISNULL(pe.PinCode, '') AS PinCode,
        ISNULL(pe.Dial_Mode, 'Web') AS Channel,
        ISNULL(mcn.FirmName, mcn.SellerName) AS DistributorRetailer,
        NULL AS ManufacturingDate,
        NULL AS ExpiryDate,
        CASE 
            WHEN mc.Use_Count > 10 THEN 'High Risk' 
            WHEN mc.Use_Count > 5 THEN 'Medium Risk' 
            ELSE 'Low Risk' 
        END AS RiskAbuseFlag,
        NULL AS ClaimID,
        pe.MobileNo AS ConsumerMobile,
        pe.Latitude,
        pe.Longitude,
        COUNT(*) OVER() AS TotalRecords
    FROM Pro_Enq pe
    LEFT JOIN #tempM_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
    LEFT JOIN Pro_Reg pr ON pr.Pro_ID = mc.Pro_ID
    LEFT JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc.Pro_ID 
    LEFT JOIN M_Consumer mcn ON mcn.MobileNo = pe.MobileNo
    WHERE pe.Comp_ID = @Comp_ID
      AND pe.Enq_Date >= @CompanyStartDate
      AND (@ServiceID IS NULL OR sd.Service_ID = @ServiceID)
      AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
      AND (@StateFilter IS NULL OR pe.State = @StateFilter)
      AND (@Search IS NULL OR pe.MobileNo LIKE '%'+@Search+'%' 
           OR pr.Pro_Name LIKE '%'+@Search+'%'
           OR ISNULL(pe.Received_Code1,'')+ISNULL(pe.Received_Code2,'') LIKE '%'+@Search+'%')
    ORDER BY pe.Enq_Date DESC
    OFFSET (@PageNumber-1)*@PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport=1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
GO
