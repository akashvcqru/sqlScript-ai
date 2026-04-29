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

    IF @datePreset = 'all' BEGIN SET @finalFromDate = @CompanyStartDate; SET @finalToDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE)) END
    ELSE IF @datePreset = 'custom' BEGIN SET @finalFromDate = @FromDate; SET @finalToDate = @ToDate END
    ELSE BEGIN
        DECLARE @today DATE = CAST(GETDATE() AS DATE); SET DATEFIRST 1;
        IF @datePreset = 'today' BEGIN SET @finalFromDate = @today; SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastday' BEGIN SET @finalFromDate = DATEADD(DAY,-1,@today); SET @finalToDate = DATEADD(SECOND,-1,CAST(@today AS DATETIME)) END
        ELSE IF @datePreset = 'week' BEGIN SET @finalFromDate = DATEADD(DAY,1-DATEPART(WEEKDAY,@today),@today); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastweek' BEGIN DECLARE @thisMonday DATE = DATEADD(DAY,1-DATEPART(WEEKDAY,@today),@today); SET @finalFromDate = DATEADD(DAY,-7,@thisMonday); SET @finalToDate = DATEADD(SECOND,-1,CAST(@thisMonday AS DATETIME)) END
        ELSE IF @datePreset = 'month' OR @datePreset = 'last30days' BEGIN SET @finalFromDate = DATEADD(DAY,-30,@today); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastmonth' BEGIN SET @finalFromDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)); SET @finalToDate = DATEADD(SECOND,-1,CAST(DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1) AS DATETIME)) END
        ELSE IF @datePreset = 'quarter' BEGIN SET @finalFromDate = DATEADD(QUARTER,DATEDIFF(QUARTER,0,GETDATE()),0); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'year' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()),1,1); SET @finalToDate = GETDATE() END
        ELSE IF @datePreset = 'lastyear' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE())-1,1,1); SET @finalToDate = DATEFROMPARTS(YEAR(GETDATE())-1,12,31) END
        ELSE BEGIN SET @finalFromDate = DATEADD(DAY,-7,@today); SET @finalToDate = GETDATE() END
    END

    ------------------------------------------------------
    -- Step 1: Pre-filter Pro_Enq (Filtered with Is_Success = 0)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempPro_Enq') IS NOT NULL DROP TABLE #tempPro_Enq;
    SELECT 
        pe.MobileNo, pe.Received_Code1, pe.Received_Code2, pe.Enq_Date, pe.Dial_Mode
    INTO #tempPro_Enq
    FROM Pro_Enq pe
    WHERE pe.Comp_ID = @Comp_ID
      AND pe.Enq_Date >= @CompanyStartDate
      AND pe.Is_Success = 0
      AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
      AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
      AND (@StateFilter IS NULL OR pe.State = @StateFilter)
      AND (@Search IS NULL OR pe.MobileNo LIKE '%'+@Search+'%' OR pe.Received_Code1 LIKE '%'+@Search+'%' OR pe.Received_Code2 LIKE '%'+@Search+'%');

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
GO
