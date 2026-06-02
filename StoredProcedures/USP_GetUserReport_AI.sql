USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetUserReport_AI]    Script Date: 4/28/2026 6:53:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Modified:    2026-04-29
-- Description: Highly optimized User scanning report.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetUserReport_AI]
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
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' SET @CodeStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' SET @DialModeFilter = NULL;

    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01')
    FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1;

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
    -- 3. Execution Branching
    -------------------------------------------------
    IF @Comp_ID = 'Comp-1693'
    BEGIN
        SELECT 
            ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN pe.Status IN ('Authenticate', 'Re-Authenticate') THEN 1 ELSE 0 END) DESC, pe.MobileLast10) AS SNo,
            MAX(pe.MobileNo) AS MobileNo,
            ISNULL(pe.State, '') AS State,
            ISNULL(pe.City, '') AS City,
            '' AS Email,
            ISNULL(mc.ConsumerName, 'Anonymous') AS ConsumerName,
            COUNT(*) AS TotalCodeScanned,
            SUM(CASE WHEN pe.Status IN ('Authenticate', 'Re-Authenticate') THEN 1 ELSE 0 END) AS SuccessfulCodeScanned,
            SUM(CASE WHEN pe.Status = 'Failed' THEN 1 ELSE 0 END) AS UnsuccessfulCodeScanned,
            MIN(pe.Enq_Date) AS FirstScannedDate,
            MAX(pe.Enq_Date) AS LastScannedDate,
            ISNULL(pe.PinCode, '') AS PostCode,
            COUNT(*) OVER() AS TotalRecords
        FROM (
            SELECT *, RIGHT(MobileNo, 10) AS MobileLast10
            FROM pfl_codecheckData WITH (NOLOCK)
            WHERE Enq_Date >= @StartDate
              AND Enq_Date < @EndDate
              AND (@CompanyStartDate IS NULL OR Enq_Date >= @CompanyStartDate)
              AND (@StateFilter IS NULL OR State = @StateFilter)
              AND (@DialModeFilter IS NULL OR Dial_Mode = @DialModeFilter)
              AND (
                  @CodeStatusFilter IS NULL OR
                  (@CodeStatusFilter = 'Verified' AND Status = 'Authenticate') OR
                  (@CodeStatusFilter = 'Already Scanned' AND Status = 'Re-Authenticate') OR
                  (@CodeStatusFilter = 'Invalid' AND Status = 'Failed')
              )
              AND (@Search IS NULL OR (
                  MobileNo LIKE '%' + @Search + '%' OR 
                  UniqueCode LIKE '%' + @Search + '%' OR 
                  Batch_No LIKE '%' + @Search + '%' OR
                  Pro_Name LIKE '%' + @Search + '%' OR
                  Pro_ID LIKE '%' + @Search + '%'
              ))
        ) pe
        LEFT JOIN M_Consumer mc WITH (NOLOCK) ON pe.MobileLast10 = mc.MobileLast10
        GROUP BY pe.MobileLast10, pe.State, pe.City, mc.ConsumerName, pe.PinCode
        ORDER BY SuccessfulCodeScanned DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
        ------------------------------------------------------
        -- Step 1: Pre-filter Pro_Enq (The largest table)
        ------------------------------------------------------
        IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
        SELECT 
            Received_Code1, 
            Received_Code2, 
            MobileNo,
            RIGHT(MobileNo, 10) AS MobileLast10,
            Enq_Date, 
            Is_Success
        INTO #tempPro_Enq
        FROM Pro_Enq WITH (NOLOCK)
        WHERE Comp_ID = @Comp_ID
          AND Enq_Date >= @CompanyStartDate
          AND Enq_Date >= @StartDate
          AND Enq_Date < @EndDate
          AND (@DialModeFilter IS NULL OR Dial_Mode = @DialModeFilter)
          AND (
              @CodeStatusFilter IS NULL OR
              (@CodeStatusFilter = 'Verified' AND Is_Success = 1) OR
              (@CodeStatusFilter = 'Already Scanned' AND Is_Success = 2) OR
              (@CodeStatusFilter = 'Invalid' AND Is_Success NOT IN (1, 2))
          );

        CREATE INDEX IX_tempPro_Enq_Codes ON #tempPro_Enq(Received_Code1, Received_Code2);
        CREATE INDEX IX_tempPro_Enq_Mobile ON #tempPro_Enq(MobileLast10);

        ------------------------------------------------------
        -- Step 2: Pre-filter M_Code (Deduplicated per code pair)
        ------------------------------------------------------
        IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
        
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_ID 
              AND a.Use_Count > 0
        )
        SELECT Code1, Code2, Pro_ID
        INTO #tempM_Code 
        FROM DistinctCodes
        WHERE rn = 1;

        CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);

        ------------------------------------------------------
        -- Main Query (Using optimized temp tables)
        ------------------------------------------------------
        SELECT 
            ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN mc_tbl.Code1 IS NOT NULL AND pe.Is_Success = 1 THEN 1 ELSE 0 END) DESC, pe.MobileLast10) AS SNo,
            MAX(pe.MobileNo) AS MobileNo, -- Show one example mobile no
            ISNULL(mc.State, '') AS State,
            ISNULL(mc.City, '') AS City,
            ISNULL(mc.Email, '') AS Email,
            ISNULL(mc.ConsumerName, 'Anonymous') AS ConsumerName,
            COUNT(pe.Received_Code1) AS TotalCodeScanned,
            SUM(CASE WHEN mc_tbl.Code1 IS NOT NULL AND pe.Is_Success = 1 THEN 1 ELSE 0 END) AS SuccessfulCodeScanned,
            SUM(CASE WHEN mc_tbl.Code1 IS NULL OR pe.Is_Success <> 1 THEN 1 ELSE 0 END) AS UnsuccessfulCodeScanned,
            MIN(pe.Enq_Date) AS FirstScannedDate,
            MAX(pe.Enq_Date) AS LastScannedDate,
            ISNULL(mc.PinCode, '') AS PostCode,
            COUNT(*) OVER() AS TotalRecords
        FROM #tempPro_Enq pe
        LEFT JOIN M_Consumer mc WITH (NOLOCK) ON pe.MobileLast10 = mc.MobileLast10
        LEFT JOIN #tempM_Code mc_tbl ON LTRIM(RTRIM(CAST(mc_tbl.Code1 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
              AND LTRIM(RTRIM(CAST(mc_tbl.Code2 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
        GROUP BY pe.MobileLast10, mc.State, mc.City, mc.Email, mc.PinCode, mc.ConsumerName
        ORDER BY SuccessfulCodeScanned DESC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
        OPTION (RECOMPILE);
    END
END
GO
