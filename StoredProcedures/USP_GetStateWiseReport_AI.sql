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
    @datePreset NVARCHAR(20) = 'week',
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @IsExport BIT = 0,
    @Search NVARCHAR(100) = NULL,
    @StateFilter NVARCHAR(100) = NULL,
    @KYCStatusFilter NVARCHAR(50) = NULL,
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

    DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
    IF (@datePreset IS NULL OR LTRIM(RTRIM(@datePreset)) = '' OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null')
        SET @datePreset = 'week'
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @today DATE = CAST(GETDATE() AS DATE); SET DATEFIRST 1;
    IF @datePreset = 'ALL' BEGIN SET @finalFromDate = @CompanyStartDate; SET @finalToDate = @today END
    ELSE IF @datePreset = 'CUSTOM' BEGIN SET @finalFromDate = @FromDate; SET @finalToDate = @ToDate END
    ELSE BEGIN
        IF @datePreset = 'TODAY' BEGIN SET @finalFromDate = @today; SET @finalToDate = @today END
        ELSE IF @datePreset = 'YESTERDAY' OR @datePreset = 'LASTDAY' BEGIN SET @finalFromDate = DATEADD(DAY,-1,@today); SET @finalToDate = DATEADD(DAY,-1,@today) END
        ELSE IF @datePreset = 'WEEK' BEGIN SET @finalFromDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalToDate = @today END
        ELSE IF @datePreset = 'LASTWEEK' BEGIN DECLARE @thisMonday DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalFromDate = DATEADD(DAY,-7,@thisMonday); SET @finalToDate = DATEADD(DAY, -1, @thisMonday) END
        ELSE IF @datePreset = 'MONTH' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1); SET @finalToDate = @today END
        ELSE IF @datePreset = 'LASTMONTH' BEGIN SET @finalFromDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)); SET @finalToDate = DATEADD(DAY, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) END
        ELSE IF @datePreset = 'QUARTER' BEGIN SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0); SET @finalToDate = DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0)) END
        ELSE IF @datePreset = 'YEAR' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1); SET @finalToDate = @today END
        ELSE IF @datePreset = 'LASTYEAR' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1); SET @finalToDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31) END
        ELSE BEGIN SET @finalFromDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalToDate = @today END
    END

    ------------------------------------------------------
    -- Step 1: Pre-filter Pro_Enq
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
    SELECT 
        pe.State, pe.City, pe.MobileNo, pe.Is_Success, pe.Enq_Date, pe.Received_Code1, pe.Received_Code2
    INTO #tempPro_Enq
    FROM Pro_Enq pe
    WHERE pe.Comp_ID = @Comp_ID
      AND pe.Enq_Date >= @CompanyStartDate
      AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
      AND (@StateFilter IS NULL OR pe.State = @StateFilter)
      AND (@DialModeFilter IS NULL OR pe.Dial_Mode = @DialModeFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          (@CodeStatusFilter = 'Verified' AND pe.Is_Success = 1) OR
          (@CodeStatusFilter = 'Already Scanned' AND pe.Is_Success = 2) OR
          (@CodeStatusFilter = 'Invalid' AND pe.Is_Success NOT IN (1, 2))
      );

    CREATE INDEX IX_tempPro_Enq_Codes ON #tempPro_Enq(Received_Code1, Received_Code2);
    CREATE INDEX IX_tempPro_Enq_Mobile ON #tempPro_Enq(MobileNo);

    ------------------------------------------------------
    -- Step 2: Pre-filter M_Code
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    SELECT a.Code1, a.Code2 INTO #tempM_Code FROM M_Code a 
    INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
    WHERE b.Comp_ID = @Comp_ID AND a.Print_Date >= @CompanyStartDate;

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);

    ------------------------------------------------------
    -- Main Query
    ------------------------------------------------------
    ;WITH RawData AS (
        SELECT 
            pe.State, pe.City, mc.PinCode AS PostCode, pe.MobileNo, mc.IsActive, mc.Entry_Date AS ConsumerEntryDate, pe.Is_Success, pe.Enq_Date,
            CASE WHEN m.Code1 IS NOT NULL THEN 1 ELSE 0 END AS CodeExists
        FROM #tempPro_Enq pe
        LEFT JOIN M_Consumer mc ON pe.MobileNo = mc.MobileNo
        LEFT JOIN #tempM_Code m ON pe.Received_Code1 = m.Code1 AND pe.Received_Code2 = m.Code2
        WHERE (@Search IS NULL OR pe.State LIKE '%'+@Search+'%' OR pe.City LIKE '%'+@Search+'%' OR mc.PinCode LIKE '%'+@Search+'%')
    ),
    LocationGroups AS (
        SELECT 
            State, City, PostCode,
            COUNT(DISTINCT CASE WHEN IsActive = 1 THEN MobileNo END) AS ActiveConsumers,
            COUNT(DISTINCT CASE WHEN ConsumerEntryDate >= @finalFromDate AND ConsumerEntryDate < DATEADD(DAY, 1, @finalToDate) THEN MobileNo END) AS NewConsumers,
            COUNT(DISTINCT CASE WHEN ConsumerEntryDate < @finalFromDate THEN MobileNo END) AS ReturningConsumers,
            COUNT(*) AS TotalScans,
            SUM(CASE WHEN Is_Success = 1 THEN 1 ELSE 0 END) AS GenuineScans,
            SUM(CASE WHEN Is_Success = 0 AND CodeExists = 1 THEN 1 ELSE 0 END) AS DuplicateScans,
            SUM(CASE WHEN Is_Success = 0 AND CodeExists = 0 THEN 1 ELSE 0 END) AS CounterfeitScans,
            CAST(CAST(COUNT(*) AS DECIMAL(18,2)) / NULLIF(COUNT(DISTINCT MobileNo), 0) AS DECIMAL(18,2)) AS AvgScansPerConsumer
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
