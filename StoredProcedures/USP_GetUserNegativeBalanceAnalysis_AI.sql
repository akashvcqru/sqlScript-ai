USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-20
-- Description: Detailed negative balance analysis transactions (Earned vs Claim) for a specific user and company.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetUserNegativeBalanceAnalysis_AI]
(
    @MobileNo   NVARCHAR(30),
    @Comp_Id    NVARCHAR(50),
    @DatePreset NVARCHAR(20) = 'ALL',
    @FromDate   NVARCHAR(30) = NULL,
    @ToDate     NVARCHAR(30) = NULL,
    @Page       INT = 1,
    @Limit      INT = 10,
    @Search     NVARCHAR(100) = NULL,
    @IsExport   BIT = 0
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

    DECLARE @CleanMobile NVARCHAR(30) = REPLACE(@MobileNo, '+', '');
    DECLARE @Last10Mobile NVARCHAR(10) = RIGHT(@CleanMobile, 10);

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
        CAST(PET.Points AS DECIMAL(18,2)) AS Amount,
        'Earned' AS Source,
        CASE WHEN PET.Code1Code2 IS NOT NULL AND PET.Code1Code2 <> '' THEN PET.Code1Code2 ELSE 'NA' END AS Code1Code2,
        CASE WHEN PET.Code1Code2 IS NOT NULL AND PET.Code1Code2 <> '' THEN ISNULL(NULLIF(PET.ProductName, ''), 'NA') ELSE 'NA' END AS ProductName,
        CASE WHEN PET.Code1Code2 IS NOT NULL AND PET.Code1Code2 <> '' THEN ISNULL(NULLIF(PET.ModeOfVerification, ''), 'NA') ELSE 'NA' END AS ModeOfVerification,
        CASE WHEN PET.Code1Code2 IS NOT NULL AND PET.Code1Code2 <> '' THEN ISNULL(NULLIF(PET.IsSuccess, ''), 'NA') ELSE 'NA' END AS IsSuccess
    INTO #Temp
    FROM ProEnq_Transactions PET WITH(NOLOCK)
    WHERE PET.TransferedAmount = 0
      AND PET.CheckedDate >= @StartDate
      AND PET.CheckedDate < @EndDate
      AND (@Comp_Id IS NULL OR @Comp_Id = '' OR PET.Comp_ID = @Comp_Id)
      AND (PET.MobileNo IN (@CleanMobile, '+' + @CleanMobile, '91' + @CleanMobile, '+91' + @CleanMobile) OR RIGHT(PET.MobileNo, 10) = @Last10Mobile)

    UNION ALL

    SELECT
        CT.Comp_id,
        CT.Comp_Name AS CompanyName,
        CT.MobileNo,
        CT.Claim_date AS CheckedDate,
        CAST(CT.Amount AS DECIMAL(18,2)) AS Amount,
        'Claim' AS Source,
        'NA' AS Code1Code2,
        'NA' AS ProductName,
        'NA' AS ModeOfVerification,
        'NA' AS IsSuccess
    FROM Claim_Transaction CT WITH(NOLOCK)
    WHERE CT.Claim_date >= @StartDate
      AND CT.Claim_date < @EndDate
      AND (@Comp_Id IS NULL OR @Comp_Id = '' OR CT.Comp_id = @Comp_Id)
      AND (CT.MobileNo IN (@CleanMobile, '+' + @CleanMobile, '91' + @CleanMobile, '+91' + @CleanMobile) OR RIGHT(CT.MobileNo, 10) = @Last10Mobile);

    -----------------------------------------
    -- Summary
    -----------------------------------------
    IF OBJECT_ID('tempdb..#Summary') IS NOT NULL
        DROP TABLE #Summary;

    SELECT
        T.MobileNo AS MobileNumber,
        ISNULL(MC.ConsumerName, '') AS ConsumerName,
        T.Code1Code2,
        T.ProductName,
        T.ModeOfVerification,
        T.IsSuccess,
        T.Amount,
        T.Source,
        T.CheckedDate AS [Date],
        T.CheckedDate
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
        OR T.Source LIKE '%' + @Search + '%'
        OR T.Code1Code2 LIKE '%' + @Search + '%'
        OR T.ProductName LIKE '%' + @Search + '%'
        OR T.ModeOfVerification LIKE '%' + @Search + '%'
        OR T.IsSuccess LIKE '%' + @Search + '%';

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #Summary;

    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY [Date] DESC;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY [Date] DESC
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
