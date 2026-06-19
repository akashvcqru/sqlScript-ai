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
    DECLARE @Today DATE = CAST(DATEADD(MINUTE, 330, GETUTCDATE()) AS DATE); -- Convert to IST before taking date
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
    -- 3. Pre-filter M_Code (Removed - using OUTER APPLY instead)
    -------------------------------------------------


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
        ------------------------------------------------------
        -- Step 1: Pre-filter M_Code (Deduplicated per code pair)
        ------------------------------------------------------
        IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
        
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Batch_No,
                a.Use_Count,
                CAST(a.Code1 AS VARCHAR(50)) AS VCode1,
                CAST(a.Code2 AS VARCHAR(50)) AS VCode2,
                CAST(a.Code1 AS VARCHAR(50)) + CAST(a.Code2 AS VARCHAR(50)) AS CombinedCode,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC, a.Series_Order DESC) AS rn
            FROM M_Code a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_ID 
              AND a.Use_Count > 0
        )
        SELECT *
        INTO #tempM_Code 
        FROM DistinctCodes
        WHERE rn = 1;

        CREATE INDEX IX_tempM_Code_12 ON #tempM_Code(VCode1, VCode2);
        CREATE INDEX IX_tempM_Code_Combined ON #tempM_Code(CombinedCode);

        ------------------------------------------------------
        -- Step 2: Pre-filter Pro_Enq (The largest table)
        ------------------------------------------------------
        IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
        
        SELECT 
            pe.Enq_Date,
            pe.Received_Code1,
            pe.Received_Code2,
            pe.Is_Success,
            pe.City,
            pe.state,
            pe.PinCode,
            pe.Dial_Mode,
            pe.MobileNo,
            pe.Latitude,
            pe.Longitude,
            pe.IsVerified,
            pe.Comp_ID,
            LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) AS VCode1,
            LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50)))) AS VCode2,
            LTRIM(RTRIM(ISNULL(CAST(pe.Received_Code1 AS VARCHAR(50)), ''))) + LTRIM(RTRIM(ISNULL(CAST(pe.Received_Code2 AS VARCHAR(50)), ''))) AS CombinedCode
        INTO #tempPro_Enq
        FROM Pro_Enq pe WITH (NOLOCK)
        WHERE pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND (@CompanyStartDate IS NULL OR pe.Enq_Date >= @CompanyStartDate)
          AND (pe.Comp_ID = @Comp_ID OR ISNULL(pe.Comp_ID, '') = '')
          AND (@StateFilter IS NULL OR pe.state = @StateFilter)
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)

        CREATE INDEX IX_tempPro_Enq_12 ON #tempPro_Enq(VCode1, VCode2);
        CREATE INDEX IX_tempPro_Enq_Combined ON #tempPro_Enq(CombinedCode);

        ------------------------------------------------------
        -- Step 3: Result Query
        ------------------------------------------------------
        ;WITH ResultCTE AS (
            SELECT 
                pe.Enq_Date AS ScanTimestamp,
                pr.Pro_Name AS Product,
                pr.Pro_ID AS VariantSKU,
                mc.Batch_No AS BatchNo,
                pe.CombinedCode AS UniqueCode,
                CASE 
                    WHEN mc.VCode1 IS NULL THEN 'Invalid'
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
            FROM #tempPro_Enq pe
            OUTER APPLY (
                SELECT TOP 1 * FROM #tempM_Code m
                WHERE (m.VCode1 = pe.VCode1 AND m.VCode2 = pe.VCode2)
                   OR (m.CombinedCode = pe.CombinedCode)
            ) mc
            LEFT JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mc.Pro_ID
            LEFT JOIN M_Consumer mcn WITH (NOLOCK) ON mcn.MobileNo = pe.MobileNo AND (mcn.IsDelete IS NULL OR mcn.IsDelete = 0)
            WHERE (pe.Comp_ID = @Comp_ID OR (ISNULL(pe.Comp_ID, '') = '' AND mc.VCode1 IS NOT NULL))
              AND (@Search IS NULL OR (
                    pe.MobileNo LIKE '%' + @Search + '%' OR 
                    pe.CombinedCode LIKE '%' + @Search + '%' OR 
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
