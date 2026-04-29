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
    @ServiceID NVARCHAR(50) = NULL,
    @IsExport BIT = 0,
    @Search NVARCHAR(100) = NULL,
    @StateFilter NVARCHAR(100) = NULL,
    @KYCStatusFilter NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @PageNumber IS NULL OR @PageNumber <= 0 SET @PageNumber = 1;
    IF @PageSize IS NULL OR @PageSize <= 0 SET @PageSize = 10;

    -- Normalize search/filter
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' SET @StateFilter = NULL;

    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01')
    FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1;

    DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
    IF (@datePreset IS NULL OR LTRIM(RTRIM(@datePreset)) = '' OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null')
        SET @datePreset = 'week'
    ELSE
        SET @datePreset = LOWER(LTRIM(RTRIM(@datePreset)));

    -- Date logic (keeping consistent)
    IF @datePreset = 'all' BEGIN SET @finalFromDate = @CompanyStartDate; SET @finalToDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE)) END
    ELSE IF @datePreset = 'custom' BEGIN SET @finalFromDate = @FromDate; SET @finalToDate = @ToDate END
    ELSE BEGIN
        DECLARE @today DATE = CAST(GETDATE() AS DATE); SET DATEFIRST 1;
        IF @datePreset = 'today' BEGIN SET @finalFromDate = @today; SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastday' BEGIN SET @finalFromDate = DATEADD(DAY, -1, @today); SET @finalToDate = DATEADD(SECOND, -1, CAST(@today AS DATETIME)) END
        ELSE IF @datePreset = 'week' BEGIN SET @finalFromDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastweek' BEGIN DECLARE @thisMonday DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalFromDate = DATEADD(DAY, -7, @thisMonday); SET @finalToDate = DATEADD(SECOND, -1, CAST(@thisMonday AS DATETIME)) END
        ELSE IF @datePreset = 'month' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastmonth' BEGIN SET @finalFromDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)); SET @finalToDate = DATEADD(SECOND, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME)) END
        ELSE IF @datePreset = 'quarter' BEGIN SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'year' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastyear' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1); SET @finalToDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31) END
        ELSE BEGIN SET @finalFromDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @today), @today); SET @finalToDate = GETDATE() END
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
      AND (@finalToDate IS NULL OR Enq_Date < DATEADD(DAY, 1, @finalToDate));

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
      AND (@ServiceID IS NULL OR Service_ID = @ServiceID);

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
    INNER JOIN #tempM_ServiceSubscription sd ON sd.Pro_ID = mc_tbl.Pro_ID 
    WHERE (@StateFilter IS NULL OR mc.State = @StateFilter)
      AND (@Search IS NULL OR mc.MobileNo LIKE '%' + @Search + '%' 
           OR mc.Email LIKE '%' + @Search + '%'
           OR mc.ConsumerName LIKE '%' + @Search + '%')
    GROUP BY mc.MobileNo, mc.State, mc.City, mc.Email, mc.ConsumerName, mc.PinCode
    ORDER BY mc.MobileNo
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
GO
