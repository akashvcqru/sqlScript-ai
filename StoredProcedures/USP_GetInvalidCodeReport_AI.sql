USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetInvalidCodeReport_AI]    Script Date: 4/28/2026 4:48:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Modified:    2026-04-29
-- Description: Highly optimized Invalid code report.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetInvalidCodeReport_AI]
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
    -- Step 2: Pre-filter Pro_Enq (Filtered for Invalid Scans)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;

    CREATE TABLE #tempPro_Enq (
        MobileNo VARCHAR(50),
        Received_Code1 VARCHAR(100),
        Received_Code2 VARCHAR(100),
        Enq_Date DATETIME,
        Dial_Mode VARCHAR(50)
    );

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        INSERT INTO #tempPro_Enq (MobileNo, Received_Code1, Received_Code2, Enq_Date, Dial_Mode)
        SELECT 
            pe.MobileNo, 
            ISNULL(pe.Code1V, '') AS Received_Code1, 
            ISNULL(pe.Code2V, '') AS Received_Code2, 
            pe.Enq_Date, 
            pe.Dial_Mode
        FROM pfl_codecheckData pe WITH (NOLOCK)
        WHERE pe.Enq_Date >= @CompanyStartDate
          AND pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND (@StateFilter IS NULL OR pe.State = @StateFilter)
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
          AND pe.Status NOT IN ('Authenticate', 'Re-Authenticate')
          AND (@Search IS NULL OR (
                pe.MobileNo LIKE '%'+@Search+'%' OR 
                pe.Code1V LIKE '%'+@Search+'%' OR 
                pe.Code2V LIKE '%'+@Search+'%' OR
                pe.UniqueCode LIKE '%'+@Search+'%'
          ));
    END
    ELSE
    BEGIN
        INSERT INTO #tempPro_Enq (MobileNo, Received_Code1, Received_Code2, Enq_Date, Dial_Mode)
        SELECT 
            pe.MobileNo, 
            pe.Received_Code1, 
            pe.Received_Code2, 
            pe.Enq_Date, 
            pe.Dial_Mode
        FROM Pro_Enq pe WITH (NOLOCK)
        LEFT JOIN #tempM_Code mc ON LTRIM(RTRIM(CAST(mc.Code1 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
              AND LTRIM(RTRIM(CAST(mc.Code2 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
        WHERE pe.Comp_ID = @Comp_ID
          AND pe.Enq_Date >= @CompanyStartDate
          AND pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND (@StateFilter IS NULL OR pe.State = @StateFilter)
          AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
          AND (mc.Pro_ID IS NULL OR pe.Is_Success NOT IN (1, 2)) -- Matches Live Tracking 'Invalid' logic
          AND (@Search IS NULL OR (
                pe.MobileNo LIKE '%'+@Search+'%' OR 
                pe.Received_Code1 LIKE '%'+@Search+'%' OR 
                pe.Received_Code2 LIKE '%'+@Search+'%'
          ));
    END

    ------------------------------------------------------
    -- Main Query
    ------------------------------------------------------
    SELECT 
        ROW_NUMBER() OVER (ORDER BY pe.Enq_Date DESC) AS SNo,
        pe.MobileNo AS MobileNo,
        pe.Received_Code1 AS ReceivedCode1,
        pe.Received_Code2 AS ReceivedCode2,
        pe.Enq_Date AS ScanTimestamp,
        ISNULL(pe.Dial_Mode, 'Web') AS Channel,
        COUNT(*) OVER() AS TotalRecords
    FROM #tempPro_Enq pe
    ORDER BY pe.Enq_Date DESC
    OFFSET (@PageNumber-1)*@PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport=1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
