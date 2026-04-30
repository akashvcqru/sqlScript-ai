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
    @datePreset NVARCHAR(20) = 'week',
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

    ------------------------------------------------------
    -- Step 1: Pre-filter Pro_Enq (The largest table)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
    SELECT 
        Received_Code1, 
        Received_Code2, 
        MobileNo, 
        Enq_Date, 
        Is_Success
    INTO #tempPro_Enq
    FROM Pro_Enq
    WHERE Comp_ID = @Comp_ID
      AND Enq_Date >= @CompanyStartDate
      AND (@finalFromDate IS NULL OR Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR Enq_Date < DATEADD(DAY, 1, @finalToDate))
      AND (@DialModeFilter IS NULL OR Dial_Mode = @DialModeFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          (@CodeStatusFilter = 'Verified' AND Is_Success = 1) OR
          (@CodeStatusFilter = 'Already Scanned' AND Is_Success = 2) OR
          (@CodeStatusFilter = 'Invalid' AND Is_Success NOT IN (1, 2))
      );

    CREATE INDEX IX_tempPro_Enq_Codes ON #tempPro_Enq(Received_Code1, Received_Code2);
    CREATE INDEX IX_tempPro_Enq_Mobile ON #tempPro_Enq(MobileNo);

    ------------------------------------------------------
    -- Step 2: Pre-filter M_Code
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    SELECT 
        a.Code1, 
        a.Code2, 
        a.Pro_ID
    INTO #tempM_Code 
    FROM M_Code a 
    INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
    WHERE b.Comp_ID = @Comp_ID
      AND a.Print_Date >= @CompanyStartDate;

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);

    ------------------------------------------------------
    -- Step 3: Service Subscriptions
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_ServiceSubscription') IS NOT NULL DROP TABLE #tempM_ServiceSubscription;
    SELECT Pro_ID, Service_ID 
    INTO #tempM_ServiceSubscription 
    FROM M_ServiceSubscription 
    WHERE Comp_ID = @Comp_ID

    CREATE INDEX IX_tempM_ServiceSub_Pro ON #tempM_ServiceSubscription(Pro_ID);

    ------------------------------------------------------
    -- Main Query (Using optimized temp tables)
    ------------------------------------------------------
    SELECT 
        ROW_NUMBER() OVER (ORDER BY mc.MobileNo) AS SNo,
        mc.MobileNo,
        mc.State,
        mc.City,
        mc.Email,
        ISNULL(mc.ConsumerName, '') AS ConsumerName,
        COUNT(pe.Received_Code1) AS TotalCodeScanned,
        SUM(CASE WHEN pe.Is_Success = 1 THEN 1 ELSE 0 END) AS SuccessfulCodeScanned,
        SUM(CASE WHEN pe.Is_Success = 0 THEN 1 ELSE 0 END) AS UnsuccessfulCodeScanned,
        MIN(pe.Enq_Date) AS FirstScannedDate,
        MAX(pe.Enq_Date) AS LastScannedDate,
        mc.PinCode AS PostCode,
        COUNT(*) OVER() AS TotalRecords
    FROM #tempPro_Enq pe
    INNER JOIN M_Consumer mc ON pe.MobileNo = mc.MobileNo
    INNER JOIN #tempM_Code mc_tbl ON mc_tbl.Code1 = pe.Received_Code1 AND mc_tbl.Code2 = pe.Received_Code2
   -- INNER JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc_tbl.Pro_ID 
        --AND CONCAT(FORMAT(mc_tbl.Series_Order, '000#'), FORMAT(mc_tbl.Series_Serial, '000#')) 
        --    BETWEEN CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#')) 
        --        AND CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
    WHERE (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
    GROUP BY mc.MobileNo, mc.State, mc.City, mc.Email, mc.PinCode, mc.ConsumerName
    ORDER BY mc.MobileNo
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
GO
