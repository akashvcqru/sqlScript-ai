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
    @DatePreset NVARCHAR(20) = 'ALL',
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
    DECLARE @StartDate DATETIME,
            @EndDate DATETIME,
            @Preset NVARCHAR(20);

    SET @Preset = UPPER(ISNULL(@DatePreset,'ALL'));

    IF @Preset='TODAY'
    BEGIN
        SET @StartDate=CAST(GETDATE() AS DATE);
        SET @EndDate=DATEADD(DAY,1,@StartDate);
    END
    ELSE IF @Preset='YESTERDAY'
    BEGIN
        SET @StartDate=DATEADD(DAY,-1,CAST(GETDATE() AS DATE));
        SET @EndDate=CAST(GETDATE() AS DATE);
    END
    ELSE IF @Preset IN('WEEK','THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate=DATEADD(DAY,1-DATEPART(WEEKDAY,GETDATE()),CAST(GETDATE() AS DATE));
        SET @EndDate=DATEADD(DAY,1,CAST(GETDATE() AS DATE));
    END
    ELSE IF @Preset='LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate=DATEADD(WEEK,DATEDIFF(WEEK,0,GETDATE())-1,0);
        SET @EndDate=DATEADD(WEEK,DATEDIFF(WEEK,0,GETDATE()),0);
    END
    ELSE IF @Preset IN('MONTH','THIS MONTH')
    BEGIN
        SET @StartDate=DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1);
        SET @EndDate=DATEADD(DAY,1,CAST(GETDATE() AS DATE));
    END
    ELSE IF @Preset='LASTMONTH'
    BEGIN
        SET @StartDate=DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())-1,0);
        SET @EndDate=DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),0);
    END
    ELSE IF @Preset IN('YEAR','THIS YEAR')
    BEGIN
        SET @StartDate=DATEFROMPARTS(YEAR(GETDATE()),1,1);
        SET @EndDate=DATEADD(DAY,1,CAST(GETDATE() AS DATE));
    END
    ELSE IF @Preset='CUSTOM'
    BEGIN
        SET @StartDate=CAST(@FromDate AS DATETIME);
        SET @EndDate=DATEADD(DAY,1,CAST(@ToDate AS DATE));
    END
    ELSE
    BEGIN
        SET @StartDate='2015-01-01';
        SET @EndDate=DATEADD(DAY,1,CAST(GETDATE() AS DATE));
    END

    IF @Page<1 SET @Page=1;
    IF @Limit<1 SET @Limit=10;

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
      AND PET.CheckedDate>=@StartDate
      AND PET.CheckedDate<@EndDate

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
    WHERE CT.Claim_date>=@StartDate
      AND CT.Claim_date<@EndDate;


    -----------------------------------------
    -- Summary
    -----------------------------------------

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
