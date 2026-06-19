USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec USP_GetHighestCounterfeitActivities_AI 'Comp-1599','QUARTER'
CREATE OR ALTER PROCEDURE [dbo].[USP_GetHighestCounterfeitActivities_AI]
(
    @Comp_Id VARCHAR(20),
    @datePreset  NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------
    -- Date Window
    ------------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

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
        SET @StartDate = '19000101';
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END

    ------------------------------------------------------
    -- 1. Build Optimized Temp Tables for Scans & Codes
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
    SELECT 
        pe.MobileNo AS OriginalMobileNo,
        RIGHT(pe.MobileNo,10) AS MobileLast10,
        pe.Is_Success,
        pe.Enq_Date,
        pe.Comp_ID,
        pe.State AS Pe_State,
        LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) AS VCode1,
        LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50)))) AS VCode2
    INTO #tempPro_Enq
    FROM Pro_Enq pe WITH (NOLOCK)
    WHERE pe.Enq_Date >= @StartDate
      AND pe.Enq_Date < @EndDate
      AND (pe.Comp_ID = @Comp_Id OR ISNULL(pe.Comp_ID, '') = '');

    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    CREATE TABLE #tempM_Code (
        Code1 VARCHAR(100),
        Code2 VARCHAR(100),
        Pro_ID VARCHAR(50),
        Use_Count INT,
        VCode1 VARCHAR(50),
        VCode2 VARCHAR(50)
    );

    IF @Comp_Id = 'Comp-1693'
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, a.Code2, a.Pro_ID, a.Use_Count, 
                CAST(a.Code1 AS VARCHAR(50)) AS VCode1, 
                CAST(a.Code2 AS VARCHAR(50)) AS VCode2,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code_PFL a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_Id AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, Use_Count, VCode1, VCode2)
        SELECT Code1, Code2, Pro_ID, Use_Count, VCode1, VCode2 FROM DistinctCodes WHERE rn = 1;
    END
    ELSE
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, a.Code2, a.Pro_ID, a.Use_Count, 
                CAST(a.Code1 AS VARCHAR(50)) AS VCode1, 
                CAST(a.Code2 AS VARCHAR(50)) AS VCode2,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_Id AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, Use_Count, VCode1, VCode2)
        SELECT Code1, Code2, Pro_ID, Use_Count, VCode1, VCode2 FROM DistinctCodes WHERE rn = 1;
    END

    CREATE INDEX IX_tempM_Code_12 ON #tempM_Code(VCode1, VCode2);

    ------------------------------------------------------
    -- 2. Build ScansWithGeo & CleanScans
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#ValidStates') IS NOT NULL DROP TABLE #ValidStates;

    ;WITH ScansWithGeo AS (
        SELECT 
            pe.OriginalMobileNo,
            pe.MobileLast10,
            pe.Is_Success,
            pe.Enq_Date,
            mc.Use_Count,
            COALESCE(
                NULLIF(g.State, ''), 
                NULLIF(pe.Pe_State, ''), 
                NULLIF(mc_usr.State, ''), 
                'Not Available'
            ) AS State
        FROM #tempPro_Enq pe
        LEFT JOIN #tempM_Code mc ON mc.VCode1 = pe.VCode1 AND mc.VCode2 = pe.VCode2
        LEFT JOIN GeoLocationData g WITH (NOLOCK) 
            ON g.Code1 = pe.VCode1 
            AND g.Code2 = pe.VCode2 
            AND RIGHT(g.MobileNo, 10) = pe.MobileLast10
        LEFT JOIN M_Consumer mc_usr ON RIGHT(pe.MobileLast10, 10) = mc_usr.MobileLast10
        WHERE (pe.Comp_Id = @Comp_Id OR (ISNULL(pe.Comp_Id, '') = '' AND mc.Pro_ID IS NOT NULL))
    ),
    LatestScans AS
    (
        SELECT
            MobileLast10,
            Is_Success,
            Use_Count,
            State,
            ROW_NUMBER() OVER (PARTITION BY MobileLast10 ORDER BY Enq_Date DESC) as rn
        FROM ScansWithGeo
    ),
    CleanScans AS
    (
        SELECT * FROM LatestScans WHERE rn = 1
    )
    SELECT * INTO #ValidStates FROM CleanScans;

    ------------------------------------------------------
    -- 3. Final Aggregation
    ------------------------------------------------------
    SELECT TOP 10
        CASE 
            WHEN LEN(LTRIM(RTRIM(State))) < 2 THEN 'NA'
            WHEN State = 'Not Available' THEN 'NA'
            ELSE State
        END AS StateName,
        SUM(CASE WHEN Use_Count = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS SuccessScans,
        SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS FailedScans,
        COUNT(*) AS TotalScans
    FROM #ValidStates
    GROUP BY State
    ORDER BY TotalScans DESC;
END
GO
