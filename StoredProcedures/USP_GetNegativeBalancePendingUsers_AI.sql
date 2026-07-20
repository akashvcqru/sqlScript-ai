USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-13
-- Description: Identifies negative balance users that had transactions (Claim / UPI) in the past @Days window
--              with optimized Pro_Enq scanning, ordering by Claim_date and ReqDate, pagination,
--              and validation that the user is present in tbl_VendorViseKYCStatus.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetNegativeBalancePendingUsers_AI]
(
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

    -- 1. Determine Date Range for Candidates
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

    -- Ensure page/limit values are valid
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    -- 2. Find Candidates from Negative Balance Transactions
    DROP TABLE IF EXISTS #Candidates;
    SELECT 
        Mobileno AS MobileNo, 
        Comp_id,
        LatestActivityDate
    INTO #Candidates
    FROM (
        SELECT MobileNo AS Mobileno, Comp_ID, MAX(CheckedDate) AS LatestActivityDate
        FROM ProEnq_Transactions WITH (NOLOCK) 
        WHERE TransferedAmount > Points
          AND CheckedDate >= @StartDate AND CheckedDate < @EndDate
        GROUP BY MobileNo, Comp_ID
        UNION ALL
        SELECT Mobileno, Comp_Id, MAX(Claim_date) AS LatestActivityDate
        FROM Claim_Transaction WITH (NOLOCK) 
        WHERE Amount > EarnedPoints
          AND Claim_date >= @StartDate AND Claim_date < @EndDate
        GROUP BY Mobileno, Comp_Id
    ) x
    WHERE ISNULL(Mobileno, '') <> '' AND Comp_id <> 'Comp-1669';

    -- Distinct Candidates
    DROP TABLE IF EXISTS #UniqueCandidates;
    SELECT 
        REPLACE(MobileNo, '+', '') AS MobileNo, 
        Comp_id,
        MAX(LatestActivityDate) AS LatestActivityDate
    INTO #UniqueCandidates
    FROM #Candidates
    GROUP BY REPLACE(MobileNo, '+', ''), Comp_id;

    -- 3. Resolve Consumer IDs & Validate KYC Presence
    DROP TABLE IF EXISTS #Users;
    SELECT 
        C.Comp_Id,
        C.MobileNo,
        C.LatestActivityDate,
        MC.M_ConsumerId,
        MC.ConsumerName,
        CR.Comp_Name AS CompanyName
    INTO #Users
    FROM #UniqueCandidates C
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = C.MobileNo
    INNER JOIN tbl_VendorViseKYCStatus K WITH (NOLOCK) ON K.M_ConsumerId = MC.M_ConsumerId AND K.Comp_Id = C.Comp_Id
    LEFT JOIN Comp_Reg CR WITH (NOLOCK) ON C.Comp_Id = CR.Comp_ID AND CR.Status = 1
    WHERE K.IsDelete = 0
      AND (
          @Search IS NULL OR @Search = ''
          OR C.MobileNo LIKE '%' + @Search + '%'
          OR MC.ConsumerName LIKE '%' + @Search + '%'
          OR CR.Comp_Name LIKE '%' + @Search + '%'
          OR C.Comp_Id LIKE '%' + @Search + '%'
      )

    UNION

    SELECT 
        C.Comp_Id,
        C.MobileNo,
        C.LatestActivityDate,
        MC.M_ConsumerId,
        MC.ConsumerName,
        CR.Comp_Name AS CompanyName
    FROM #UniqueCandidates C
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = '+' + C.MobileNo
    INNER JOIN tbl_VendorViseKYCStatus K WITH (NOLOCK) ON K.M_ConsumerId = MC.M_ConsumerId AND K.Comp_Id = C.Comp_Id
    LEFT JOIN Comp_Reg CR WITH (NOLOCK) ON C.Comp_Id = CR.Comp_ID AND CR.Status = 1
    WHERE K.IsDelete = 0
      AND (
          @Search IS NULL OR @Search = ''
          OR C.MobileNo LIKE '%' + @Search + '%'
          OR MC.ConsumerName LIKE '%' + @Search + '%'
          OR CR.Comp_Name LIKE '%' + @Search + '%'
          OR C.Comp_Id LIKE '%' + @Search + '%'
      );

    CREATE CLUSTERED INDEX IX_Users_ConsumerId ON #Users(M_ConsumerId);
    CREATE INDEX IX_Users_CompUser ON #Users(Comp_Id, MobileNo);

    -- 4. Final output: Combine and filter to those with negative balances
    DROP TABLE IF EXISTS #Summary;
    SELECT
        U.CompanyName,
        U.Comp_Id AS CompanyId,
        U.MobileNo AS MobileNumber,
        U.ConsumerName AS ConsumerName,
        ISNULL(T.Earned, 0) AS TotalPointsEarned,
        ISNULL(T.Redeemed, 0) AS TotalPointsRedeemed,
        (ISNULL(T.Earned, 0) - ISNULL(T.Redeemed, 0)) AS PendingPoints,
        U.LatestActivityDate
    INTO #Summary
    FROM #Users U
    INNER JOIN (
        SELECT Comp_Id, RIGHT(MobileNo, 10) AS CleanMobile, SUM(Earned) AS Earned, SUM(Redeemed) AS Redeemed
        FROM (
            SELECT Comp_ID, MobileNo, CAST(Points AS DECIMAL(18,2)) AS Earned, CAST(TransferedAmount AS DECIMAL(18,2)) AS Redeemed
            FROM ProEnq_Transactions WITH (NOLOCK)
            WHERE TransferedAmount > Points
              AND CheckedDate >= @StartDate AND CheckedDate < @EndDate
            UNION ALL
            SELECT Comp_ID, Mobileno AS MobileNo, CAST(EarnedPoints AS DECIMAL(18,2)) AS Earned, CAST(Amount AS DECIMAL(18,2)) AS Redeemed
            FROM Claim_Transaction WITH (NOLOCK)
            WHERE Amount > EarnedPoints
              AND Claim_date >= @StartDate AND Claim_date < @EndDate
        ) x GROUP BY Comp_Id, RIGHT(MobileNo, 10)
    ) T ON T.Comp_Id = U.Comp_Id AND T.CleanMobile = RIGHT(U.MobileNo, 10);

    -- Return Paginated Output OR Export Output
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #Summary;

    IF @IsExport = 1
    BEGIN
        SELECT
            CompanyName,
            CompanyId,
            MobileNumber,
            ConsumerName,
            TotalPointsEarned,
            TotalPointsRedeemed,
            PendingPoints,
            LatestActivityDate
        FROM #Summary
        ORDER BY LatestActivityDate DESC;
    END
    ELSE
    BEGIN
        SELECT
            CompanyName,
            CompanyId,
            MobileNumber,
            ConsumerName,
            TotalPointsEarned,
            TotalPointsRedeemed,
            PendingPoints,
            LatestActivityDate
        FROM #Summary
        ORDER BY LatestActivityDate DESC
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        -- Meta Pagination Results
        SELECT
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(@TotalRecords * 1.0 / @Limit) AS TotalPages;
    END

    -- Cleanup temp tables
    DROP TABLE IF EXISTS #Candidates, #UniqueCandidates, #Users, #Summary;
END
GO
