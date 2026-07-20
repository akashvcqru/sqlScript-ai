USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetUserNegativeBalanceAnalysis_AI]    Script Date: 7/20/2026 4:55:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-13
-- Description: Analyzes a user's lifetime ledger (earnings and redemptions) chronologically and links
--              claims and UPI payouts to identify which redemptions are "fraudulent" (post-transaction
--              running balance < 0) and by how many points. Restored PointsRedeemed column.
-- =========================================================================================================
ALTER   PROCEDURE [dbo].[USP_GetUserNegativeBalanceAnalysis_AI]
(
    @MobileNo NVARCHAR(30),
    @Comp_Id  NVARCHAR(50),
    @DatePreset NVARCHAR(20) = 'ALL',
    @FromDate        NVARCHAR(30) = NULL,
    @ToDate          NVARCHAR(30) = NULL,
    @Page     INT = 1,
    @Limit    INT = 10,
    @Search   NVARCHAR(100) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Comp_Id = 'Comp-1669'
    BEGIN
        SELECT TOP 0
            CAST(NULL AS NVARCHAR(150)) AS CompanyName,
            CAST(NULL AS NVARCHAR(150)) AS ProductName,
            CAST(NULL AS NVARCHAR(50)) AS MobileNo,
            CAST(NULL AS NVARCHAR(150)) AS Code1Code2,
            CAST(NULL AS NVARCHAR(50)) AS ModeOfVerification,
            CAST(0.00 AS DECIMAL(18,2)) AS Amount,
            CAST(0.00 AS DECIMAL(18,2)) AS ClaimRedeemAmount,
            CAST(NULL AS NVARCHAR(50)) AS Status,
            CAST(NULL AS DATETIME) AS CheckedDate,
            CAST(0.00 AS DECIMAL(18,2)) AS RunningBalance,
            CAST(0.00 AS DECIMAL(18,2)) AS ExceededPointsNegative,
            CAST(0 AS INT) AS IsFraudEntry;
        
        SELECT 0 AS TotalRecords, @Page AS CurrentPage, @Limit AS [Limit], 0 AS TotalPages;
        RETURN;
    END

    -- Determine Date Range
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    DECLARE @Preset NVARCHAR(20) = UPPER(ISNULL(@DatePreset, ''));
    IF (@Preset = '' OR @Preset = 'NULL') 
    BEGIN
        IF (@FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
            SET @Preset = 'CUSTOM';
        ELSE
            SET @Preset = 'ALL';
    END

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
    ELSE -- ALL or default fallback
    BEGIN
        SET @StartDate = CAST('2015-01-01 00:00:00.000' AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

	-- Temp Data
    -----------------------------------------
    IF OBJECT_ID('tempdb..#Temp') IS NOT NULL
        DROP TABLE #Temp;

    SELECT
        PET.Comp_ID,
        PET.CompanyName,
        PET.MobileNo,
        PET.CheckedDate,
        
        PET.Points as Amount,
        'Earned' AS Source
    INTO #Temp
    FROM ProEnq_Transactions PET WITH(NOLOCK)
    WHERE PET.TransferedAmount = 0
      AND PET.CheckedDate >= @StartDate
      AND PET.CheckedDate < @EndDate

    UNION ALL

    SELECT
        CT.Comp_id,
        CT.Comp_Name AS CompanyName,
        CT.MobileNo,
        CT.Claim_date AS CheckedDate,
        CT.Amount,
         
        'Claim' AS Source
    FROM Claim_Transaction CT WITH(NOLOCK)
    WHERE CT.Claim_date >= @StartDate
      AND CT.Claim_date < @EndDate;

    -----------------------------------------
    -- Summary (Negative Balance Only)
    -----------------------------------------
    IF OBJECT_ID('tempdb..#Summary') IS NOT NULL
        DROP TABLE #Summary;

    SELECT
        T.Comp_ID AS CompanyId,
        T.CompanyName,
        T.MobileNo AS MobileNumber,
         Points,Source,CheckedDate as date
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
