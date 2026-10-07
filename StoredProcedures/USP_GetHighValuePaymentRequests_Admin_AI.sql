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
        tdsAmount DECIMAL(18, 2) NULL,
        tdsper DECIMAL(18, 2) NULL,
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
        ELSE IF @Win = 'ALL' OR @Win = 'ALLTIME'
        BEGIN
            SET @StartDate = '1900-01-01';
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
    INSERT INTO #FinalData (ClaimId, ClaimDate, MobileNo, UserName, Amount, RequestAmmount, ClaimPoints, PointConversion, CompName, CompId, IsApproved, VendorComment, PaymentRemarks, PaymentStatus, tdsAmount, tdsper, VendorWalletBalance, TotalEarnedPoints, TotalRedeemedPoints, BalancePoints, IFSCCode, AccountNumber, BankName, KycStatus)
    SELECT
        cd.Row_id AS ClaimId,
        cd.Claim_date AS ClaimDate,
        cd.Mobileno AS MobileNo,
        mc.ConsumerName AS UserName,
        CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) AS Amount,
        CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) AS RequestAmmount,
        CAST(ISNULL(cd.Points_Redeemed, cd.Amount) AS DECIMAL(18,2)) AS ClaimPoints,
        CASE 
            WHEN pcr.PointValue IS NOT NULL AND pcr.CashValue IS NOT NULL THEN
                CONCAT(
                    CAST(CAST(pcr.PointValue AS DECIMAL(10,2)) AS NVARCHAR(20)),
                    CASE WHEN pcr.PointValue = 1.00 THEN N' Pt = ' + NCHAR(8377) ELSE N' Pts = ' + NCHAR(8377) END,
                    CAST(CAST(pcr.CashValue AS DECIMAL(10,2)) AS NVARCHAR(20))
                )
            WHEN TRY_CAST(ISNULL(cd.Points_Redeemed, cd.Amount) AS DECIMAL(18,2)) > 0 
                 AND TRY_CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) > 0 
                 AND TRY_CAST(ISNULL(cd.Points_Redeemed, cd.Amount) AS DECIMAL(18,2)) <> TRY_CAST(ISNULL(cd.RequestAmmount, cd.Amount) AS DECIMAL(18,2)) THEN
                CONCAT(
                    CAST(CAST(ROUND(TRY_CAST(cd.Points_Redeemed AS DECIMAL(18,2)) / TRY_CAST(cd.RequestAmmount AS DECIMAL(18,2)), 2) AS DECIMAL(10,2)) AS NVARCHAR(20)),
                    N' Pts = ' + NCHAR(8377) + N'1.00'
                )
            ELSE N'1 Pt = ' + NCHAR(8377) + N'1.00'
        END AS PointConversion,
        ISNULL(c.Comp_Name, 'Unknown') AS CompName,
        cd.Comp_id AS CompId,
        cd.Isapproved AS IsApproved,
        cd.vendor_comment AS VendorComment,
        cd.PaymentRemarks AS PaymentRemarks,
        CASE WHEN cd.Isapproved = 1 THEN 'Approved' WHEN cd.Isapproved = 2 THEN 'Rejected' ELSE 'Pending' END AS PaymentStatus,
        ISNULL(TRY_CAST(cd.tdsAmount AS DECIMAL(18,2)), 0.00) AS tdsAmount,
        ISNULL(TRY_CAST(cd.tdsper AS DECIMAL(18,2)), 0.00) AS tdsper,
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
        SELECT TOP 1 PointValue, CashValue 
        FROM PointConversionRate WITH (NOLOCK)
        WHERE Comp_ID = cd.Comp_id 
          AND (Service_ID = cd.Service_ID OR Service_ID IS NULL OR Service_ID = '')
          AND IsActive = 1
        ORDER BY CASE WHEN Service_ID = cd.Service_ID THEN 0 ELSE 1 END, ConversionID DESC
    ) pcr
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
    DROP TABLE IF EXISTS #ReqConsumers, #ConsumerMapping, #UniqueScans, #EarnedPoints, #ConfigPoints, #Benefit, #OtherEarnedPoints, #Referrals, #Claims, #BPoints, #Transactions, #Paytm, #UPI, #ConsumerPoints;

    SELECT DISTINCT RIGHT(f.MobileNo, 10) AS Mobile10, f.CompId, mc.M_Consumerid AS Active_ConsumerId
    INTO #ReqConsumers
    FROM #FinalData f
    OUTER APPLY (
        SELECT TOP 1 M_Consumerid
        FROM M_Consumer WITH (NOLOCK)
        WHERE RIGHT(MobileNo, 10) = RIGHT(f.MobileNo, 10) AND IsDelete = 0
        ORDER BY M_Consumerid DESC
    ) mc
    WHERE f.MobileNo IS NOT NULL AND LTRIM(RTRIM(f.MobileNo)) <> '';

    -- Consumer Mapping for all historical / duplicate M_ConsumerId per MobileNo
    SELECT DISTINCT 
        mc.M_ConsumerId, 
        rc.Active_ConsumerId, 
        rc.Mobile10, 
        rc.CompId
    INTO #ConsumerMapping
    FROM #ReqConsumers rc
    INNER JOIN M_Consumer mc WITH (NOLOCK) 
        ON RIGHT(mc.MobileNo, 10) = rc.Mobile10;

    CREATE CLUSTERED INDEX IX_ConsumerMapping_ConsumerId ON #ConsumerMapping(M_ConsumerId);
    CREATE INDEX IX_ConsumerMapping_Active ON #ConsumerMapping(Active_ConsumerId);

    CREATE TABLE #Benefit
    (
        Active_ConsumerId INT,
        CompId VARCHAR(50),
        Benefit DECIMAL(18,2)
    );
    CREATE CLUSTERED INDEX IX_Benefit_Active ON #Benefit(Active_ConsumerId, CompId);

    -- 1. Comp-1669 Isolated Points (Multi-Service Head & Assistant Mechanics matched to SP_BL_GetBeneficiariesReport)
    IF EXISTS (SELECT 1 FROM #ReqConsumers WHERE CompId = 'Comp-1669')
    BEGIN
        INSERT INTO #Benefit (Active_ConsumerId, CompId, Benefit)
        SELECT 
            CM.Active_ConsumerId,
            'Comp-1669' AS CompId,
            SUM(CAST(
                CASE 
                    WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10   -- old records: Points + 10%
                            ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))              -- new records: Points as-is
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10   -- old records: Cash + 10%
                            ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))              -- new records: Cash as-is
                        END
                    ELSE 0.00
                END
            AS DECIMAL(18,2))) AS Benefit
        FROM (
            SELECT BL.M_Consumerid, BL.Points, BL.Cash, BL.UpdateDate, BL.ServiceName
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
            WHERE BL.compid = 'Comp-1669'

            UNION ALL

            SELECT BL.M_Consumerid, BL.Points, BL.Cash, BL.UpdateDate, BL.ServiceName
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
            INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
                ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
            INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
                ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
            INNER JOIN M_Code M WITH (NOLOCK) 
                ON MC.M_Codeid = M.Row_ID
            INNER JOIN Pro_Reg PR WITH (NOLOCK) 
                ON M.Pro_ID = PR.Pro_ID
            WHERE BL.compid IS NULL
              AND PR.Comp_ID = 'Comp-1669'
        ) BL
        INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId AND CM.CompId = 'Comp-1669'
        GROUP BY CM.Active_ConsumerId;
    END

    -- 2. Non-Comp-1669 Standard Points Calculation (100% Preserved)
    IF EXISTS (SELECT 1 FROM #ReqConsumers WHERE CompId <> 'Comp-1669')
    BEGIN
        SELECT 
            CM.Mobile10,
            CM.Active_ConsumerId,
            CM.CompId,
            M.Row_ID AS M_Codeid,
            PE.Enq_Date,
            M.Pro_ID,
            M.Series_Order,
            M.Series_Serial,
            ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2, PE.Is_Success ORDER BY PE.Enq_Date) as rn
        INTO #UniqueScans
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN (SELECT DISTINCT Mobile10, Active_ConsumerId, CompId FROM #ConsumerMapping WHERE CompId <> 'Comp-1669') CM 
            ON RIGHT(PE.MobileNo, 10) = CM.Mobile10
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_ID = CM.CompId
        WHERE PE.Is_Success = '1';

        CREATE INDEX IX_US_MCode ON #UniqueScans(M_Codeid) WHERE rn = 1;

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
            INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId AND BL.compid = CM.CompId
            LEFT JOIN loyalty_calculation lc WITH (NOLOCK)
                ON lc.comp_id = BL.compid AND lc.isactive = 1 AND lc.isdelete = 0
            WHERE CM.CompId <> 'Comp-1669'

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
            INNER JOIN #ConsumerMapping CM ON MC.M_Consumerid = CM.M_ConsumerId AND PR.Comp_ID = CM.CompId
            LEFT JOIN loyalty_calculation lc WITH (NOLOCK)
                ON lc.comp_id = PR.Comp_ID AND lc.isactive = 1 AND lc.isdelete = 0
            WHERE BL.compid IS NULL
              AND CM.CompId <> 'Comp-1669'
        ) x
        GROUP BY x.M_Codeid, x.CompId;

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

        INSERT INTO #Benefit (Active_ConsumerId, CompId, Benefit)
        SELECT
            E.Active_ConsumerId,
            E.CompId,
            SUM(CASE WHEN ISNULL(P.Points, 0) > 0 THEN P.Points ELSE ISNULL(CP.ConfigPoints, 0) END) AS Benefit
        FROM #UniqueScans E
        LEFT JOIN #EarnedPoints P ON P.M_Codeid = E.M_Codeid AND P.CompId = E.CompId
        LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = E.M_Codeid AND CP.CompId = E.CompId
        WHERE E.rn = 1
        GROUP BY E.Active_ConsumerId, E.CompId;
    END

    -- 3. Other Earned Points (KYC, invoice rewards, etc.) - non-Comp-1669
    SELECT 
        CM.Active_ConsumerId,
        CM.CompId,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(lc.calculation_value, 0.0) / 100.0)
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS OtherPoints
    INTO #OtherEarnedPoints
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId AND BL.compid = CM.CompId
    LEFT JOIN loyalty_calculation lc WITH (NOLOCK) ON lc.comp_id = BL.compid AND lc.isactive = 1 AND lc.isdelete = 0
    WHERE BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND CM.CompId <> 'Comp-1669'
    GROUP BY CM.Active_ConsumerId, CM.CompId;

    -- 4. Referral Points
    SELECT 
        CM.Active_ConsumerId,
        CM.CompId,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * (1.00 + ISNULL(lc.calculation_value, 0.0) / 100.0)
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS ReferralPoints
    INTO #Referrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId AND BL.compid = CM.CompId
    LEFT JOIN loyalty_calculation lc WITH (NOLOCK) ON lc.comp_id = BL.compid AND lc.isactive = 1 AND lc.isdelete = 0
    WHERE LOWER(BL.ServiceName) IN ('refral', 'referral')
    GROUP BY CM.Active_ConsumerId, CM.CompId;

    -- 5. Claims (Redeemed)
    SELECT 
        rc.Mobile10,
        rc.CompId,
        SUM(CAST(CD.Amount AS DECIMAL(18,2))) AS Transferred
    INTO #Claims
    FROM #ReqConsumers rc
    INNER JOIN ClaimDetails CD WITH (NOLOCK) ON RIGHT(CD.Mobileno, 10) = rc.Mobile10 AND CD.Comp_id = rc.CompId
    WHERE CD.PaymentStatus = 'Success'
    GROUP BY rc.Mobile10, rc.CompId;

    -- 6. BPoints Debits
    SELECT 
        CM.Active_ConsumerId,
        BT.companyid AS CompId,
        SUM(CAST(ISNULL(BT.RedeemPoints, 0) AS DECIMAL(18,2))) AS BPointsDebited
    INTO #BPoints
    FROM BPointsTransaction BT WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON BT.RedeemBy = CM.M_ConsumerId
    WHERE BT.bpstatus IN ('Accepted', 'SUCCESS', 'Debit')
    GROUP BY CM.Active_ConsumerId, BT.companyid;

    -- 7. Transactions (Direct cash / wallet payouts)
    SELECT 
        CM.Active_ConsumerId,
        t.CompId,
        SUM(CAST(ISNULL(t.Amount, 0) AS DECIMAL(18,2))) AS TransactionsAmount
    INTO #Transactions
    FROM Transactions t WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON TRY_CAST(t.M_CounserID AS INT) = CM.M_ConsumerId
    WHERE t.Issuccess = 1
    GROUP BY CM.Active_ConsumerId, t.CompId;

    -- 8. Instant UPI Cash Transfers
    SELECT 
        rc.Mobile10,
        rc.CompId,
        SUM(TRY_CAST(t.Amount AS DECIMAL(18,2))) AS UPIAmount
    INTO #UPI
    FROM #ReqConsumers rc
    INNER JOIN tblUPITransactionDetails t WITH (NOLOCK) 
        ON RIGHT(t.MobileNo, 10) = rc.Mobile10 
       AND (t.Comp_Id = rc.CompId OR t.Comp_Id = REPLACE(rc.CompId, 'Comp-', ''))
    WHERE t.Status = 'Success'
      AND (rc.CompId = 'Comp-1669' OR LEN(ISNULL(t.Code1, '')) > 3)
    GROUP BY rc.Mobile10, rc.CompId;

    -- 9. Paytm Transactions (Isolated for Comp-1669)
    CREATE TABLE #Paytm
    (
        Active_ConsumerId INT,
        CompId VARCHAR(50),
        PaytmAmount DECIMAL(18,2)
    );

    IF EXISTS (SELECT 1 FROM #ReqConsumers WHERE CompId = 'Comp-1669')
    BEGIN
        INSERT INTO #Paytm (Active_ConsumerId, CompId, PaytmAmount)
        SELECT 
            CM.Active_ConsumerId,
            'Comp-1669' AS CompId,
            SUM(TRY_CAST(ISNULL(pt.Amount, 0) AS DECIMAL(18,2))) AS PaytmAmount
        FROM paytmtransaction pt WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON pt.M_Consumerid = CM.M_ConsumerId AND CM.CompId = 'Comp-1669'
        WHERE pt.compid = 'Comp-1669'
          AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
        GROUP BY CM.Active_ConsumerId;
    END

    -- 10. Combine into #ConsumerPoints
    SELECT rc.Mobile10, rc.CompId,
        (ISNULL(b.Benefit, 0) + ISNULL(o.OtherPoints, 0) + ISNULL(r.ReferralPoints, 0)) AS TotalEarnedPoints,
        CASE 
            WHEN rc.CompId = 'Comp-1669' THEN (ISNULL(pt.PaytmAmount, 0) + ISNULL(upi.UPIAmount, 0))
            ELSE (ISNULL(c.Transferred, 0) + ISNULL(upi.UPIAmount, 0) + ISNULL(bp.BPointsDebited, 0) + ISNULL(t.TransactionsAmount, 0))
        END AS TotalRedeemedPoints
    INTO #ConsumerPoints
    FROM #ReqConsumers rc
    LEFT JOIN #Benefit b ON b.Active_ConsumerId = rc.Active_ConsumerId AND b.CompId = rc.CompId
    LEFT JOIN #OtherEarnedPoints o ON o.Active_ConsumerId = rc.Active_ConsumerId AND o.CompId = rc.CompId
    LEFT JOIN #Referrals r ON r.Active_ConsumerId = rc.Active_ConsumerId AND r.CompId = rc.CompId
    LEFT JOIN #Claims c ON c.Mobile10 = rc.Mobile10 AND c.CompId = rc.CompId
    LEFT JOIN #BPoints bp ON bp.Active_ConsumerId = rc.Active_ConsumerId AND (bp.CompId = rc.CompId OR bp.CompId = REPLACE(rc.CompId, 'Comp-', ''))
    LEFT JOIN #Transactions t ON t.Active_ConsumerId = rc.Active_ConsumerId AND (t.CompId = rc.CompId OR t.CompId = REPLACE(rc.CompId, 'Comp-', ''))
    LEFT JOIN #UPI upi ON upi.Mobile10 = rc.Mobile10 AND upi.CompId = rc.CompId
    LEFT JOIN #Paytm pt ON pt.Active_ConsumerId = rc.Active_ConsumerId AND pt.CompId = rc.CompId;

    UPDATE f
    SET 
        f.TotalEarnedPoints = ISNULL(cp.TotalEarnedPoints, 0),
        f.TotalRedeemedPoints = ISNULL(cp.TotalRedeemedPoints, 0),
        f.BalancePoints = ISNULL(cp.TotalEarnedPoints, 0) - ISNULL(cp.TotalRedeemedPoints, 0)
    FROM #FinalData f
    LEFT JOIN #ConsumerPoints cp ON RIGHT(f.MobileNo, 10) = cp.Mobile10 AND f.CompId = cp.CompId;

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
