USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetStateWiseReport_AI]    Script Date: 4/28/2026 5:01:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Modified:    2026-04-29
-- Description: Highly optimized State-wise Report.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetStateWiseReport_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset NVARCHAR(20) = 'All',
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
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'All' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' OR @CodeStatusFilter = 'All' OR @CodeStatusFilter = 'All Status' SET @CodeStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' OR @DialModeFilter = 'All' OR @DialModeFilter = 'All Modes' SET @DialModeFilter = NULL;

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

    ------------------------------------------------------
    -- Step 1: Pre-filter M_Code (Deduplicated per code pair)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    
    IF @Comp_ID <> 'Comp-1693'
    BEGIN
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
    END

    ------------------------------------------------------
    -- Step 2: Pre-filter Pro_Enq
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;

    CREATE TABLE #tempPro_Enq (
        State NVARCHAR(100),
        City NVARCHAR(100),
        MobileNo VARCHAR(50),
        Is_Success INT,
        Enq_Date DATETIME,
        Received_Code1 VARCHAR(100),
        Received_Code2 VARCHAR(100),
        MobileLast10 VARCHAR(10),
        CodeExists INT,
        PinCode VARCHAR(20)
    );

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        INSERT INTO #tempPro_Enq (State, City, MobileNo, Is_Success, Enq_Date, Received_Code1, Received_Code2, MobileLast10, CodeExists, PinCode)
        SELECT 
            COALESCE(
                NULLIF(g.State, ''), 
                NULLIF(pe.State, ''), 
                NULLIF(mc.State, ''), 
                'Not Available'
            ) AS State,
            COALESCE(
                NULLIF(g.City, ''), 
                NULLIF(pe.City, ''), 
                NULLIF(mc.City, ''), 
                'Not Available'
            ) AS City,
            pe.MobileNo, 
            CASE 
                WHEN pe.Status = 'Authenticate' THEN 1 
                WHEN pe.Status = 'Re-Authenticate' THEN 2 
                ELSE 0 
            END AS Is_Success, 
            pe.Enq_Date, 
            pe.UniqueCode AS Received_Code1, 
            '' AS Received_Code2,
            RIGHT(pe.MobileNo, 10) AS MobileLast10,
            CASE 
                WHEN pe.Status IN ('Authenticate', 'Re-Authenticate') THEN 1 
                ELSE 0 
            END AS CodeExists,
            COALESCE(
                NULLIF(pe.PinCode, ''), 
                NULLIF(g.Postcode, ''), 
                NULLIF(mc.PinCode, ''), 
                ''
            ) AS PinCode
        FROM pfl_codecheckData pe WITH (NOLOCK)
        LEFT JOIN M_Consumer mc WITH (NOLOCK) ON RIGHT(pe.MobileNo, 10) = mc.MobileLast10
        LEFT JOIN GeoLocationData g WITH (NOLOCK) 
            ON g.Comp_Id = pe.Comp_Id 
            AND g.MobileNo = pe.MobileNo
            AND g.Code1 = pe.Code1V
            AND g.Code2 = pe.Code2V
        WHERE pe.Enq_Date >= @CompanyStartDate
          AND pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
          AND (
              @CodeStatusFilter IS NULL OR
              (@CodeStatusFilter = 'Genuine' AND pe.Status = 'Authenticate') OR
              (@CodeStatusFilter = 'Duplicate' AND pe.Status = 'Re-Authenticate') OR
              (@CodeStatusFilter = 'Invalid' AND pe.Status NOT IN ('Authenticate', 'Re-Authenticate'))
          )
          AND COALESCE(NULLIF(g.State, ''), NULLIF(pe.State, ''), NULLIF(mc.State, ''), 'Not Available') NOT IN ('NA','undefined','null')
          AND (@StateFilter IS NULL OR COALESCE(NULLIF(g.State, ''), NULLIF(pe.State, ''), NULLIF(mc.State, ''), 'Not Available') = @StateFilter);
    END
    ELSE
    BEGIN
        INSERT INTO #tempPro_Enq (State, City, MobileNo, Is_Success, Enq_Date, Received_Code1, Received_Code2, MobileLast10, CodeExists, PinCode)
        SELECT 
            COALESCE(
                NULLIF(g.State, ''), 
                NULLIF(pe.State, ''), 
                NULLIF(mc.State, ''), 
                'Not Available'
            ) AS State,
            COALESCE(
                NULLIF(g.City, ''), 
                NULLIF(pe.City, ''), 
                NULLIF(mc.City, ''), 
                'Not Available'
            ) AS City,
            pe.MobileNo, 
            pe.Is_Success, 
            pe.Enq_Date, 
            pe.Received_Code1, 
            pe.Received_Code2,
            RIGHT(pe.MobileNo, 10) AS MobileLast10,
            CASE WHEN m.Pro_ID IS NOT NULL THEN 1 ELSE 0 END AS CodeExists,
            COALESCE(
                NULLIF(pe.PinCode, ''), 
                NULLIF(g.Postcode, ''), 
                NULLIF(mc.PinCode, ''), 
                ''
            ) AS PinCode
        FROM Pro_Enq pe WITH (NOLOCK)
        LEFT JOIN #tempM_Code m ON LTRIM(RTRIM(CAST(m.Code1 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
              AND LTRIM(RTRIM(CAST(m.Code2 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
        LEFT JOIN M_Consumer mc WITH (NOLOCK) ON RIGHT(pe.MobileNo, 10) = mc.MobileLast10
        LEFT JOIN GeoLocationData g WITH (NOLOCK) 
            ON g.Comp_Id = pe.Comp_ID 
            AND g.MobileNo = pe.MobileNo
            AND g.Code1 = pe.Received_Code1
            AND g.Code2 = pe.Received_Code2
        WHERE pe.Comp_ID = @Comp_ID
          AND pe.Enq_Date >= @CompanyStartDate
          AND pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
          AND (
              @CodeStatusFilter IS NULL OR
              (@CodeStatusFilter = 'Genuine' AND pe.Is_Success = 1) OR
              (@CodeStatusFilter = 'Duplicate' AND pe.Is_Success = 2) OR
              (@CodeStatusFilter = 'Invalid' AND pe.Is_Success NOT IN (1, 2))
          )
          AND COALESCE(NULLIF(g.State, ''), NULLIF(pe.State, ''), NULLIF(mc.State, ''), 'Not Available') NOT IN ('NA','undefined','null')
          AND (@StateFilter IS NULL OR COALESCE(NULLIF(g.State, ''), NULLIF(pe.State, ''), NULLIF(mc.State, ''), 'Not Available') = @StateFilter);
    END

    CREATE INDEX IX_tempPro_Enq_Mobile ON #tempPro_Enq(MobileLast10);

    -- Get unique locations from scans and consumers
    ;WITH RawData AS (
        SELECT 
            pe.State,
            pe.City,
            pe.PinCode AS PostCode,
            pe.MobileLast10,
            mc.IsActive,
            mc.Entry_Date AS ConsumerEntryDate,
            pe.Is_Success,
            pe.Enq_Date,
            pe.CodeExists
        FROM #tempPro_Enq pe
        LEFT JOIN M_Consumer mc ON pe.MobileLast10 = mc.MobileLast10
        WHERE (@Search IS NULL OR pe.State LIKE '%'+@Search+'%' OR pe.City LIKE '%'+@Search+'%' OR pe.PinCode LIKE '%'+@Search+'%')
    ),
    LocationGroups AS (
        SELECT 
            State,
            City,
            PostCode,
            COUNT(DISTINCT MobileLast10) AS ActiveConsumers,
            COUNT(DISTINCT CASE WHEN ConsumerEntryDate >= @StartDate AND ConsumerEntryDate < @EndDate THEN MobileLast10 END) AS NewConsumers,
            COUNT(DISTINCT CASE WHEN ConsumerEntryDate < @StartDate THEN MobileLast10 END) AS ReturningConsumers,
            COUNT(*) AS TotalScans,
            SUM(CASE WHEN CodeExists = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS GenuineScans,
            SUM(CASE WHEN CodeExists = 1 AND Is_Success = 2 THEN 1 ELSE 0 END) AS DuplicateScans,
            SUM(CASE WHEN CodeExists = 0 OR Is_Success NOT IN (1, 2) THEN 1 ELSE 0 END) AS CounterfeitScans,
            CAST(CAST(COUNT(*) AS DECIMAL(18,2)) / NULLIF(COUNT(DISTINCT MobileLast10), 0) AS DECIMAL(18,2)) AS AvgScansPerConsumer
        FROM RawData
        GROUP BY State, City, PostCode
    )
    SELECT 
        ROW_NUMBER() OVER (ORDER BY State, City, PostCode) AS SNo,
        *,
        COUNT(*) OVER() AS TotalRecords
    FROM LocationGroups
    ORDER BY State, City, PostCode
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
GO
