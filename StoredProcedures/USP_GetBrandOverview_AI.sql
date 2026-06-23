/****** Object:  StoredProcedure [dbo].[USP_GetBrandOverview_AI]    Script Date: 4/7/2026 11:04:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER Procedure [dbo].[USP_GetBrandOverview_AI]     
    @CompanyKey         NVARCHAR(100),          -- Comp_ID
    @datePreset             VARCHAR(20) = NULL,    
    @CompanyKeyType     VARCHAR(10) = 'ID',     -- 'ID' | 'EMAIL' | 'NAME'    
    @FromDate           DATE        = NULL,     -- inclusive start
    @ToDate             DATE        = NULL,     -- inclusive end    
    @ServiceID          INT         = NULL,     -- optional filter    
    @OveruseThreshold   INT         = 10        -- distinct (code1, code2) count > threshold => suspicious    
AS                
BEGIN                  
    SET NOCOUNT ON;    

    ---------------------------------------------------------
    -- DATE RANGE LOGIC
    ---------------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

    IF @Win = 'TODAY'
    BEGIN
        SET @StartDate = @Today;
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'YESTERDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, @Today);
        SET @EndDate   = DATEADD(DAY, -1, @Today);
    END
    ELSE IF @Win = 'WEEK'
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
        SET @EndDate   = DATEADD(DAY, -1, @ThisWeekStart);
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @StartDate = DATEADD(MONTH, -1, @ThisMonthStart);
        SET @EndDate   = DATEADD(DAY, -1, @ThisMonthStart);
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, @Today);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'YEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'LASTYEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(@Today) - 1, 12, 31);
    END
    ELSE
    BEGIN
        -- Default = ALL
        SET @StartDate = '2015-01-01';
        SET @EndDate   = @Today;
    END

    ---------------------------------------------------------
    -- Step 1: Pre-filter M_Code (Deduplicated)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    CREATE TABLE #tempM_Code (
        Code1 VARCHAR(100),
        Code2 VARCHAR(100),
        Pro_ID VARCHAR(50),
        VCode1 VARCHAR(50),
        VCode2 VARCHAR(50)
    );

    IF @CompanyKey = 'Comp-1693'
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code_PFL a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @CompanyKey 
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, VCode1, VCode2)
        SELECT Code1, Code2, Pro_ID, CAST(Code1 AS VARCHAR(50)), CAST(Code2 AS VARCHAR(50))
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
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @CompanyKey 
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, VCode1, VCode2)
        SELECT Code1, Code2, Pro_ID, CAST(Code1 AS VARCHAR(50)), CAST(Code2 AS VARCHAR(50))
        FROM DistinctCodes
        WHERE rn = 1;
    END

    CREATE INDEX IX_tempM_Code_12 ON #tempM_Code(VCode1, VCode2);

    ---------------------------------------------------------
    -- Step 2: Pre-filter Pro_Enq
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_EnqBase') IS NOT NULL DROP TABLE #tempPro_EnqBase;
    SELECT 
        pe.MobileNo, 
        pe.Is_Success, 
        pe.Received_Code1, 
        pe.Received_Code2,
        pe.Comp_ID,
        RIGHT(pe.MobileNo, 10) AS MobileLast10,
        LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) AS VCode1,
        LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50)))) AS VCode2
    INTO #tempPro_EnqBase
    FROM Pro_Enq pe WITH (NOLOCK)
    WHERE pe.Enq_Date >= CAST(@StartDate AS DATETIME)
      AND pe.Enq_Date < DATEADD(DAY, 1, CAST(@EndDate AS DATETIME))
      AND (pe.Comp_ID = @CompanyKey OR ISNULL(pe.Comp_ID, '') = '');

    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
    SELECT 
        pe.MobileNo, 
        pe.Is_Success, 
        pe.Received_Code1, 
        pe.Received_Code2,
        pe.MobileLast10,
        CASE WHEN mc.Pro_ID IS NOT NULL THEN 1 ELSE 0 END AS CodeExists
    INTO #tempPro_Enq
    FROM #tempPro_EnqBase pe
    LEFT JOIN #tempM_Code mc ON mc.VCode1 = pe.VCode1 AND mc.VCode2 = pe.VCode2
    WHERE (pe.Comp_ID = @CompanyKey OR (ISNULL(pe.Comp_ID, '') = '' AND mc.Pro_ID IS NOT NULL));

    ---------------------------------------------------------
    -- Step 3: Aggregates
    ---------------------------------------------------------
    DECLARE @LifetimeCodeGeneration INT;
    IF @CompanyKey = 'Comp-1693'
        SET @LifetimeCodeGeneration = (SELECT COUNT(1) FROM M_Code_PFL WITH (NOLOCK) WHERE Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WITH (NOLOCK) WHERE Comp_ID = @CompanyKey));
    ELSE
        SET @LifetimeCodeGeneration = (SELECT COUNT(1) FROM M_Code WITH (NOLOCK) WHERE Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WITH (NOLOCK) WHERE Comp_ID = @CompanyKey));
    DECLARE @AntiCounterfeitMeasures INT = (SELECT COUNT(*) FROM #tempPro_Enq WHERE CodeExists = 1 AND Is_Success = 1);
    DECLARE @CounterfeitAttemptsDetected INT = (SELECT COUNT(*) FROM #tempPro_Enq WHERE CodeExists = 0 OR Is_Success NOT IN (1, 2));
    DECLARE @NumberofScans INT = (SELECT COUNT(*) FROM #tempPro_Enq);
    DECLARE @RepeatedCodes INT = (SELECT COUNT(*) FROM #tempPro_Enq WHERE CodeExists = 1 AND Is_Success = 2);
    DECLARE @NumberofActiveUsers INT = (SELECT COUNT(DISTINCT MobileLast10) FROM #tempPro_Enq WHERE Is_Success = 1);

    SELECT 'Anti-Counterfeit Measures'      AS title, @AntiCounterfeitMeasures      AS TotalCount,
           0.00 AS per, '#FFC107' AS ColorCode, '/anti-counterfeit' AS link
    UNION ALL
    SELECT 'Counterfeit Attempts Detected', @CounterfeitAttemptsDetected,
           0.00, '#FF0000', '/anti-counterfeit'
    UNION ALL
    SELECT 'Number of Scans',               @NumberofScans,
           0.00, '#E2852E', '/anti-counterfeit'
    UNION ALL
    SELECT 'Repeated Codes (= 10)',         @RepeatedCodes,
           0.00, '#62109F', '/anti-counterfeit'
    UNION ALL
    SELECT 'Number of Active Users',        @NumberofActiveUsers,
           0.00, '#F87B1B', '/anti-counterfeit'
    UNION ALL
    SELECT 'Lifetime Code Generation',      @LifetimeCodeGeneration,
           100.00, '#FC5185', '/anti-counterfeit';
END
GO
