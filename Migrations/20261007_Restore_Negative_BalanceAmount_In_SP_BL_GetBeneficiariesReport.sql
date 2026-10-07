USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- Migration: 20261007_Restore_Negative_BalanceAmount_In_SP_BL_GetBeneficiariesReport.sql
-- Date: 2026-10-07
-- Purpose:
--   Restore negative BalanceAmount calculation in SP_BL_GetBeneficiariesReport
--   and SP_BL_GetBeneficiariesReport_Admin_AI so that:
--     BalanceAmount = (PointsEarned + RefralAmount) - RedeemAmount
--   When RedeemAmount > PointsEarned, negative balance (e.g. -279.00) is shown
--   instead of being clamped to 0.00.
-- Applied to:
--   - [dbo].[SP_BL_GetBeneficiariesReport]
--   - [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]
-- ============================================================================

PRINT 'Updating [dbo].[SP_BL_GetBeneficiariesReport]...';
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport]
(
    @Comp_Id         NVARCHAR(50),  
    @datePreset      NVARCHAR(20) = NULL,   -- TODAY, WEEK, LASTWEEK, MONTH, QUARTER, ALL
    @FromDate        DATE = NULL,
    @ToDate          DATE = NULL, 
    @KYCStatusFilter NVARCHAR(20) = NULL,   -- Approved / Rejected / Pending
    @StateFilter     NVARCHAR(100) = NULL,
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL,
    @Search          NVARCHAR(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- DEFAULT PAGINATION
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- COMPANY FILTER PREPARATION (UNLINKED)
    ---------------------------------------------------------
    DECLARE @CompanyList TABLE (Comp_Id VARCHAR(50) PRIMARY KEY);
    INSERT INTO @CompanyList VALUES (@Comp_Id);

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation WITH (NOLOCK)
    WHERE comp_id = @Comp_Id;

    ---------------------------------------------------------
    -- DATE RANGE CALCULATION
    ---------------------------------------------------------
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate DATETIME = NULL;

    IF @datePreset IS NOT NULL AND @datePreset <> ''
    BEGIN
        SET @datePreset = UPPER(@datePreset);
        IF @datePreset = 'TODAY'
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate = DATEADD(DAY, 1, @StartDate);
        END
        ELSE IF @datePreset = 'WEEK'
        BEGIN
            SET @StartDate = DATEADD(DAY, -(DATEPART(WEEKDAY, @Today) - 1), CAST(@Today AS DATETIME));
            SET @EndDate = DATEADD(DAY, 7, @StartDate);
        END
        ELSE IF @datePreset = 'LASTWEEK'
        BEGIN
            SET @StartDate = DATEADD(DAY, -(DATEPART(WEEKDAY, @Today) + 6), CAST(@Today AS DATETIME));
            SET @EndDate = DATEADD(DAY, 7, @StartDate);
        END
        ELSE IF @datePreset = 'MONTH'
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DAY(@Today), CAST(@Today AS DATETIME));
            SET @EndDate = DATEADD(MONTH, 1, @StartDate);
        END
        ELSE IF @datePreset = 'QUARTER'
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Today), 0);
            SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
        END
        ELSE IF @datePreset = 'YEAR'
        BEGIN
            SET @StartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, @Today), 0);
            SET @EndDate = DATEADD(YEAR, 1, @StartDate);
        END
        ELSE IF @datePreset = 'ALL'
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate = NULL;
        END
    END
    ELSE IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END

    ---------------------------------------------------------
    -- TEMP TABLES DEFINITION
    ---------------------------------------------------------
    CREATE TABLE #ConsumerMapping (
        M_ConsumerId INT PRIMARY KEY,
        Active_ConsumerId INT
    );

    CREATE TABLE #Users (
        M_ConsumerId INT PRIMARY KEY,
        ConsumerName NVARCHAR(250),
        MobileNo NVARCHAR(50),
        City NVARCHAR(100),
        State NVARCHAR(100),
        PinCode NVARCHAR(20),
        KYCStatus NVARCHAR(50)
    );

    CREATE TABLE #Benefit (
        M_ConsumerId INT PRIMARY KEY,
        PointsEarned DECIMAL(18,2),
        LastScan DATETIME
    );

    CREATE TABLE #OtherEarnedPoints (
        M_ConsumerId INT PRIMARY KEY,
        OtherPoints DECIMAL(18,2)
    );

    CREATE TABLE #Referrals (
        M_ConsumerId INT PRIMARY KEY,
        RefralAmount DECIMAL(18,2)
    );

    CREATE TABLE #Claims (
        M_ConsumerId INT PRIMARY KEY,
        ClaimRedeem DECIMAL(18,2)
    );

    CREATE TABLE #UPI (
        M_ConsumerId INT PRIMARY KEY,
        UPIRedeem DECIMAL(18,2)
    );

    CREATE TABLE #BPoints (
        M_ConsumerId INT PRIMARY KEY,
        BPointsDebited DECIMAL(18,2)
    );

    CREATE TABLE #Transactions (
        M_ConsumerId INT PRIMARY KEY,
        TransactionsAmount DECIMAL(18,2)
    );

    CREATE TABLE #Paytm (
        M_ConsumerId INT PRIMARY KEY,
        PaytmAmount DECIMAL(18,2)
    );

    CREATE TABLE #State (
        M_ConsumerId INT PRIMARY KEY,
        State NVARCHAR(100),
        City NVARCHAR(100)
    );

    ---------------------------------------------------------
    -- 0. CONSUMER MAPPING & USERS FILTERING
    ---------------------------------------------------------
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
    BEGIN
        SET @Search = LTRIM(RTRIM(@Search));
        INSERT INTO #ConsumerMapping (M_ConsumerId, Active_ConsumerId)
        SELECT 
            M_Consumerid,
            COALESCE(Active_Consumerid, M_Consumerid)
        FROM M_Consumer WITH (NOLOCK)
        WHERE (User_ID = @Search OR MobileNo = @Search OR ConsumerName LIKE '%' + @Search + '%');
    END
    ELSE
    BEGIN
        INSERT INTO #ConsumerMapping (M_ConsumerId, Active_ConsumerId)
        SELECT 
            M_Consumerid,
            COALESCE(Active_Consumerid, M_Consumerid)
        FROM M_Consumer WITH (NOLOCK)
        WHERE (IsDelete = 0 OR IsDelete IS NULL);
    END

    INSERT INTO #Users (M_ConsumerId, ConsumerName, MobileNo, City, State, PinCode, KYCStatus)
    SELECT 
        c.M_Consumerid,
        c.ConsumerName,
        RIGHT(RTRIM(c.MobileNo), 10) AS MobileNo,
        c.City,
        c.State,
        c.PinCode,
        CASE 
            WHEN k.Status = 1 THEN 'Approved'
            WHEN k.Status = 2 THEN 'Rejected'
            ELSE 'Pending'
        END AS KYCStatus
    FROM M_Consumer c WITH (NOLOCK)
    LEFT JOIN Kyc_status k WITH (NOLOCK) ON c.M_Consumerid = k.M_Consumerid
    WHERE c.M_Consumerid IN (SELECT DISTINCT Active_ConsumerId FROM #ConsumerMapping)
      AND (c.IsDelete = 0 OR c.IsDelete IS NULL);

    ---------------------------------------------------------
    -- 1. BENEFITS (POINTS EARNED)
    ---------------------------------------------------------
    IF @Comp_Id = 'Comp-1669'
    BEGIN
        INSERT INTO #Benefit (M_ConsumerId, PointsEarned, LastScan)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            SUM(ISNULL(p.Cash, 0.00)) AS PointsEarned,
            MAX(p.Entry_Date) AS LastScan
        FROM Pro_Reg p WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON p.M_Consumerid = CM.M_ConsumerId
        WHERE p.Comp_ID = 'Comp-1669'
          AND (@StartDate IS NULL OR p.Entry_Date >= @StartDate)
          AND (@EndDate   IS NULL OR p.Entry_Date <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END
    ELSE
    BEGIN
        INSERT INTO #Benefit (M_ConsumerId, PointsEarned, LastScan)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            ROUND(SUM(ISNULL(TRY_CAST(b.PointsEarned AS DECIMAL(18,2)), 0.00)) * @Multiplier, 2) AS PointsEarned,
            MAX(b.EntryDate) AS LastScan
        FROM BLoyaltyPointsEarned b WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON b.ConsumerId = CM.M_ConsumerId
        WHERE (b.compid = @Comp_Id OR (b.compid IS NULL AND EXISTS (
            SELECT 1 FROM M_Consumer_M_Code mc WITH (NOLOCK)
            INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.M_Code = pr.M_Code
            WHERE mc.M_Consumerid = b.ConsumerId
              AND pr.Comp_ID = @Comp_Id
        )))
          AND (@StartDate IS NULL OR b.EntryDate >= @StartDate)
          AND (@EndDate   IS NULL OR b.EntryDate <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END

    ---------------------------------------------------------
    -- 2. STATE OVERRIDES
    ---------------------------------------------------------
    INSERT INTO #State (M_ConsumerId, State, City)
    SELECT 
        CM.Active_ConsumerId,
        S.State_Name,
        C.City_Name
    FROM (
        SELECT 
            mc.M_Consumerid,
            mc.State_Id,
            mc.City_Id,
            ROW_NUMBER() OVER (PARTITION BY CM.Active_ConsumerId ORDER BY mc.M_Consumerid DESC) as rn
        FROM M_Consumer mc WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON mc.M_Consumerid = CM.M_ConsumerId
        WHERE mc.State_Id IS NOT NULL
    ) RankedConsumers
    LEFT JOIN State_Master S WITH (NOLOCK) ON RankedConsumers.State_Id = S.State_Id
    LEFT JOIN City_Master C WITH (NOLOCK) ON RankedConsumers.City_Id = C.City_Id
    INNER JOIN #ConsumerMapping CM ON RankedConsumers.M_Consumerid = CM.M_ConsumerId
    WHERE RankedConsumers.rn = 1;

    ---------------------------------------------------------
    -- 3. OTHER EARNED POINTS
    ---------------------------------------------------------
    INSERT INTO #OtherEarnedPoints (M_ConsumerId, OtherPoints)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        ROUND(SUM(ISNULL(TRY_CAST(points AS DECIMAL(18,2)), 0.00)) * @Multiplier, 2) AS OtherPoints
    FROM Other_Earned_Point o WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON o.Consumer_id = CM.M_ConsumerId
    WHERE o.Comp_Id = @Comp_Id
      AND (@StartDate IS NULL OR o.Entry_Date >= @StartDate)
      AND (@EndDate   IS NULL OR o.Entry_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 4. REFERRALS
    ---------------------------------------------------------
    INSERT INTO #Referrals (M_ConsumerId, RefralAmount)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        ROUND(SUM(ISNULL(TRY_CAST(r.Amount AS DECIMAL(18,2)), 0.00)) * @Multiplier, 2) AS RefralAmount
    FROM Referral_History r WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON r.User_Id = CM.M_ConsumerId
    WHERE r.Comp_Id = @Comp_Id
      AND (@StartDate IS NULL OR r.Entry_Date >= @StartDate)
      AND (@EndDate   IS NULL OR r.Entry_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 5. CLAIMS REDEEM
    ---------------------------------------------------------
    INSERT INTO #Claims (M_ConsumerId, ClaimRedeem)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(cd.Points, 0.00)) AS ClaimRedeem
    FROM Claim_Details cd WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON cd.Consumer_ID = CM.M_ConsumerId
    WHERE cd.Comp_ID = @Comp_Id
      AND cd.Status = 1
      AND cd.IsSuccess = 1
      AND (@StartDate IS NULL OR cd.Claim_Date >= @StartDate)
      AND (@EndDate   IS NULL OR cd.Claim_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 6. UPI REDEEM
    ---------------------------------------------------------
    INSERT INTO #UPI (M_ConsumerId, UPIRedeem)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(TRY_CAST(u.Amount AS DECIMAL(18,2)), 0.00)) AS UPIRedeem
    FROM Upi_PaymentTransaction u WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON u.M_Consumerid = CM.M_ConsumerId
    WHERE u.Comp_Id = @Comp_Id
      AND u.Status IN ('Success', 'SUCCESS', 'ACCEPTED')
      AND u.IsCode1 = 1
      AND (@StartDate IS NULL OR u.Payment_Date >= @StartDate)
      AND (@EndDate   IS NULL OR u.Payment_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 7. BPOINTS DEBITED
    ---------------------------------------------------------
    INSERT INTO #BPoints (M_ConsumerId, BPointsDebited)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(bp.PointsDebited, 0.00)) AS BPointsDebited
    FROM BPointsRedeemed bp WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON bp.ConsumerId = CM.M_ConsumerId
    WHERE bp.compid = @Comp_Id
      AND bp.IsRedeemed = 1
      AND bp.PointsDebited > 0
      AND (@StartDate IS NULL OR bp.EntryDate >= @StartDate)
      AND (@EndDate   IS NULL OR bp.EntryDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 8. TRANSACTIONS
    ---------------------------------------------------------
    INSERT INTO #Transactions (M_ConsumerId, TransactionsAmount)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(TRY_CAST(t.Amount AS DECIMAL(18,2)), 0.00)) AS TransactionsAmount
    FROM Transactions t WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON t.M_Consumerid = CM.M_ConsumerId
    WHERE t.Comp_Id = @Comp_Id
      AND t.Remarks = 'Vcqru'
      AND (@StartDate IS NULL OR t.EntryDate >= @StartDate)
      AND (@EndDate   IS NULL OR t.EntryDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 9. PAYTM
    ---------------------------------------------------------
    IF @Comp_Id = 'Comp-1669'
    BEGIN
        INSERT INTO #Paytm (M_ConsumerId, PaytmAmount)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            SUM(TRY_CAST(ISNULL(pt.Amount, 0) AS DECIMAL(18,2))) AS PaytmAmount
        FROM paytmtransaction pt WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON pt.M_Consumerid = CM.M_ConsumerId
        WHERE pt.compid = 'Comp-1669'
          AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
          AND (@StartDate IS NULL OR pt.pdate >= @StartDate)
          AND (@EndDate   IS NULL OR pt.pdate <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END

    ---------------------------------------------------------
    -- 10. COMBINE FINAL DATA
    ---------------------------------------------------------
    SELECT
        U.ConsumerName,
        U.MobileNo,
        ISNULL(S.State, U.State) AS State,
        ISNULL(S.City, U.City) AS City,
        U.PinCode,
        U.KYCStatus,
        (ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00)) AS PointsEarned,
        ISNULL(R.RefralAmount, 0.00) AS RefralAmount,
        CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN (ISNULL(PT.PaytmAmount, 0.00) + ISNULL(UPI.UPIRedeem, 0.00))
            ELSE (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
        END AS RedeemAmount,
        ((ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00) + ISNULL(R.RefralAmount, 0.00)) - 
         CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN (ISNULL(PT.PaytmAmount, 0.00) + ISNULL(UPI.UPIRedeem, 0.00))
            ELSE (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
         END) AS BalanceAmount,
        B.LastScan
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State S ON U.M_ConsumerId = S.M_ConsumerId
    LEFT JOIN #Benefit B ON U.M_ConsumerId = B.M_ConsumerId
    LEFT JOIN #OtherEarnedPoints OEP ON U.M_ConsumerId = OEP.M_ConsumerId
    LEFT JOIN #Referrals R ON U.M_ConsumerId = R.M_ConsumerId
    LEFT JOIN #Claims CD ON U.M_ConsumerId = CD.M_ConsumerId
    LEFT JOIN #UPI UPI ON U.M_ConsumerId = UPI.M_ConsumerId
    LEFT JOIN #BPoints BP ON U.M_ConsumerId = BP.M_ConsumerId
    LEFT JOIN #Transactions T ON U.M_ConsumerId = T.M_ConsumerId
    LEFT JOIN #Paytm PT ON U.M_ConsumerId = PT.M_ConsumerId
    WHERE (
        @KYCStatusFilter IS NULL OR
        (@KYCStatusFilter = 'Approved' AND U.KYCStatus = 'Approved') OR
        (@KYCStatusFilter = 'Rejected' AND U.KYCStatus = 'Rejected') OR
        (@KYCStatusFilter = 'Pending' AND (U.KYCStatus = 'Pending' OR U.KYCStatus IS NULL))
    )
    AND (
        @StateFilter IS NULL OR
        ISNULL(S.State, U.State) = @StateFilter
    )
    AND (
        (ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00)) > 0
        OR ISNULL(R.RefralAmount, 0.00) > 0
        OR (CASE 
                WHEN @Comp_Id = 'Comp-1669' THEN (ISNULL(PT.PaytmAmount, 0.00) + ISNULL(UPI.UPIRedeem, 0.00))
                ELSE (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
            END) > 0
    );

    ---------------------------------------------------------
    -- 11. RESULT SETS
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RefralAmount,
            RedeemAmount,
            BalanceAmount,
            LastScan
        FROM #FinalData
        ORDER BY PointsEarned DESC, LastScan DESC;
    END
    ELSE
    BEGIN
        SELECT
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RefralAmount,
            RedeemAmount,
            BalanceAmount,
            LastScan
        FROM #FinalData
        ORDER BY PointsEarned DESC, LastScan DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO

PRINT 'Updating [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]...';
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]
(
    @Comp_Id         NVARCHAR(50),  
    @datePreset      NVARCHAR(20) = NULL,   -- TODAY, WEEK, LASTWEEK, MONTH, QUARTER, ALL
    @FromDate        DATE = NULL,
    @ToDate          DATE = NULL, 
    @KYCStatusFilter NVARCHAR(20) = NULL,   -- Approved / Rejected / Pending
    @StateFilter     NVARCHAR(100) = NULL,
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL,
    @Search          NVARCHAR(100) = NULL,
    @BalanceLessThan DECIMAL(18,2) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- DEFAULT PAGINATION
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- COMPANY FILTER PREPARATION (UNLINKED)
    ---------------------------------------------------------
    DECLARE @CompanyList TABLE (Comp_Id VARCHAR(50) PRIMARY KEY);
    INSERT INTO @CompanyList VALUES (@Comp_Id);

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation WITH (NOLOCK)
    WHERE comp_id = @Comp_Id;

    ---------------------------------------------------------
    -- DATE RANGE CALCULATION
    ---------------------------------------------------------
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate DATETIME = NULL;

    IF @datePreset IS NOT NULL AND @datePreset <> ''
    BEGIN
        SET @datePreset = UPPER(@datePreset);
        IF @datePreset = 'TODAY'
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate = DATEADD(DAY, 1, @StartDate);
        END
        ELSE IF @datePreset = 'WEEK'
        BEGIN
            SET @StartDate = DATEADD(DAY, -(DATEPART(WEEKDAY, @Today) - 1), CAST(@Today AS DATETIME));
            SET @EndDate = DATEADD(DAY, 7, @StartDate);
        END
        ELSE IF @datePreset = 'LASTWEEK'
        BEGIN
            SET @StartDate = DATEADD(DAY, -(DATEPART(WEEKDAY, @Today) + 6), CAST(@Today AS DATETIME));
            SET @EndDate = DATEADD(DAY, 7, @StartDate);
        END
        ELSE IF @datePreset = 'MONTH'
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DAY(@Today), CAST(@Today AS DATETIME));
            SET @EndDate = DATEADD(MONTH, 1, @StartDate);
        END
        ELSE IF @datePreset = 'QUARTER'
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Today), 0);
            SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
        END
        ELSE IF @datePreset = 'YEAR'
        BEGIN
            SET @StartDate = DATEADD(YEAR, DATEDIFF(YEAR, 0, @Today), 0);
            SET @EndDate = DATEADD(YEAR, 1, @StartDate);
        END
        ELSE IF @datePreset = 'ALL'
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate = NULL;
        END
    END
    ELSE IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END

    ---------------------------------------------------------
    -- TEMP TABLES DEFINITION
    ---------------------------------------------------------
    CREATE TABLE #ConsumerMapping (
        M_ConsumerId INT PRIMARY KEY,
        Active_ConsumerId INT
    );

    CREATE TABLE #Users (
        M_ConsumerId INT PRIMARY KEY,
        ConsumerName NVARCHAR(250),
        MobileNo NVARCHAR(50),
        City NVARCHAR(100),
        State NVARCHAR(100),
        PinCode NVARCHAR(20),
        KYCStatus NVARCHAR(50)
    );

    CREATE TABLE #Benefit (
        M_ConsumerId INT PRIMARY KEY,
        PointsEarned DECIMAL(18,2),
        LastScan DATETIME
    );

    CREATE TABLE #OtherEarnedPoints (
        M_ConsumerId INT PRIMARY KEY,
        OtherPoints DECIMAL(18,2)
    );

    CREATE TABLE #Referrals (
        M_ConsumerId INT PRIMARY KEY,
        ReferralPoints DECIMAL(18,2)
    );

    CREATE TABLE #Claims (
        M_ConsumerId INT PRIMARY KEY,
        Transferred DECIMAL(18,2),
        TDS DECIMAL(18,2)
    );

    CREATE TABLE #UPI (
        M_ConsumerId INT PRIMARY KEY,
        UPIAmount DECIMAL(18,2)
    );

    CREATE TABLE #BPoints (
        M_ConsumerId INT PRIMARY KEY,
        BPointsDebited DECIMAL(18,2)
    );

    CREATE TABLE #Transactions (
        M_ConsumerId INT PRIMARY KEY,
        TransactionsAmount DECIMAL(18,2)
    );

    CREATE TABLE #Paytm (
        M_ConsumerId INT PRIMARY KEY,
        PaytmAmount DECIMAL(18,2)
    );

    CREATE TABLE #State (
        M_ConsumerId INT PRIMARY KEY,
        State NVARCHAR(100),
        City NVARCHAR(100)
    );

    ---------------------------------------------------------
    -- 0. CONSUMER MAPPING & USERS FILTERING
    ---------------------------------------------------------
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
    BEGIN
        SET @Search = LTRIM(RTRIM(@Search));
        INSERT INTO #ConsumerMapping (M_ConsumerId, Active_ConsumerId)
        SELECT 
            M_Consumerid,
            COALESCE(Active_Consumerid, M_Consumerid)
        FROM M_Consumer WITH (NOLOCK)
        WHERE (User_ID = @Search OR MobileNo = @Search OR ConsumerName LIKE '%' + @Search + '%');
    END
    ELSE
    BEGIN
        INSERT INTO #ConsumerMapping (M_ConsumerId, Active_ConsumerId)
        SELECT 
            M_Consumerid,
            COALESCE(Active_Consumerid, M_Consumerid)
        FROM M_Consumer WITH (NOLOCK)
        WHERE (IsDelete = 0 OR IsDelete IS NULL);
    END

    INSERT INTO #Users (M_ConsumerId, ConsumerName, MobileNo, City, State, PinCode, KYCStatus)
    SELECT 
        c.M_Consumerid,
        c.ConsumerName,
        RIGHT(RTRIM(c.MobileNo), 10) AS MobileNo,
        c.City,
        c.State,
        c.PinCode,
        CASE 
            WHEN k.Status = 1 THEN 'Approved'
            WHEN k.Status = 2 THEN 'Rejected'
            ELSE 'Pending'
        END AS KYCStatus
    FROM M_Consumer c WITH (NOLOCK)
    LEFT JOIN Kyc_status k WITH (NOLOCK) ON c.M_Consumerid = k.M_Consumerid
    WHERE c.M_Consumerid IN (SELECT DISTINCT Active_ConsumerId FROM #ConsumerMapping)
      AND (c.IsDelete = 0 OR c.IsDelete IS NULL);

    ---------------------------------------------------------
    -- 1. BENEFITS (POINTS EARNED)
    ---------------------------------------------------------
    IF @Comp_Id = 'Comp-1669'
    BEGIN
        INSERT INTO #Benefit (M_ConsumerId, PointsEarned, LastScan)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            SUM(ISNULL(p.Cash, 0.00)) AS PointsEarned,
            MAX(p.Entry_Date) AS LastScan
        FROM Pro_Reg p WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON p.M_Consumerid = CM.M_ConsumerId
        WHERE p.Comp_ID = 'Comp-1669'
          AND (@StartDate IS NULL OR p.Entry_Date >= @StartDate)
          AND (@EndDate   IS NULL OR p.Entry_Date <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END
    ELSE
    BEGIN
        INSERT INTO #Benefit (M_ConsumerId, PointsEarned, LastScan)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            ROUND(SUM(ISNULL(TRY_CAST(b.PointsEarned AS DECIMAL(18,2)), 0.00)) * @Multiplier, 2) AS PointsEarned,
            MAX(b.EntryDate) AS LastScan
        FROM BLoyaltyPointsEarned b WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON b.ConsumerId = CM.M_ConsumerId
        WHERE (b.compid = @Comp_Id OR (b.compid IS NULL AND EXISTS (
            SELECT 1 FROM M_Consumer_M_Code mc WITH (NOLOCK)
            INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.M_Code = pr.M_Code
            WHERE mc.M_Consumerid = b.ConsumerId
              AND pr.Comp_ID = @Comp_Id
        )))
          AND (@StartDate IS NULL OR b.EntryDate >= @StartDate)
          AND (@EndDate   IS NULL OR b.EntryDate <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END

    ---------------------------------------------------------
    -- 2. STATE OVERRIDES
    ---------------------------------------------------------
    INSERT INTO #State (M_ConsumerId, State, City)
    SELECT 
        CM.Active_ConsumerId,
        S.State_Name,
        C.City_Name
    FROM (
        SELECT 
            mc.M_Consumerid,
            mc.State_Id,
            mc.City_Id,
            ROW_NUMBER() OVER (PARTITION BY CM.Active_ConsumerId ORDER BY mc.M_Consumerid DESC) as rn
        FROM M_Consumer mc WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON mc.M_Consumerid = CM.M_ConsumerId
        WHERE mc.State_Id IS NOT NULL
    ) RankedConsumers
    LEFT JOIN State_Master S WITH (NOLOCK) ON RankedConsumers.State_Id = S.State_Id
    LEFT JOIN City_Master C WITH (NOLOCK) ON RankedConsumers.City_Id = C.City_Id
    INNER JOIN #ConsumerMapping CM ON RankedConsumers.M_Consumerid = CM.M_ConsumerId
    WHERE RankedConsumers.rn = 1;

    ---------------------------------------------------------
    -- 3. OTHER EARNED POINTS
    ---------------------------------------------------------
    INSERT INTO #OtherEarnedPoints (M_ConsumerId, OtherPoints)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        ROUND(SUM(ISNULL(TRY_CAST(points AS DECIMAL(18,2)), 0.00)) * @Multiplier, 2) AS OtherPoints
    FROM Other_Earned_Point o WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON o.Consumer_id = CM.M_ConsumerId
    WHERE o.Comp_Id = @Comp_Id
      AND (@StartDate IS NULL OR o.Entry_Date >= @StartDate)
      AND (@EndDate   IS NULL OR o.Entry_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 4. REFERRALS
    ---------------------------------------------------------
    INSERT INTO #Referrals (M_ConsumerId, ReferralPoints)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        ROUND(SUM(ISNULL(TRY_CAST(r.Amount AS DECIMAL(18,2)), 0.00)) * @Multiplier, 2) AS ReferralPoints
    FROM Referral_History r WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON r.User_Id = CM.M_ConsumerId
    WHERE r.Comp_Id = @Comp_Id
      AND (@StartDate IS NULL OR r.Entry_Date >= @StartDate)
      AND (@EndDate   IS NULL OR r.Entry_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 5. CLAIMS REDEEM
    ---------------------------------------------------------
    INSERT INTO #Claims (M_ConsumerId, Transferred, TDS)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(cd.Points, 0.00)) AS Transferred,
        SUM(ISNULL(cd.Tds_Amount, 0.00)) AS TDS
    FROM Claim_Details cd WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON cd.Consumer_ID = CM.M_ConsumerId
    WHERE cd.Comp_ID = @Comp_Id
      AND cd.Status = 1
      AND cd.IsSuccess = 1
      AND (@StartDate IS NULL OR cd.Claim_Date >= @StartDate)
      AND (@EndDate   IS NULL OR cd.Claim_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 6. UPI REDEEM
    ---------------------------------------------------------
    INSERT INTO #UPI (M_ConsumerId, UPIAmount)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(TRY_CAST(u.Amount AS DECIMAL(18,2)), 0.00)) AS UPIAmount
    FROM Upi_PaymentTransaction u WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON u.M_Consumerid = CM.M_ConsumerId
    WHERE u.Comp_Id = @Comp_Id
      AND u.Status IN ('Success', 'SUCCESS', 'ACCEPTED')
      AND u.IsCode1 = 1
      AND (@StartDate IS NULL OR u.Payment_Date >= @StartDate)
      AND (@EndDate   IS NULL OR u.Payment_Date <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 7. BPOINTS DEBITED
    ---------------------------------------------------------
    INSERT INTO #BPoints (M_ConsumerId, BPointsDebited)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(bp.PointsDebited, 0.00)) AS BPointsDebited
    FROM BPointsRedeemed bp WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON bp.ConsumerId = CM.M_ConsumerId
    WHERE bp.compid = @Comp_Id
      AND bp.IsRedeemed = 1
      AND bp.PointsDebited > 0
      AND (@StartDate IS NULL OR bp.EntryDate >= @StartDate)
      AND (@EndDate   IS NULL OR bp.EntryDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 8. TRANSACTIONS
    ---------------------------------------------------------
    INSERT INTO #Transactions (M_ConsumerId, TransactionsAmount)
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(TRY_CAST(t.Amount AS DECIMAL(18,2)), 0.00)) AS TransactionsAmount
    FROM Transactions t WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON t.M_Consumerid = CM.M_ConsumerId
    WHERE t.Comp_Id = @Comp_Id
      AND t.Remarks = 'Vcqru'
      AND (@StartDate IS NULL OR t.EntryDate >= @StartDate)
      AND (@EndDate   IS NULL OR t.EntryDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    ---------------------------------------------------------
    -- 9. PAYTM
    ---------------------------------------------------------
    IF @Comp_Id = 'Comp-1669'
    BEGIN
        INSERT INTO #Paytm (M_ConsumerId, PaytmAmount)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            SUM(TRY_CAST(ISNULL(pt.Amount, 0) AS DECIMAL(18,2))) AS PaytmAmount
        FROM paytmtransaction pt WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON pt.M_Consumerid = CM.M_ConsumerId
        WHERE pt.compid = 'Comp-1669'
          AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
          AND (@StartDate IS NULL OR pt.pdate >= @StartDate)
          AND (@EndDate   IS NULL OR pt.pdate <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END

    ---------------------------------------------------------
    -- 10. COMBINE FINAL DATA
    ---------------------------------------------------------
    SELECT 
        U.ConsumerName,
        U.MobileNo,
        COALESCE(S.State, U.State) AS State,
        COALESCE(S.City, U.City) AS City,
        U.PinCode,
        U.KYCStatus,
        (ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) AS PointsEarned,
        ISNULL(R.ReferralPoints, 0.00) AS RefralAmount,
        CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN (ISNULL(PT.PaytmAmount, 0.00) + ISNULL(UPI.UPIAmount, 0.00))
            ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
        END AS RedeemAmount,
        (((ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) + ISNULL(R.ReferralPoints, 0.00)) - 
         CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN (ISNULL(PT.PaytmAmount, 0.00) + ISNULL(UPI.UPIAmount, 0.00))
            ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
         END) AS BalanceAmount,
        ISNULL(C.TDS, 0.00) AS TDSAmount,
        B.LastScan,
        ROW_NUMBER() OVER (ORDER BY (ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) DESC, U.M_ConsumerId) AS RN
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State S ON S.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Benefit B ON B.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #OtherEarnedPoints O ON O.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Referrals R ON R.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Claims C ON C.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #UPI UPI ON UPI.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #BPoints BP ON BP.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Transactions T ON T.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Paytm PT ON PT.M_ConsumerId = U.M_ConsumerId
    WHERE (
            (ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) > 0 
            OR ISNULL(R.ReferralPoints, 0.00) > 0 
            OR (CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN (ISNULL(PT.PaytmAmount, 0.00) + ISNULL(UPI.UPIAmount, 0.00))
                    ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
                END) > 0
          )
      AND (@KYCStatusFilter IS NULL OR U.KYCStatus = @KYCStatusFilter)
      AND (@StateFilter IS NULL OR S.State = @StateFilter OR (S.State IS NULL AND U.State = @StateFilter))
      AND (@BalanceLessThan IS NULL OR ((((ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) + ISNULL(R.ReferralPoints, 0.00)) - 
           CASE 
                WHEN @Comp_Id = 'Comp-1669' THEN (ISNULL(PT.PaytmAmount, 0.00) + ISNULL(UPI.UPIAmount, 0.00))
                ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
           END) < @BalanceLessThan))
      AND (
          @Search IS NULL 
          OR LTRIM(RTRIM(@Search)) = ''
          OR U.ConsumerName LIKE '%' + @Search + '%'
          OR U.MobileNo LIKE '%' + @Search + '%'
          OR S.State LIKE '%' + @Search + '%'
          OR S.City LIKE '%' + @Search + '%'
      );

    ---------------------------------------------------------
    -- 11. OUTPUT
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN 
        SELECT 
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RefralAmount,
            RedeemAmount,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        ORDER BY PointsEarned DESC, LastScan DESC;
    END
    ELSE 
    BEGIN
        SELECT 
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RefralAmount,
            RedeemAmount,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        ORDER BY PointsEarned DESC, LastScan DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT 
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
