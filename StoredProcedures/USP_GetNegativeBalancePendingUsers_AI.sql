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
    @Search          NVARCHAR(100) = NULL
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

    -- 2. Find Candidates with claim/UPI transactions in the last @Days days (or Date Range)
    DROP TABLE IF EXISTS #Candidates;
    SELECT 
        Mobileno, 
        Comp_id,
        LatestActivityDate
    INTO #Candidates
    FROM (
        SELECT Mobileno, Comp_id, MAX(Claim_date) AS LatestActivityDate
        FROM ClaimDetails WITH (NOLOCK) 
        WHERE Claim_date >= @StartDate AND Claim_date < @EndDate
        GROUP BY Mobileno, Comp_id
        UNION ALL
        SELECT Mobileno, Comp_Id, MAX(ReqDate) AS LatestActivityDate
        FROM tblUPITransactionDetails WITH (NOLOCK) 
        WHERE ReqDate >= @StartDate AND ReqDate < @EndDate
        GROUP BY Mobileno, Comp_Id
    ) x
    WHERE ISNULL(Mobileno, '') <> '';

    -- Distinct Candidates
    DROP TABLE IF EXISTS #UniqueCandidates;
    SELECT 
        REPLACE(Mobileno, '+', '') AS MobileNo, 
        Comp_id,
        MAX(LatestActivityDate) AS LatestActivityDate
    INTO #UniqueCandidates
    FROM #Candidates
    GROUP BY REPLACE(Mobileno, '+', ''), Comp_id;

    -- 3. Resolve Consumer IDs & Validate KYC Presence
    DROP TABLE IF EXISTS #Users;
    SELECT DISTINCT
        C.Comp_Id,
        C.MobileNo,
        C.LatestActivityDate,
        MC.M_ConsumerId,
        MC.ConsumerName,
        CR.Comp_Name AS CompanyName
    INTO #Users
    FROM #UniqueCandidates C
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON REPLACE(MC.MobileNo, '+', '') = C.MobileNo
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

    -- 4. Calculate Scan Points (LIFETIME) with Optimized SARGable joins on Pro_Enq MobileNo
    DROP TABLE IF EXISTS #UniqueScans;
    SELECT 
        Comp_Id, MobileNo, M_ConsumerId, M_Codeid, Pro_ID, Series_Order, Series_Serial,
        ROW_NUMBER() OVER (PARTITION BY Received_Code1, Received_Code2, Is_Success ORDER BY Enq_Date) as rn
    INTO #UniqueScans
    FROM (
        SELECT 
            U.Comp_Id,
            U.MobileNo,
            U.M_ConsumerId,
            M.Row_ID AS M_Codeid,
            M.Pro_ID,
            M.Series_Order,
            M.Series_Serial,
            PE.Received_Code1,
            PE.Received_Code2,
            PE.Is_Success,
            PE.Enq_Date
        FROM #Users U
        INNER JOIN Pro_Enq PE WITH (NOLOCK) ON PE.MobileNo = U.MobileNo
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = U.Comp_Id
        WHERE PE.Is_Success = '1'

        UNION ALL

        SELECT 
            U.Comp_Id,
            U.MobileNo,
            U.M_ConsumerId,
            M.Row_ID AS M_Codeid,
            M.Pro_ID,
            M.Series_Order,
            M.Series_Serial,
            PE.Received_Code1,
            PE.Received_Code2,
            PE.Is_Success,
            PE.Enq_Date
        FROM #Users U
        INNER JOIN Pro_Enq PE WITH (NOLOCK) ON PE.MobileNo = '+' + U.MobileNo
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = U.Comp_Id
        WHERE PE.Is_Success = '1'
    ) x;

    CREATE CLUSTERED INDEX IX_UniqueScans_MCodeid ON #UniqueScans(M_Codeid);

    -- Get Earned Points per scan
    DROP TABLE IF EXISTS #EarnedPoints;
    SELECT
        US.Comp_Id,
        US.M_Codeid,
        SUM(Points) AS Points
    INTO #EarnedPoints
    FROM (
        SELECT
            U.Comp_Id,
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(LC.calculation_value, 0.0) / 100.0)
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN #Users U ON BL.compid = U.Comp_Id
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON MC.M_Consumerid = U.M_ConsumerId
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        LEFT JOIN loyalty_calculation LC WITH (NOLOCK) ON LC.comp_id = U.Comp_Id AND LC.isactive = 1 AND LC.isdelete = 0
        
        UNION ALL

        SELECT
            U.Comp_Id,
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(LC.calculation_value, 0.0) / 100.0)
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN #Users U ON U.M_ConsumerId = BL.M_Consumerid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON MC.M_Consumerid = U.M_ConsumerId
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID AND PR.Comp_Id = U.Comp_Id
        LEFT JOIN loyalty_calculation LC WITH (NOLOCK) ON LC.comp_id = U.Comp_Id AND LC.isactive = 1 AND LC.isdelete = 0
        WHERE BL.compid IS NULL
    ) x
    INNER JOIN #UniqueScans US ON US.Comp_Id = x.Comp_Id AND US.M_Codeid = x.M_Codeid AND US.rn = 1
    GROUP BY US.Comp_Id, US.M_Codeid;

    CREATE CLUSTERED INDEX IX_EarnedPoints ON #EarnedPoints(M_Codeid);

    -- Get Configured Points per scan
    DROP TABLE IF EXISTS #ConfigPoints;
    SELECT 
        US.Comp_Id,
        US.M_Codeid,
        MAX(CAST(
            CASE 
                WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                ELSE ISNULL(SST.IsCash, 0) * (1.00 + ISNULL(LC.calculation_value, 0.0) / 100.0)
            END 
        AS DECIMAL(18,2))) AS ConfigPoints
    INTO #ConfigPoints
    FROM #UniqueScans US
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID AND SS.Comp_ID = US.Comp_Id
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    LEFT JOIN loyalty_calculation LC WITH (NOLOCK) ON LC.comp_id = US.Comp_Id AND LC.isactive = 1 AND LC.isdelete = 0
    WHERE US.rn = 1
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
      AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
      AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
    GROUP BY US.Comp_Id, US.M_Codeid;

    CREATE CLUSTERED INDEX IX_ConfigPoints ON #ConfigPoints(M_Codeid);

    DROP TABLE IF EXISTS #Benefit;
    SELECT
        US.Comp_Id,
        US.MobileNo,
        SUM(ISNULL(P.Points, ISNULL(CP.ConfigPoints, 0))) AS BenefitPoints
    INTO #Benefit
    FROM #UniqueScans US
    LEFT JOIN #EarnedPoints P ON P.Comp_Id = US.Comp_Id AND P.M_Codeid = US.M_Codeid
    LEFT JOIN #ConfigPoints CP ON CP.Comp_Id = US.Comp_Id AND CP.M_Codeid = US.M_Codeid
    WHERE US.rn = 1
    GROUP BY US.Comp_Id, US.MobileNo;

    CREATE CLUSTERED INDEX IX_Benefit ON #Benefit(Comp_Id, MobileNo);

    -- 5. Calculate Referral and other rewards (LIFETIME)
    DROP TABLE IF EXISTS #Referrals;
    SELECT 
        U.Comp_Id,
        U.MobileNo,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralAmount
    INTO #Referrals
    FROM #Users U
    INNER JOIN dbo.BLoyaltyPointsEarned BL WITH (NOLOCK) ON BL.M_Consumerid = U.M_ConsumerId AND BL.compid = U.Comp_Id
    WHERE LOWER(BL.ServiceName) IN ('refral', 'referral', 'kycrewards', 'supervisor', 'invoicebenifit', 'invoicerewards')
    GROUP BY U.Comp_Id, U.MobileNo;

    CREATE CLUSTERED INDEX IX_Referrals ON #Referrals(Comp_Id, MobileNo);

    -- 6. Override for Comp-1152 (LIFETIME)
    DROP TABLE IF EXISTS #Earned1152;
    SELECT 
        U.MobileNo,
        SUM(TRY_CAST(points AS DECIMAL(18,2))) AS PointsEarned
    INTO #Earned1152
    FROM #Users U
    INNER JOIN dbo.ConsumerPointsCashDetails CP WITH (NOLOCK) ON CP.MobileNo = U.MobileNo
    WHERE U.Comp_Id = 'Comp-1152'
      AND CP.Enq_Date >= '2022-08-04 00:00:00.000'
      AND CP.Is_Success = 1
    GROUP BY U.MobileNo;

    CREATE CLUSTERED INDEX IX_Earned1152 ON #Earned1152(MobileNo);

    -- Merge all Earning methods
    DROP TABLE IF EXISTS #TotalEarned;
    SELECT 
        U.Comp_Id,
        U.MobileNo,
        CAST(
            CASE 
                WHEN U.Comp_Id = 'Comp-1152' THEN ISNULL(E1152.PointsEarned, 0)
                ELSE ISNULL(B.BenefitPoints, 0) + ISNULL(R.ReferralAmount, 0)
            END 
        AS DECIMAL(18,2)) AS TotalEarnedPoints
    INTO #TotalEarned
    FROM #Users U
    LEFT JOIN #Benefit B ON B.Comp_Id = U.Comp_Id AND B.MobileNo = U.MobileNo
    LEFT JOIN #Referrals R ON R.Comp_Id = U.Comp_Id AND R.MobileNo = U.MobileNo
    LEFT JOIN #Earned1152 E1152 ON E1152.MobileNo = U.MobileNo;

    CREATE CLUSTERED INDEX IX_TotalEarned ON #TotalEarned(Comp_Id, MobileNo);

    -- 7. Redemptions: Claim Payouts (LIFETIME)
    DROP TABLE IF EXISTS #Claims;
    SELECT
        U.Comp_Id,
        U.MobileNo,
        SUM(CD.Amount) AS ClaimsAmount
    INTO #Claims
    FROM #Users U
    INNER JOIN ClaimDetails CD WITH (NOLOCK) ON CD.Comp_id = U.Comp_Id AND CD.Mobileno = U.MobileNo
    WHERE CD.Isapproved = 1
    GROUP BY U.Comp_Id, U.MobileNo;

    CREATE CLUSTERED INDEX IX_Claims ON #Claims(Comp_Id, MobileNo);

    -- 8. Redemptions: UPI Payouts (LIFETIME)
    DROP TABLE IF EXISTS #UPI;
    SELECT
        U.Comp_Id,
        U.MobileNo,
        SUM(ISNULL(UT.Amount, 0)) AS UPIAmount
    INTO #UPI
    FROM #Users U
    INNER JOIN tblUPITransactionDetails UT WITH (NOLOCK) 
        ON UT.Comp_Id = U.Comp_Id 
        AND (UT.M_Consumerid = CAST(U.M_ConsumerId AS VARCHAR(50)) OR REPLACE(UT.Mobileno, '+', '') = U.MobileNo)
    WHERE UT.Status = 'Success'
      AND LEN(ISNULL(UT.Code1, '')) > 1
      AND LEN(ISNULL(UT.Code2, '')) > 6
    GROUP BY U.Comp_Id, U.MobileNo;

    CREATE CLUSTERED INDEX IX_UPI ON #UPI(Comp_Id, MobileNo);

    -- 9. Redemptions: BPoints Redeem (LIFETIME)
    DROP TABLE IF EXISTS #BPoints;
    SELECT
        U.Comp_Id,
        U.MobileNo,
        SUM(ISNULL(BP.RedeemPoints, 0)) AS BPointsAmount
    INTO #BPoints
    FROM #Users U
    INNER JOIN BPointsTransaction BP WITH (NOLOCK) ON BP.companyid = U.Comp_Id AND BP.RedeemBy = U.M_ConsumerId
    WHERE BP.bpstatus IN ('Accepted', 'SUCCESS')
    GROUP BY U.Comp_Id, U.MobileNo;

    CREATE CLUSTERED INDEX IX_BPoints ON #BPoints(Comp_Id, MobileNo);

    -- 10. Redemptions: Legacy Transactions (LIFETIME)
    DROP TABLE IF EXISTS #Transactions;
    SELECT
        U.Comp_Id,
        U.MobileNo,
        SUM(ISNULL(CAST(TR.Amount AS DECIMAL(18,2)), 0)) AS TransactionsAmount
    INTO #Transactions
    FROM #Users U
    INNER JOIN Transactions TR WITH (NOLOCK) ON TR.CompId = REPLACE(U.Comp_Id, 'Comp-', '') AND TR.M_CounserID = CAST(U.M_ConsumerId AS VARCHAR(50))
    WHERE TR.IsSuccess = 1
      AND (U.Comp_Id <> 'Comp-1152' OR TR.TransactionDate > '2022-11-25')
    GROUP BY U.Comp_Id, U.MobileNo;

    CREATE CLUSTERED INDEX IX_Transactions ON #Transactions(Comp_Id, MobileNo);

    -- 11. Final output: Combine and filter to those with negative balances
    DROP TABLE IF EXISTS #Summary;
    SELECT
        U.CompanyName,
        U.Comp_Id AS CompanyId,
        U.MobileNo AS MobileNumber,
        U.ConsumerName AS ConsumerName,
        ISNULL(E.TotalEarnedPoints, 0) AS TotalPointsEarned,
        (ISNULL(C.ClaimsAmount, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsAmount, 0) + ISNULL(TR.TransactionsAmount, 0)) AS TotalPointsRedeemed,
        (ISNULL(E.TotalEarnedPoints, 0) - (ISNULL(C.ClaimsAmount, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsAmount, 0) + ISNULL(TR.TransactionsAmount, 0))) AS PendingPoints,
        U.LatestActivityDate
    INTO #Summary
    FROM #Users U
    LEFT JOIN #TotalEarned E ON E.Comp_Id = U.Comp_Id AND E.MobileNo = U.MobileNo
    LEFT JOIN #Claims C ON C.Comp_Id = U.Comp_Id AND C.MobileNo = U.MobileNo
    LEFT JOIN #UPI UPI ON UPI.Comp_Id = U.Comp_Id AND UPI.MobileNo = U.MobileNo
    LEFT JOIN #BPoints BP ON BP.Comp_Id = U.Comp_Id AND BP.MobileNo = U.MobileNo
    LEFT JOIN #Transactions TR ON TR.Comp_Id = U.Comp_Id AND TR.MobileNo = U.MobileNo
    WHERE (ISNULL(E.TotalEarnedPoints, 0) - (ISNULL(C.ClaimsAmount, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsAmount, 0) + ISNULL(TR.TransactionsAmount, 0))) < 0;

    -- Return Paginated Output
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #Summary;

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

    -- Cleanup temp tables
    DROP TABLE IF EXISTS #Candidates, #UniqueCandidates, #Users, #UniqueScans, #EarnedPoints, #ConfigPoints, #Benefit, #Referrals, #Earned1152, #TotalEarned, #Claims, #UPI, #BPoints, #Transactions, #Summary;
END
GO
