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
-- Modified:    2026-04-29
-- Description: Ultra-optimized Live scanning tracking report using per-company flat tables.
-- =============================================
ALTER   PROCEDURE [dbo].[USP_GetLiveScanTracking_AI]
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
    @DialModeFilter NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @PageNumber IS NULL OR @PageNumber <= 0 SET @PageNumber = 1;
    IF @PageSize IS NULL OR @PageSize <= 0 SET @PageSize = 10;
    -- Normalize search/filter
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'All' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' OR @CodeStatusFilter = 'All' SET @CodeStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' OR @DialModeFilter = 'All' SET @DialModeFilter = NULL;

    -- 1. Construct Date Range
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

    -- 2. Pre-filter M_Code (Deduplicated per code pair)
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    
    ;WITH DistinctCodes AS (
        SELECT 
            a.Code1, 
            a.Code2, 
            a.Pro_ID,
            a.Batch_No,
            a.Use_Count,
            a.Series_Order,
            a.Series_Serial,
            ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC, a.Series_Order DESC) AS rn
        FROM M_Code a 
        INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
        WHERE b.Comp_ID = @Comp_ID
          AND a.Use_Count > 0
    )
    SELECT Code1, Code2, Pro_ID, Batch_No, Use_Count, Series_Order, Series_Serial
    INTO #tempM_Code 
    FROM DistinctCodes
    WHERE rn = 1;

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);

    ;WITH ResultCTE AS (
        SELECT 
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
            NULL AS ManufacturingDate,
            NULL AS ExpiryDate,
            CASE 
                WHEN mc.Use_Count > 10 THEN 'High Risk' 
                WHEN mc.Use_Count > 5 THEN 'Medium Risk' 
                ELSE 'Low Risk' 
            END AS RiskAbuseFlag,
            NULL AS ClaimID,
            pe.MobileNo AS ConsumerMobile,
            mcn.ConsumerName,
            pe.Latitude,
            pe.Longitude
        FROM Pro_Enq pe
        LEFT JOIN #tempM_Code mc ON LTRIM(RTRIM(CAST(mc.Code1 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
              AND LTRIM(RTRIM(CAST(mc.Code2 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
        LEFT JOIN Pro_Reg pr ON pr.Pro_ID = mc.Pro_ID
        LEFT JOIN M_Consumer mcn ON mcn.MobileNo = pe.MobileNo
        WHERE (pe.Comp_ID = @Comp_ID OR mc.Pro_ID IS NOT NULL)
          AND (mcn.IsDelete IS NULL OR mcn.IsDelete = 0)
          AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
          AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
          AND (@StateFilter IS NULL OR pe.state = @StateFilter)
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
          AND (@Search IS NULL OR (
                pe.MobileNo LIKE '%' + @Search + '%' OR 
                (ISNULL(CAST(pe.Received_Code1 AS VARCHAR(50)), '') + ISNULL(CAST(pe.Received_Code2 AS VARCHAR(50)), '')) LIKE '%' + @Search + '%' OR 
                mc.Batch_No LIKE '%' + @Search + '%' OR
                pr.Pro_Name LIKE '%' + @Search + '%' OR
                pr.Pro_ID LIKE '%' + @Search + '%'
          ))
    )
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ScanTimestamp DESC) AS SNo,
        ScanTimestamp,
        Product,
        VariantSKU,
        BatchNo,
        UniqueCode,
        ScanResult,
        FirstOrRepeat,
        TotalScansForUID,
        City,
        State,
        PinCode,
        Channel,
        DistributorRetailer,
        ManufacturingDate,
        ExpiryDate,
        RiskAbuseFlag,
        ClaimID,
        ConsumerMobile,
        ConsumerName,
        Latitude,
        Longitude,
        COUNT(*) OVER() AS TotalRecords
    FROM ResultCTE
    WHERE (@CodeStatusFilter IS NULL OR ScanResult = @CodeStatusFilter)
    ORDER BY ScanTimestamp DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
