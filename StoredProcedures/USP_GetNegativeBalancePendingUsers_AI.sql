USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-13
-- Description: Identifies negative balance users (-ve balance only) in date range, returning ConsumerName,
--              MobileNumber, Company details, negative Balance, and LatestActivityDate.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetNegativeBalancePendingUsers_AI]
(
    @Comp_ID         NVARCHAR(50),
    @DatePreset      NVARCHAR(20) = 'TODAY',   -- TODAY, TOMORROW, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, YEAR, ALL, CUSTOM
    @FromDate        NVARCHAR(30) = NULL,
    @ToDate          NVARCHAR(30) = NULL,
    @Page            INT = 1,
    @Limit           INT = 10,
    @Search          NVARCHAR(100) = NULL,
    @IsExport        BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------------
    -- Date Range
    -----------------------------------------
    DECLARE @StartDate DATETIME,
            @EndDate   DATETIME,
            @Preset    NVARCHAR(20);

    SET @Preset = UPPER(ISNULL(@DatePreset, 'ALL'));

    IF (@Preset = 'TODAY')
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'TOMORROW')
    BEGIN
        SET @StartDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 2, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'YESTERDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
        SET @EndDate   = CAST(GETDATE() AS DATE);
    END
    ELSE IF (@Preset = 'WEEK' OR @Preset = 'THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH' OR @Preset = 'MONTHS')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'YEAR' OR @Preset = 'THIS YEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE
    BEGIN
        SET @StartDate = CAST('2015-01-01 00:00:00.000' AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
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
      AND PET.CheckedDate >= @StartDate
      AND PET.CheckedDate < @EndDate
      AND PET.Comp_ID = @Comp_ID

    UNION ALL

    SELECT
        CT.Comp_id,
        CT.Comp_Name AS CompanyName,
        CT.MobileNo,
        CT.Claim_date AS CheckedDate,
        CT.Amount,
        NULL AS Points,
        'C' AS Source
    FROM Claim_Transaction CT WITH(NOLOCK)
    WHERE CT.Claim_date >= @StartDate
      AND CT.Claim_date < @EndDate
      AND CT.Comp_id = @Comp_ID;

    -----------------------------------------
    -- Summary (Negative Balance Only)
    -----------------------------------------
    IF OBJECT_ID('tempdb..#Summary') IS NOT NULL
        DROP TABLE #Summary;

    SELECT
        T.CompanyName,
        T.MobileNo AS MobileNumber,
        ISNULL(MC.ConsumerName, '') AS ConsumerName,
        SUM(CASE WHEN T.Source='P' THEN ISNULL(T.Points,0) ELSE 0 END) AS EarnedPoints,
        SUM(CASE WHEN T.Source='C' THEN ISNULL(T.Amount,0) ELSE 0 END) AS RedeemPoints,
        SUM(CASE WHEN T.Source='P' THEN ISNULL(T.Points,0) ELSE 0 END)
        -
        SUM(CASE WHEN T.Source='C' THEN ISNULL(T.Amount,0) ELSE 0 END) AS Balance,
        MAX(T.CheckedDate) AS LatestActivityDate
    INTO #Summary
    FROM #Temp T
    LEFT JOIN M_Consumer MC WITH(NOLOCK) ON RIGHT(MC.MobileNo, 10) = RIGHT(T.MobileNo, 10) AND MC.IsDelete = 0
    WHERE
        @Search IS NULL
        OR @Search = ''
        OR T.CompanyName LIKE '%' + @Search + '%'
        OR T.Comp_ID LIKE '%' + @Search + '%'
        OR T.MobileNo LIKE '%' + @Search + '%'
        OR MC.ConsumerName LIKE '%' + @Search + '%'
    GROUP BY
        T.Comp_ID,
        T.CompanyName,
        T.MobileNo,
        MC.ConsumerName
    HAVING
        (SUM(CASE WHEN T.Source='P' THEN ISNULL(T.Points,0) ELSE 0 END)
        - SUM(CASE WHEN T.Source='C' THEN ISNULL(T.Amount,0) ELSE 0 END)) < 0;

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #Summary;

    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY CompanyName, MobileNumber;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY CompanyName, MobileNumber
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        SELECT
            @TotalRecords TotalRecords,
            @Page CurrentPage,
            @Limit [Limit],
            CEILING(@TotalRecords * 1.0 / @Limit) TotalPages;
    END

    DROP TABLE IF EXISTS #Temp;
    DROP TABLE IF EXISTS #Summary;

END
GO
