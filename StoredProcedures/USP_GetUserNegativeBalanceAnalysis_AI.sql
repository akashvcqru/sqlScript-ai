USE [Vcqru]
GO
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
CREATE OR ALTER PROCEDURE [dbo].[USP_GetUserNegativeBalanceAnalysis_AI]
(
    @MobileNo NVARCHAR(30),
    @Comp_Id  NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #UniqueScans, #EarnedPoints, #ConfigPoints, #Ledger, #ChronologicalLedger;

    -- Clean the mobile number and resolve consumer info
    DECLARE @CleanMobile NVARCHAR(30) = REPLACE(@MobileNo, '+', '');
    DECLARE @M_ConsumerId INT;
    SELECT TOP 1 @M_ConsumerId = M_ConsumerId FROM M_Consumer WITH (NOLOCK) WHERE REPLACE(MobileNo, '+', '') = @CleanMobile AND IsDelete = 0;

    IF @M_ConsumerId IS NULL
    BEGIN
        -- If user not found, return empty results matching output schema
        SELECT 
            CAST(NULL AS DATETIME) AS TransactionDate,
            CAST(NULL AS NVARCHAR(50)) AS TransactionType,
            CAST(NULL AS NVARCHAR(100)) AS TransactionRefId,
            CAST(NULL AS DECIMAL(18,2)) AS PointsRedeemed,
            CAST(NULL AS NVARCHAR(50)) AS Status,
            CAST(NULL AS DECIMAL(18,2)) AS RunningBalance,
            CAST(NULL AS INT) AS IsFraudEntry,
            CAST(NULL AS DECIMAL(18,2)) AS ExceededPointsNegative,
            CAST(NULL AS DATETIME) AS EntryDate,
            CAST(NULL AS NVARCHAR(150)) AS UPIId,
            CAST(NULL AS NVARCHAR(max)) AS Remark;
        RETURN;
    END

    -- Temporary table to hold unified lifetime ledger transactions
    CREATE TABLE #Ledger (
        LedgerDate DATETIME,
        SortOrder INT, -- 1: Earning, 2: Redemption
        TransactionType NVARCHAR(50),
        RefId NVARCHAR(100),
        Amount DECIMAL(18,2), -- positive for earnings, negative for redemptions
        Status NVARCHAR(50)
    );

    ---------------------------------------------------------
    -- 1. LOAD EARNINGS: SCAN POINTS (LIFETIME)
    -- Optimized SARGable joins on Pro_Enq MobileNo (UNION ALL ensures index seek)
    ---------------------------------------------------------
    SELECT 
        Row_ID AS M_Codeid, Pro_ID, Series_Order, Series_Serial, Enq_Date,
        ROW_NUMBER() OVER (PARTITION BY Received_Code1, Received_Code2, Is_Success ORDER BY PE.Enq_Date) as rn
    INTO #UniqueScans
    FROM (
        SELECT M.Row_ID, M.Pro_ID, M.Series_Order, M.Series_Serial, PE.Received_Code1, PE.Received_Code2, PE.Is_Success, PE.Enq_Date
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = @Comp_Id
        WHERE PE.MobileNo = @CleanMobile AND PE.Is_Success = '1'

        UNION ALL

        SELECT M.Row_ID, M.Pro_ID, M.Series_Order, M.Series_Serial, PE.Received_Code1, PE.Received_Code2, PE.Is_Success, PE.Enq_Date
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = @Comp_Id
        WHERE PE.MobileNo = '+' + @CleanMobile AND PE.Is_Success = '1'
    ) PE;

    CREATE CLUSTERED INDEX IX_UniqueScans_MCodeid ON #UniqueScans(M_Codeid);

    -- Get Earned points for each scan
    SELECT
        US.M_Codeid,
        SUM(Points) AS Points
    INTO #EarnedPoints
    FROM (
        SELECT
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(LC.calculation_value, 0.0) / 100.0)
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON MC.M_Consumerid = @M_ConsumerId
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        LEFT JOIN loyalty_calculation LC WITH (NOLOCK) ON LC.comp_id = @Comp_Id AND LC.isactive = 1 AND LC.isdelete = 0
        WHERE BL.compid = @Comp_Id
        
        UNION ALL

        SELECT
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(LC.calculation_value, 0.0) / 100.0)
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON MC.M_Consumerid = @M_ConsumerId
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID AND PR.Comp_Id = @Comp_Id
        LEFT JOIN loyalty_calculation LC WITH (NOLOCK) ON LC.comp_id = @Comp_Id AND LC.isactive = 1 AND LC.isdelete = 0
        WHERE BL.compid IS NULL
    ) x
    INNER JOIN #UniqueScans US ON US.M_Codeid = x.M_Codeid AND US.rn = 1
    GROUP BY US.M_Codeid;

    CREATE CLUSTERED INDEX IX_EarnedPoints ON #EarnedPoints(M_Codeid);

    -- Get Configured points for each scan
    SELECT 
        US.M_Codeid,
        MAX(CAST(
            CASE 
                WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                ELSE ISNULL(SST.IsCash, 0) * (1.00 + ISNULL(LC.calculation_value, 0.0) / 100.0)
            END 
        AS DECIMAL(18,2))) AS ConfigPoints
    INTO #ConfigPoints
    FROM #UniqueScans US
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID AND SS.Comp_ID = @Comp_Id
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    LEFT JOIN loyalty_calculation LC WITH (NOLOCK) ON LC.comp_id = @Comp_Id AND LC.isactive = 1 AND LC.isdelete = 0
    WHERE US.rn = 1
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
      AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
      AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
    GROUP BY US.M_Codeid;

    CREATE CLUSTERED INDEX IX_ConfigPoints ON #ConfigPoints(M_Codeid);

    -- Record Scan earnings in #Ledger (Exclude Comp-1152 which has its own ledger table below)
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        US.Enq_Date AS LedgerDate,
        1 AS SortOrder,
        'SCAN' AS TransactionType,
        CAST(US.M_Codeid AS NVARCHAR(100)) AS RefId,
        ISNULL(P.Points, ISNULL(CP.ConfigPoints, 0)) AS Amount,
        'Success' AS Status
    FROM #UniqueScans US
    LEFT JOIN #EarnedPoints P ON P.M_Codeid = US.M_Codeid
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = US.M_Codeid
    WHERE US.rn = 1 AND @Comp_Id <> 'Comp-1152';

    -- Override: Load Comp-1152 scans from ConsumerPointsCashDetails (LIFETIME)
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        CP.Enq_Date AS LedgerDate,
        1 AS SortOrder,
        'SCAN' AS TransactionType,
        CAST(NULL AS NVARCHAR(100)) AS RefId,
        TRY_CAST(CP.points AS DECIMAL(18,2)) AS Amount,
        'Success' AS Status
    FROM dbo.ConsumerPointsCashDetails CP WITH (NOLOCK)
    WHERE CP.MobileNo = @CleanMobile
      AND @Comp_Id = 'Comp-1152'
      AND CP.Enq_Date >= '2022-08-04 00:00:00.000'
      AND CP.Is_Success = 1;

    ---------------------------------------------------------
    -- 2. LOAD EARNINGS: REFERRAL POINTS & OTHER REWARDS
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        BL.UpdateDate AS LedgerDate,
        1 AS SortOrder,
        UPPER(BL.ServiceName) AS TransactionType,
        CAST(BL.BLoyalty_PointEarnedID AS NVARCHAR(100)) AS RefId,
        CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS Amount,
        'Success' AS Status
    FROM dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
    WHERE BL.M_Consumerid = @M_ConsumerId AND BL.compid = @Comp_Id
      AND LOWER(BL.ServiceName) IN ('refral', 'referral', 'kycrewards', 'supervisor', 'invoicebenifit', 'invoicerewards');

    ---------------------------------------------------------
    -- 3. LOAD REDEMPTIONS: CLAIMS (APPROVED REST)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        CD.Claim_date AS LedgerDate,
        2 AS SortOrder,
        'CLAIM' AS TransactionType,
        CAST(CD.Row_ID AS NVARCHAR(100)) AS RefId,
        -CD.Amount AS Amount,
        'Approved' AS Status
    FROM ClaimDetails CD WITH (NOLOCK)
    WHERE CD.Comp_id = @Comp_Id AND CD.Mobileno = @CleanMobile
      AND CD.Isapproved = 1;

    ---------------------------------------------------------
    -- 4. LOAD REDEMPTIONS: UPI PAYOUTS (SUCCESS REST)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        UT.ReqDate AS LedgerDate,
        2 AS SortOrder,
        'UPI' AS TransactionType,
        CAST(UT.Id AS NVARCHAR(100)) AS RefId,
        -ISNULL(UT.Amount, 0) AS Amount,
        UT.Status AS Status
    FROM tblUPITransactionDetails UT WITH (NOLOCK)
    WHERE UT.Comp_Id = @Comp_Id 
      AND (UT.M_Consumerid = CAST(@M_ConsumerId AS VARCHAR(50)) OR REPLACE(UT.Mobileno, '+', '') = @CleanMobile)
      AND UT.Status = 'Success'
      AND LEN(ISNULL(UT.Code1, '')) > 1
      AND LEN(ISNULL(UT.Code2, '')) > 6;

    ---------------------------------------------------------
    -- 5. LOAD REDEMPTIONS: BPOINTS REDEMPTION (ACCEPTED / SUCCESS REST)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        BP.Redeemdate AS LedgerDate,
        2 AS SortOrder,
        'BPOINTS' AS TransactionType,
        CAST(NULL AS NVARCHAR(100)) AS RefId,
        -ISNULL(BP.RedeemPoints, 0) AS Amount,
        BP.bpstatus AS Status
    FROM BPointsTransaction BP WITH (NOLOCK)
    WHERE BP.companyid = @Comp_Id AND BP.RedeemBy = @M_ConsumerId
      AND BP.bpstatus IN ('Accepted', 'SUCCESS');

    ---------------------------------------------------------
    -- 6. LOAD REDEMPTIONS: LEGACY TRANSACTIONS (SUCCESS REST)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        TR.TransactionDate AS LedgerDate,
        2 AS SortOrder,
        'TRANSACTION' AS TransactionType,
        CAST(NULL AS NVARCHAR(100)) AS RefId,
        -ISNULL(CAST(TR.Amount AS DECIMAL(18,2)), 0) AS Amount,
        'Success' AS Status
    FROM Transactions TR WITH (NOLOCK)
    WHERE TR.CompId = REPLACE(@Comp_Id, 'Comp-', '') AND TR.M_CounserID = CAST(@M_ConsumerId AS VARCHAR(50))
      AND TR.IsSuccess = 1
      AND (@Comp_Id <> 'Comp-1152' OR TR.TransactionDate > '2022-11-25');

    ---------------------------------------------------------
    -- 7. COMPILE LEDGER AND COMPUTE CHRONOLOGICAL RUNNING BALANCE
    ---------------------------------------------------------
    SELECT 
        LedgerDate,
        SortOrder,
        TransactionType,
        RefId,
        Amount,
        Status,
        SUM(Amount) OVER (
            ORDER BY LedgerDate ASC, SortOrder ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningBalance
    INTO #ChronologicalLedger
    FROM #Ledger;

    ---------------------------------------------------------
    -- 8. RETURN HIGHLIGHTED CLAIMS AND UPI DETAILS WITH FRAUD STATUS
    ---------------------------------------------------------
    SELECT 
        CL.TransactionDate,
        CL.TransactionType,
        CL.TransactionRefId,
        CL.PointsRedeemed,
        CL.Status,
        CL.RunningBalance,
        CL.IsFraudEntry,
        CL.ExceededPointsNegative,
        COALESCE(CD.Claim_date, UT.ReqDate) AS EntryDate,
        COALESCE(CD.UPIID, UT.UPI_Id) AS UPIId,
        COALESCE(CD.PaymentRemarks, UT.Remarks) AS Remark
    FROM (
        SELECT 
            LedgerDate AS TransactionDate,
            TransactionType,
            RefId AS TransactionRefId,
            -Amount AS PointsRedeemed,
            Status,
            RunningBalance,
            CASE WHEN RunningBalance < 0 THEN 1 ELSE 0 END AS IsFraudEntry,
            CASE WHEN RunningBalance < 0 THEN -RunningBalance ELSE 0 END AS ExceededPointsNegative
        FROM #ChronologicalLedger
        WHERE TransactionType IN ('CLAIM', 'UPI')
    ) CL
    LEFT JOIN ClaimDetails CD WITH (NOLOCK) ON CL.TransactionType = 'CLAIM' AND CAST(CD.Row_ID AS NVARCHAR(100)) = CL.TransactionRefId
    LEFT JOIN tblUPITransactionDetails UT WITH (NOLOCK) ON CL.TransactionType = 'UPI' AND CAST(UT.Id AS NVARCHAR(100)) = CL.TransactionRefId
    ORDER BY CL.TransactionDate DESC;

    -- Cleanup temp tables
    DROP TABLE IF EXISTS #UniqueScans, #EarnedPoints, #ConfigPoints, #Ledger, #ChronologicalLedger;
END
GO
