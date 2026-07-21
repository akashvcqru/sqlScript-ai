USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-20
-- Description: Retrieves summary of company points and claim amounts, filtering by date preset, custom date range,
--              search term, and handling pagination or full export data.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCompanyPointsClaimSummary_AI]
(
    @DatePreset NVARCHAR(50) = 'ALL',
    @FromDate NVARCHAR(30) = NULL,
    @ToDate NVARCHAR(30) = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------------
    -- Date Range
    -----------------------------------------
    DECLARE @StartDate DATETIME = NULL,
            @EndDate   DATETIME = NULL,
            @Preset    NVARCHAR(50);

    IF @FromDate IS NOT NULL AND LTRIM(RTRIM(@FromDate)) <> '' 
       AND @ToDate IS NOT NULL AND LTRIM(RTRIM(@ToDate)) <> ''
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
    BEGIN
        SET @Preset = UPPER(LTRIM(RTRIM(@DatePreset)));

        IF @Preset = 'TODAY'
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('YESTERDAY', 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF @Preset IN ('WEEK', 'THIS WEEK', 'THISWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTWEEK', 'LAST WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('MONTH', 'THIS MONTH', 'THISMONTH', 'MONTHS')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTMONTH', 'LAST MONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('QUARTER', 'THIS QUARTER', 'THISQUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTQUARTER', 'LAST QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('YEAR', 'THIS YEAR', 'THISYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTYEAR', 'LAST YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF @Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> ''
        BEGIN
            SET @StartDate = CAST(@FromDate AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
        END
        ELSE IF @Preset IN ('ALL', 'NULL')
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    -----------------------------------------
    -- Temp Data
    -----------------------------------------

    IF OBJECT_ID('tempdb..#Temp') IS NOT NULL
        DROP TABLE #Temp;

    SELECT
        PET.Comp_ID,
        PET.CompanyName,
        PET.MobileNo,
        PET.CheckedDate,
        PET.TransferedAmount AS Amount,
        PET.Points,
        'P' AS Source
    INTO #Temp
    FROM ProEnq_Transactions PET WITH(NOLOCK)
    WHERE PET.TransferedAmount = 0
      AND (@StartDate IS NULL OR PET.CheckedDate >= @StartDate)
      AND (@EndDate IS NULL OR PET.CheckedDate < @EndDate)

    UNION ALL

    SELECT
        CT.Comp_id,
        CT.Comp_Name,
        CT.MobileNo,
        CT.Claim_date,
        CT.Amount,
        NULL,
        'C'
    FROM Claim_Transaction CT WITH(NOLOCK)
    WHERE (@StartDate IS NULL OR CT.Claim_date >= @StartDate)
      AND (@EndDate IS NULL OR CT.Claim_date < @EndDate);


    -----------------------------------------
    -- Summary
    -----------------------------------------

    IF OBJECT_ID('tempdb..#Summary') IS NOT NULL
        DROP TABLE #Summary;

    SELECT
        Comp_ID,
        CompanyName,
        COUNT(DISTINCT MobileNo) AS TotalUsers,
        SUM(CASE WHEN Source='P' THEN ISNULL(Points,0) ELSE 0 END) TotalPoints,
        SUM(CASE WHEN Source='C' THEN ISNULL(Amount,0) ELSE 0 END) TotalClaimAmount,
        SUM(CASE WHEN Source='P' THEN ISNULL(Points,0) ELSE 0 END)
        -
        SUM(CASE WHEN Source='C' THEN ISNULL(Amount,0) ELSE 0 END) Balance
    INTO #Summary
    FROM #Temp
    WHERE
        @Search IS NULL
        OR @Search=''
        OR CompanyName LIKE '%'+@Search+'%'
        OR Comp_ID LIKE '%'+@Search+'%'
    GROUP BY
        Comp_ID,
        CompanyName
	HAVING
        SUM(CASE WHEN Source='P' THEN ISNULL(Points,0) ELSE 0 END)
        - SUM(CASE WHEN Source='C' THEN ISNULL(Amount,0) ELSE 0 END) < 0;

    DECLARE @TotalRecords INT;

    SELECT @TotalRecords=COUNT(*) FROM #Summary;

    IF @IsExport=1
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY CompanyName;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY CompanyName
        OFFSET (@Page-1)*@Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        SELECT
            @TotalRecords TotalRecords,
            @Page CurrentPage,
            @Limit [Limit],
            CEILING(@TotalRecords*1.0/@Limit) TotalPages;
    END

    DROP TABLE IF EXISTS #Temp;
    DROP TABLE IF EXISTS #Summary;

END
GO

