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

    -------------------------------------------------
    -- 1. Get Company Registration Date
    -------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = Reg_Date
    FROM Comp_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_ID AND Status = 1;

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

    -------------------------------------------------
    -- 3. Pre-filter M_Code (Deduplicated per code pair)
    -------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    
    CREATE TABLE #tempM_Code (
        Code1 VARCHAR(100),
        Code2 VARCHAR(100),
        Pro_ID VARCHAR(50),
        Batch_No VARCHAR(100),
        Use_Count INT,
        Series_Order INT,
        Series_Serial INT
    );

    IF @Comp_ID = 'Comp-1693'
    BEGIN
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
            FROM M_Code_PFL a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_ID
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, Batch_No, Use_Count, Series_Order, Series_Serial)
        SELECT Code1, Code2, Pro_ID, Batch_No, Use_Count, Series_Order, Series_Serial
        FROM DistinctCodes
        WHERE rn = 1;
    END
    ELSE
    BEGIN
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
            FROM M_Code a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_ID
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, Batch_No, Use_Count, Series_Order, Series_Serial)
        SELECT Code1, Code2, Pro_ID, Batch_No, Use_Count, Series_Order, Series_Serial
        FROM DistinctCodes
        WHERE rn = 1;
    END

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);

    -------------------------------------------------
    -- 4. Result Query
    -------------------------------------------------
    IF @Comp_ID = 'Comp-1693'
    BEGIN
        ;WITH ResultCTE AS (
            SELECT 
                pe.Enq_Date AS ScanTimestamp,
                pe.Pro_Name AS Product,
                pe.Pro_ID AS VariantSKU,
                pe.Batch_No AS BatchNo,
                pe.UniqueCode AS UniqueCode,
                CASE 
                    WHEN pe.Status = 'Authenticate' THEN 'Genuine'
                    WHEN pe.Status = 'Re-Authenticate' THEN 'Duplicate'
                    ELSE 'Invalid' 
                END AS ScanResult,
                CASE WHEN pe.Status = 'Authenticate' THEN 'First' ELSE 'Repeat' END AS FirstOrRepeat,
                ISNULL(pe.Use_Count, 0) AS TotalScansForUID,
                ISNULL(pe.City, '') AS City,
                ISNULL(pe.State, '') AS State,
                ISNULL(pe.PinCode, '') AS PinCode,
                ISNULL(pe.Dial_Mode, 'Web') AS Channel,
                NULL AS DistributorRetailer,
                pe.MfgDate AS ManufacturingDate,
                pe.ExpiryDate AS ExpiryDate,
                ISNULL(pe.RiskLevel, 'Low Risk') AS RiskAbuseFlag,
                NULL AS ClaimID,
                pe.MobileNo AS ConsumerMobile,
                NULL AS ConsumerName,
                pe.Latitude,
                pe.Longitude,
                ISNULL(pe.IsVerified, 0) AS ImageVerified
            FROM pfl_codecheckData pe WITH (NOLOCK)
            WHERE pe.Enq_Date >= @StartDate
              AND pe.Enq_Date < @EndDate
              AND (@CompanyStartDate IS NULL OR pe.Enq_Date >= @CompanyStartDate)
              AND (@StateFilter IS NULL OR pe.State = @StateFilter)
              AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
              AND (@Search IS NULL OR (
                    pe.MobileNo LIKE '%' + @Search + '%' OR 
                    pe.UniqueCode LIKE '%' + @Search + '%' OR 
                    pe.Batch_No LIKE '%' + @Search + '%' OR
                    pe.Pro_Name LIKE '%' + @Search + '%' OR
                    pe.Pro_ID LIKE '%' + @Search + '%'
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
            ImageVerified,
            COUNT(*) OVER() AS TotalRecords
        FROM ResultCTE
        WHERE (@CodeStatusFilter IS NULL OR ScanResult = @CodeStatusFilter)
        ORDER BY ScanTimestamp DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
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
                pe.Longitude,
                ISNULL(pe.IsVerified, 0) AS ImageVerified
            FROM Pro_Enq pe WITH (NOLOCK)
            LEFT JOIN #tempM_Code mc ON LTRIM(RTRIM(CAST(mc.Code1 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
                  AND LTRIM(RTRIM(CAST(mc.Code2 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
            LEFT JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mc.Pro_ID
            LEFT JOIN M_Consumer mcn WITH (NOLOCK) ON mcn.MobileNo = pe.MobileNo
            WHERE pe.Comp_ID = @Comp_ID
              AND (mcn.IsDelete IS NULL OR mcn.IsDelete = 0)
              AND pe.Enq_Date >= @StartDate
              AND pe.Enq_Date < @EndDate
              AND (@CompanyStartDate IS NULL OR pe.Enq_Date >= @CompanyStartDate)
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
            ImageVerified,
            COUNT(*) OVER() AS TotalRecords
        FROM ResultCTE
        WHERE (@CodeStatusFilter IS NULL OR ScanResult = @CodeStatusFilter)
        ORDER BY ScanTimestamp DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
        OPTION (RECOMPILE);
    END
END
