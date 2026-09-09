USE [vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-07-03
-- Description: Retrieves high value payment requests from ClaimDetails with fallback to DEFAULT limit.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetHighValuePaymentRequests_Admin_AI]
(
      @Compid           NVARCHAR(50) = NULL,   -- Optional company filter
      @FromDate         DATE = NULL,
      @ToDate           DATE = NULL,
      @datePreset       NVARCHAR(20) = NULL,
      @Search           NVARCHAR(50) = NULL,   -- Search parameter (mobile, claim ID, or bank reference)
      @Page             INT = 1,
      @Limit            INT = 10,
      @IsExport         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #FinalData;

    CREATE TABLE #FinalData (
        ClaimId INT NOT NULL,
        ClaimDate DATETIME NOT NULL,
        MobileNo VARCHAR(15) NULL,
        UserName NVARCHAR(150) NULL,
        Amount DECIMAL(18, 2) NULL,
        RequestAmmount DECIMAL(18, 2) NULL,
        ClaimPoints DECIMAL(18, 2) NULL,
        PointConversion NVARCHAR(50) NULL,
        CompName NVARCHAR(150) NULL,
        CompId VARCHAR(50) NULL,
        IsApproved INT NOT NULL,
        VendorComment NVARCHAR(MAX) NULL,
        PaymentRemarks NVARCHAR(MAX) NULL,
        PaymentStatus VARCHAR(50) NULL,
        ClaimMode NVARCHAR(200) NULL,
        VendorWalletBalance DECIMAL(18, 2) NULL,
        TotalEarnedPoints DECIMAL(18, 2) NULL,
        TotalRedeemedPoints DECIMAL(18, 2) NULL,
        BalancePoints DECIMAL(18, 2) NULL,
        IFSCCode NVARCHAR(50) NULL,
        AccountNumber NVARCHAR(50) NULL,
        BankName NVARCHAR(100) NULL,
        KycStatus NVARCHAR(50) NULL
    );

    -- Date window resolution
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@datePreset,''));

    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = DATEADD(DAY, 1, @ToDate);
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'LASTDAY'
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @Today);
            SET @EndDate   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'MONTH'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE
        BEGIN
            -- Default to last 30 days
            SET @StartDate = DATEADD(DAY, -30, @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
    END

    -- Fetch high value claims prioritizing company threshold or falling back to default threshold
    INSERT INTO #FinalData (ClaimId, ClaimDate, MobileNo, UserName, Amount, RequestAmmount, ClaimPoints, PointConversion, CompName, CompId, IsApproved, VendorComment, PaymentRemarks, PaymentStatus, ClaimMode, VendorWalletBalance, TotalEarnedPoints, TotalRedeemedPoints, BalancePoints, IFSCCode, AccountNumber, BankName, KycStatus)
    SELECT
        cd.Row_id AS ClaimId,
        cd.Claim_date AS ClaimDate,
        cd.Mobileno AS MobileNo,
        mc.ConsumerName AS UserName,
        CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) AS Amount,
        CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) AS RequestAmmount,
        CAST(ISNULL(cd.Points_Redeemed, cd.Amount) AS DECIMAL(18,2)) AS ClaimPoints,
        CASE 
            WHEN TRY_CAST(ISNULL(cd.Points_Redeemed, cd.Amount) AS DECIMAL(18,2)) > 0 
                 AND TRY_CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) > 0 
                 AND TRY_CAST(ISNULL(cd.Points_Redeemed, cd.Amount) AS DECIMAL(18,2)) <> TRY_CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) THEN
                CONCAT(
                    CAST(CAST(ROUND(TRY_CAST(cd.Points_Redeemed AS DECIMAL(18,2)) / TRY_CAST(cd.RequestAmmount AS DECIMAL(18,2)), 2) AS DECIMAL(10,2)) AS VARCHAR(20)),
                    ' Pts = ₹1.00'
                )
            ELSE '1 Pt = ₹1.00'
        END AS PointConversion,
        ISNULL(c.Comp_Name, 'Unknown') AS CompName,
        cd.Comp_id AS CompId,
        cd.Isapproved AS IsApproved,
        cd.vendor_comment AS VendorComment,
        cd.PaymentRemarks AS PaymentRemarks,
        CASE WHEN cd.Isapproved = 1 THEN 'Approved' WHEN cd.Isapproved = 2 THEN 'Rejected' ELSE 'Pending' END AS PaymentStatus,
        cd.Claim_mode AS ClaimMode,
        0.00 AS VendorWalletBalance,
        0.00 AS TotalEarnedPoints,
        0.00 AS TotalRedeemedPoints,
        0.00 AS BalancePoints,
        NULL AS IFSCCode,
        NULL AS AccountNumber,
        NULL AS BankName,
        CASE 
            WHEN kyc.VRKbl_KYC_status = 1 THEN 'Approved' 
            WHEN kyc.VRKbl_KYC_status = 2 THEN 'Rejected' 
            ELSE 'Pending' 
        END AS KycStatus
    FROM ClaimDetails cd WITH (NOLOCK)
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = cd.Comp_id
    OUTER APPLY (
        SELECT TOP 1 M_Consumerid, ConsumerName
        FROM M_Consumer WITH (NOLOCK)
        WHERE RIGHT(MobileNo, 10) = RIGHT(cd.Mobileno, 10) AND IsDelete = 0
        ORDER BY M_Consumerid DESC
    ) mc
    OUTER APPLY (
        SELECT TOP 1 VRKbl_KYC_status
        FROM tbl_Vendorvisekycstatus WITH (NOLOCK)
        WHERE Comp_id = cd.Comp_id 
          AND M_consumerId = mc.M_Consumerid
        ORDER BY Entry_date DESC
    ) kyc
    WHERE cd.Claim_date >= @StartDate
      AND cd.Claim_date < @EndDate
      AND (@Compid IS NULL OR cd.Comp_id = @Compid)
      AND cd.IsHighValue = 1
      AND cd.Isapproved = 0
      AND (
          @Search IS NULL 
          OR cd.Mobileno LIKE '%' + @Search + '%' 
          OR mc.ConsumerName LIKE '%' + @Search + '%'
          OR CAST(cd.Row_id AS VARCHAR(20)) = @Search 
          OR cd.UPIID LIKE '%' + @Search + '%'
          OR cd.BankRefID LIKE '%' + @Search + '%'
      );

    -- Populate Bank Details
    UPDATE f
    SET 
        f.IFSCCode = ISNULL(mba.IFSC_Code, ISNULL(audit.IFSC_Code, '')),
        f.AccountNumber = ISNULL(mba.Account_No, ISNULL(audit.Account_Number, CASE WHEN cd.UPIID NOT LIKE '%@%' THEN ISNULL(cd.BankRefID, cd.UPIID) ELSE cd.BankRefID END)),
        f.BankName = ISNULL(mba.Bank_Name, '')
    FROM #FinalData f
    INNER JOIN ClaimDetails cd WITH (NOLOCK) ON cd.Row_id = f.ClaimId
    LEFT JOIN M_Consumer mc WITH (NOLOCK) ON RIGHT(mc.MobileNo, 10) = RIGHT(f.MobileNo, 10) AND mc.IsDelete = 0
    OUTER APPLY (
        SELECT TOP 1 Account_No, IFSC_Code, Bank_Name 
        FROM M_BankAccount WITH (NOLOCK)
        WHERE M_Consumerid = mc.M_Consumerid AND ISNULL(Account_No, '') <> ''
        ORDER BY Row_ID DESC
    ) mba
    OUTER APPLY (
        SELECT TOP 1 Account_Number, IFSC_Code
        FROM MobileToAccount_Audit WITH (NOLOCK)
        WHERE RIGHT(MobileNo, 10) = RIGHT(f.MobileNo, 10) AND ISNULL(Account_Number, '') <> ''
        ORDER BY Id DESC
    ) audit;

    -- Populate Vendor Wallet Balance
    UPDATE f
    SET f.VendorWalletBalance = ISNULL(pb.Amount, ISNULL(cb.Balance, 0.00))
    FROM #FinalData f
    OUTER APPLY (
        SELECT SUM(Amount) AS Amount 
        FROM Paytm_balance WITH (NOLOCK) 
        WHERE Comp_ID = f.CompId
    ) pb
    OUTER APPLY (
        SELECT TOP 1 ISNULL(NewBal, Amount) AS Balance 
        FROM tblCashWalletBalance WITH (NOLOCK) 
        WHERE Comp_ID = f.CompId 
        ORDER BY Id DESC
    ) cb;

    -- Aggregate Points for Consumers in #FinalData matching SP_BL_GetBeneficiariesReport logic
    DROP TABLE IF EXISTS #ReqConsumers, #UserMobiles, #UniqueScans, #EarnedPoints, #ConfigPoints, #Benefit, #OtherEarnedPoints, #Referrals, #Claims, #BPoints, #Transactions, #UPI, #ConsumerPoints;

    SELECT DISTINCT f.MobileNo, f.CompId, mc.M_Consumerid
    INTO #ReqConsumers
    FROM #FinalData f
    LEFT JOIN M_Consumer mc WITH (NOLOCK) ON RIGHT(mc.MobileNo, 10) = RIGHT(f.MobileNo, 10) AND mc.IsDelete = 0;

    SELECT DISTINCT rc.MobileNo, rc.M_Consumerid, rc.CompId
    INTO #UserMobiles
    FROM #ReqConsumers rc
    WHERE rc.MobileNo IS NOT NULL AND LTRIM(RTRIM(rc.MobileNo)) <> '';

    -- 1. Unique scans per consumer/company
    SELECT 
        UM.MobileNo,
        UM.M_Consumerid,
        UM.CompId,
        M.Row_ID AS M_Codeid,
        PE.Enq_Date,
        M.Pro_ID,
        M.Series_Order,
        M.Series_Serial,
        ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2, PE.Is_Success ORDER BY PE.Enq_Date) as rn
    INTO #UniqueScans
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN #UserMobiles UM ON RIGHT(PE.MobileNo, 10) = RIGHT(UM.MobileNo, 10)
    INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_ID = UM.CompId
    WHERE PE.Is_Success = '1';

    CREATE INDEX IX_US_MCode ON #UniqueScans(M_Codeid) WHERE rn = 1;

    -- 2. Earned Points per M_Codeid from BLoyaltyPointsEarned
    SELECT
        x.M_Codeid,
        x.CompId,
        MAX(x.Points) AS Points
    INTO #EarnedPoints
    FROM (
        SELECT
            MC.M_Codeid,
            BL.compid AS CompId,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(lc.calculation_value, 0.0) / 100.0)
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK)
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        LEFT JOIN loyalty_calculation lc WITH (NOLOCK)
            ON lc.comp_id = BL.compid AND lc.isactive = 1 AND lc.isdelete = 0
        WHERE BL.M_Consumerid IN (SELECT M_Consumerid FROM #ReqConsumers WHERE M_Consumerid IS NOT NULL)

        UNION ALL

        SELECT
            MC.M_Codeid,
            PR.Comp_ID AS CompId,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(lc.calculation_value, 0.0) / 100.0)
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK)
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN M_Code M WITH (NOLOCK) 
            ON MC.M_Codeid = M.Row_ID
        INNER JOIN Pro_Reg PR WITH (NOLOCK) 
            ON M.Pro_ID = PR.Pro_ID
        LEFT JOIN loyalty_calculation lc WITH (NOLOCK)
            ON lc.comp_id = PR.Comp_ID AND lc.isactive = 1 AND lc.isdelete = 0
        WHERE BL.compid IS NULL
          AND MC.M_Consumerid IN (SELECT M_Consumerid FROM #ReqConsumers WHERE M_Consumerid IS NOT NULL)
    ) x
    GROUP BY x.M_Codeid, x.CompId;

    -- 3. Config Points fallback
    SELECT 
        US.M_Codeid,
        US.CompId,
        MAX(CAST(
            CASE 
                WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                ELSE ISNULL(SST.IsCash, 0) * (1.00 + ISNULL(lc.calculation_value, 0.0) / 100.0)
            END 
        AS DECIMAL(18,2))) AS ConfigPoints
    INTO #ConfigPoints
    FROM #UniqueScans US
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID AND SS.Comp_Id = US.CompId
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    LEFT JOIN loyalty_calculation lc WITH (NOLOCK) ON lc.comp_id = US.CompId AND lc.isactive = 1 AND lc.isdelete = 0
    WHERE US.rn = 1
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
      AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
      AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
    GROUP BY US.M_Codeid, US.CompId;

    -- 4. Scan Benefit aggregation
    SELECT
        E.M_Consumerid,
        E.CompId,
        SUM(CASE WHEN ISNULL(P.Points, 0) > 0 THEN P.Points ELSE ISNULL(CP.ConfigPoints, 0) END) AS Benefit
    INTO #Benefit
    FROM #UniqueScans E
    LEFT JOIN #EarnedPoints P ON P.M_Codeid = E.M_Codeid AND P.CompId = E.CompId
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = E.M_Codeid AND CP.CompId = E.CompId
    WHERE E.rn = 1
    GROUP BY E.M_Consumerid, E.CompId;

    -- 5. Other Earned Points (KYC, invoice rewards, etc.)
    SELECT 
        BL.M_Consumerid,
        BL.compid AS CompId,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(lc.calculation_value, 0.0) / 100.0)
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS OtherPoints
    INTO #OtherEarnedPoints
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    LEFT JOIN loyalty_calculation lc WITH (NOLOCK) ON lc.comp_id = BL.compid AND lc.isactive = 1 AND lc.isdelete = 0
    WHERE BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND BL.M_Consumerid IN (SELECT M_Consumerid FROM #ReqConsumers WHERE M_Consumerid IS NOT NULL)
    GROUP BY BL.M_Consumerid, BL.compid;

    -- 6. Referral Points
    SELECT 
        BL.M_Consumerid,
        BL.compid AS CompId,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(lc.calculation_value, 0.0) / 100.0)
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS ReferralPoints
    INTO #Referrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    LEFT JOIN loyalty_calculation lc WITH (NOLOCK) ON lc.comp_id = BL.compid AND lc.isactive = 1 AND lc.isdelete = 0
    WHERE LOWER(BL.ServiceName) IN ('refral', 'referral')
      AND BL.M_Consumerid IN (SELECT M_Consumerid FROM #ReqConsumers WHERE M_Consumerid IS NOT NULL)
    GROUP BY BL.M_Consumerid, BL.compid;

    -- 7. Claims (Redeemed)
    SELECT 
        rc.MobileNo,
        rc.CompId,
        SUM(CAST(CD.Amount AS DECIMAL(18,2))) AS Transferred
    INTO #Claims
    FROM #ReqConsumers rc
    INNER JOIN ClaimDetails CD WITH (NOLOCK) ON RIGHT(CD.Mobileno, 10) = RIGHT(rc.MobileNo, 10) AND CD.Comp_id = rc.CompId
    WHERE CD.PaymentStatus = 'Success'
    GROUP BY rc.MobileNo, rc.CompId;

    -- 8. BPoints Debits
    SELECT 
        BT.RedeemBy AS M_Consumerid,
        BT.companyid AS CompId,
        SUM(CAST(ISNULL(BT.RedeemPoints, 0) AS DECIMAL(18,2))) AS BPointsDebited
    INTO #BPoints
    FROM BPointsTransaction BT WITH (NOLOCK)
    WHERE BT.bpstatus IN ('Accepted', 'SUCCESS', 'Debit')
      AND BT.RedeemBy IN (SELECT M_Consumerid FROM #ReqConsumers WHERE M_Consumerid IS NOT NULL)
    GROUP BY BT.RedeemBy, BT.companyid;

    -- 9. Transactions (Direct cash / wallet payouts)
    SELECT 
        TRY_CAST(t.M_CounserID AS INT) AS M_Consumerid,
        t.CompId,
        SUM(CAST(ISNULL(t.Amount, 0) AS DECIMAL(18,2))) AS TransactionsAmount
    INTO #Transactions
    FROM Transactions t WITH (NOLOCK)
    WHERE t.Issuccess = 1
      AND TRY_CAST(t.M_CounserID AS INT) IN (SELECT M_Consumerid FROM #ReqConsumers WHERE M_Consumerid IS NOT NULL)
    GROUP BY TRY_CAST(t.M_CounserID AS INT), t.CompId;

    -- 10. Instant UPI Cash Transfers
    SELECT 
        rc.MobileNo,
        rc.CompId,
        SUM(TRY_CAST(t.Amount AS DECIMAL(18,2))) AS UPIAmount
    INTO #UPI
    FROM #ReqConsumers rc
    INNER JOIN tblUPITransactionDetails t WITH (NOLOCK) ON RIGHT(t.MobileNo, 10) = RIGHT(rc.MobileNo, 10) AND t.Comp_Id = rc.CompId
    WHERE t.Status = 'Success'
      AND LEN(ISNULL(t.Code1, '')) > 3
    GROUP BY rc.MobileNo, rc.CompId;

    -- Combine into #ConsumerPoints
    SELECT rc.MobileNo, rc.CompId,
        (ISNULL(b.Benefit, 0) + ISNULL(o.OtherPoints, 0) + ISNULL(r.ReferralPoints, 0)) AS TotalEarnedPoints,
        (ISNULL(c.Transferred, 0) + ISNULL(upi.UPIAmount, 0) + ISNULL(bp.BPointsDebited, 0) + ISNULL(t.TransactionsAmount, 0)) AS TotalRedeemedPoints
    INTO #ConsumerPoints
    FROM #ReqConsumers rc
    LEFT JOIN #Benefit b ON b.M_Consumerid = rc.M_Consumerid AND b.CompId = rc.CompId
    LEFT JOIN #OtherEarnedPoints o ON o.M_Consumerid = rc.M_Consumerid AND o.CompId = rc.CompId
    LEFT JOIN #Referrals r ON r.M_Consumerid = rc.M_Consumerid AND r.CompId = rc.CompId
    LEFT JOIN #Claims c ON c.MobileNo = rc.MobileNo AND c.CompId = rc.CompId
    LEFT JOIN #BPoints bp ON bp.M_Consumerid = rc.M_Consumerid AND (bp.CompId = rc.CompId OR bp.CompId = REPLACE(rc.CompId, 'Comp-', ''))
    LEFT JOIN #Transactions t ON t.M_Consumerid = rc.M_Consumerid AND (t.CompId = rc.CompId OR t.CompId = REPLACE(rc.CompId, 'Comp-', ''))
    LEFT JOIN #UPI upi ON upi.MobileNo = rc.MobileNo AND upi.CompId = rc.CompId;

    UPDATE f
    SET 
        f.TotalEarnedPoints = ISNULL(cp.TotalEarnedPoints, 0),
        f.TotalRedeemedPoints = ISNULL(cp.TotalRedeemedPoints, 0),
        f.BalancePoints = ISNULL(cp.TotalEarnedPoints, 0) - ISNULL(cp.TotalRedeemedPoints, 0)
    FROM #FinalData f
    LEFT JOIN #ConsumerPoints cp ON cp.MobileNo = f.MobileNo AND cp.CompId = f.CompId;

    DECLARE @TotalRecords INT = (SELECT COUNT(*) FROM #FinalData);

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #FinalData
        ORDER BY CASE WHEN IsApproved = 0 THEN 0 ELSE 1 END ASC, ClaimDate DESC;
    END
    ELSE
    BEGIN
        DECLARE @Offset INT = (@Page - 1) * @Limit;

        SELECT * FROM #FinalData
        ORDER BY CASE WHEN IsApproved = 0 THEN 0 ELSE 1 END ASC, ClaimDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Metadata
        SELECT 
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CAST(CEILING(CAST(@TotalRecords AS DECIMAL) / @Limit) AS INT) AS TotalPages;
    END
END
GO
