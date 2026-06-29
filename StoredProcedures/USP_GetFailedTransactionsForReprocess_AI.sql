USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetFailedTransactionsForReprocess_AI]    Script Date: 5/13/2026 4:45:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================================================
-- Stored Procedure: USP_GetFailedTransactionsForReprocess_AI
-- Purpose: Retrieves failed transaction records waiting to be reprocessed.
-- Used By: ReprocessTransactionService (Scenario 1 Execution)
-- ====================================================================
ALTER   PROCEDURE [dbo].[USP_GetFailedTransactionsForReprocess_AI]
    @Comp_ID VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- STEP 0.1: Sync ClaimDetails with successful tblUPITransactionDetails records
    -- Uses NEAREST TIMESTAMP matching to correctly pair records regardless of order
    -- =========================================================================
    WITH SuccessUT AS (
        SELECT Id, Comp_Id, MobileNo, Amount, OrderId, Remarks, Status, ReqDate, account_no
        FROM tblUPITransactionDetails
        WHERE Status = 'Success'
          AND (Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
    ),
    NearestMatch AS (
        -- For each successful UT record, find the ClaimDetails record closest in time (that is not already success)
        SELECT 
            UT.Id AS UT_Id,
            UT.OrderId, UT.Remarks, UT.ReqDate, UT.Status, UT.account_no, UT.Amount,
            NEAREST.Row_id AS CD_RowId
        FROM SuccessUT UT
        CROSS APPLY (
            SELECT TOP 1 Row_id
            FROM ClaimDetails CD
            WHERE CD.Comp_id = UT.Comp_Id
              AND CD.Mobileno = UT.MobileNo
              AND CD.Amount = UT.Amount
              AND CD.Isapproved <> 1
            ORDER BY ABS(DATEDIFF(second, UT.ReqDate, CD.Claim_date)) ASC
        ) NEAREST
    )
    UPDATE CD
    SET CD.Isapproved = 1,
        CD.PaymentStatus = 'Success',
        CD.PaymentRemarks = M.Remarks,
        CD.BankRefID = M.OrderId,
        CD.TransactionDate = CONVERT(VARCHAR(30), M.ReqDate, 120),
        -- vendor_comment = gateway remarks (e.g. 'Transaction Successful'), fallback to claim type
        CD.vendor_comment = ISNULL(NULLIF(M.Remarks, ''), CASE WHEN M.account_no IS NOT NULL AND M.account_no <> '' THEN 'IMPS Claim' ELSE 'UPI Claim' END),
        CD.Points_Redeemed = CAST(M.Amount AS INT)
    FROM ClaimDetails CD
    INNER JOIN NearestMatch M ON CD.Row_id = M.CD_RowId;

    -- =========================================================================
    -- STEP 0.2: Auto-Reject other duplicate ClaimDetails attempts
    -- If a successful record exists, mark all other records on same day as Rejected
    -- =========================================================================
    WITH SuccessClaims AS (
        SELECT Comp_id, Mobileno, Amount, Row_id, Claim_date
        FROM ClaimDetails
        WHERE Isapproved = 1
          AND (Comp_id = @Comp_ID OR @Comp_ID IS NULL)
    )
    UPDATE CD
    SET CD.Isapproved = 2,
        CD.PaymentStatus = 'Rejected',
        CD.PaymentRemarks = 'Duplicate attempt of successful claim'
    FROM ClaimDetails CD
    INNER JOIN SuccessClaims SC 
       ON CD.Comp_id = SC.Comp_id
      AND CD.Mobileno = SC.Mobileno
      AND CD.Amount = SC.Amount
      AND CD.Row_id <> SC.Row_id
      AND CAST(CD.Claim_date AS DATE) = CAST(SC.Claim_date AS DATE)
    WHERE CD.Isapproved <> 2;

    -- =========================================================================
    -- STEP 1: Auto-Reject duplicate failed claims for 13-Digit Coupons
    -- If a Success record exists for this code, mark all failed attempts as 'Cancelled'
    -- =========================================================================
    UPDATE UT
    SET UT.Status = 'Cancelled',
        UT.FinalStatus = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful coupon claim'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND UT.Comp_Id = @Comp_ID
      AND ISNULL(UT.Code1, '0') <> '0' 
      AND ISNULL(UT.Code2, '0') <> '0' 
      AND LEN(UT.Code1) = 5 
      AND LEN(UT.Code2) = 8
      AND EXISTS (
          SELECT 1 FROM tblUPITransactionDetails UT2
          WHERE UT2.Code1 = UT.Code1 
            AND UT2.Code2 = UT.Code2
            AND UT2.Status = 'Success'
            AND UT2.Id <> UT.Id
      );

    -- =========================================================================
    -- STEP 2: Auto-Cancel duplicate failed claims for Non-Coupon/Manual Payouts
    -- If a Success record exists for the same consumer + amount in a 24h window,
    -- mark duplicate failed attempts as 'Cancelled'
    -- =========================================================================
    UPDATE UT
    SET UT.Status      = 'Cancelled',
        UT.FinalStatus  = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful manual payout'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND (UT.Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
      AND (ISNULL(UT.Code1, '0') = '0' OR ISNULL(UT.Code2, '0') = '0')
      AND EXISTS (
          SELECT 1 FROM tblUPITransactionDetails UT2
          WHERE UT2.Status = 'Success'
            AND UT2.Amount = UT.Amount
            AND UT2.Id    <> UT.Id
            AND (
                -- Match by consumer ID (preferred)
                UT2.M_Consumerid = UT.M_Consumerid
                OR
                -- Fallback: match by mobile number if consumer ID is same or missing
                UT2.MobileNo = UT.MobileNo
            )
            AND UT2.ReqDate BETWEEN DATEADD(hour, -24, UT.ReqDate)
                                AND DATEADD(hour,  24, UT.ReqDate)
      );

    -- =========================================================================
    -- STEP 2.5: Auto-Cancel failed UPI transaction records where the claim has
    -- already been successfully paid (confirmed via ClaimDetails.PaymentStatus).
    -- This handles cases where STEP 1 & 2 miss records because Code1/Code2 are
    -- blank/zero, or the success record falls outside the 24h window.
    -- =========================================================================
    UPDATE UT
    SET UT.Status      = 'Cancelled',
        UT.FinalStatus  = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful coupon claim'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND (UT.Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
      AND (ISNULL(NULLIF(LTRIM(RTRIM(UT.Code1)), '0'), '') = '' OR ISNULL(NULLIF(LTRIM(RTRIM(UT.Code2)), '0'), '') = '')
      AND EXISTS (
          SELECT 1
          FROM ClaimDetails CD
          WHERE CD.Comp_id  = UT.Comp_Id
            AND CD.Mobileno = UT.MobileNo
            AND CD.Amount   = UT.Amount
            AND CD.PaymentStatus = 'Success'
            AND CD.Isapproved    = 1
      );

    -- =========================================================================
    -- STEP 2.7: Auto-Cancel failed Coupon check transaction records where the user
    -- has already successfully claimed/redeemed the amount via manual payout.
    -- Uses running totals to ensure we only cancel failed transactions up to the
    -- cumulative successfully claimed amount, and only for claims requested after
    -- the failed transaction date.
    -- =========================================================================
    ;WITH FailedCouponTxns AS (
        SELECT 
            Id,
            MobileNo,
            Comp_Id,
            Amount,
            ReqDate,
            SUM(Amount) OVER (PARTITION BY MobileNo, Comp_Id ORDER BY Id ASC) AS CumulativeFailed
        FROM tblUPITransactionDetails
        WHERE Status = 'Failed'
          AND ISNULL(Code1, '0') <> '0'
          AND ISNULL(Code2, '0') <> '0'
          AND LEN(Code1) = 5
          AND LEN(Code2) = 8
          AND (Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
    ),
    SuccessfulManualPayouts AS (
        SELECT 
            Id,
            MobileNo,
            Comp_Id,
            Amount,
            ReqDate,
            SUM(Amount) OVER (PARTITION BY MobileNo, Comp_Id ORDER BY Id ASC) AS CumulativePaid
        FROM tblUPITransactionDetails
        WHERE Status = 'Success'
          AND (ISNULL(NULLIF(LTRIM(RTRIM(Code1)), '0'), '') = '' OR ISNULL(NULLIF(LTRIM(RTRIM(Code2)), '0'), '') = '')
          AND (Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
    ),
    Matched AS (
        SELECT 
            F.Id
        FROM FailedCouponTxns F
        INNER JOIN SuccessfulManualPayouts P
           ON P.MobileNo = F.MobileNo 
          AND P.Comp_Id = F.Comp_Id
          AND P.ReqDate >= F.ReqDate
          AND P.CumulativePaid >= F.CumulativeFailed
    )
    UPDATE UT
    SET UT.Status      = 'Cancelled',
        UT.FinalStatus  = 'CANCELLED',
        UT.FinalRemarks = 'Claimed via manual payout'
    FROM tblUPITransactionDetails UT
    INNER JOIN Matched M ON UT.Id = M.Id;

    -- =========================================================================
    -- STEP 3: Select remaining genuine failed transactions for reprocessing
    -- =========================================================================
    SELECT 
        Id, 
        Comp_Id, 
        M_Consumerid, 
        MobileNo, 
        ConsumerName, 
        ConsumerEmailId, 
        Code1, 
        Code2, 
        Amount, 
        UPI_Id, 
        account_no, 
        ifsc_code, 
        benef_name,
		Remarks,
		FinalRemarks,
		FinalStatus
    FROM tblUPITransactionDetails 
    WHERE Status = 'Failed' and Remarks in(
	'Insufficient wallet balance for debit'
	,'Service Provider Downtime'
	,'Insufficient Wallet Balance'
	,'BENEFICIARY BANK IS DOWN',
	'Beneficiary Bank is not responding, try again later'
	,'TRANSACTION TYPE NOT SUPPORTED'
	) and LEN(Code1)=5 and LEN(Code2)=8
	and Comp_Id=@Comp_ID
      AND ReqDate >'2026-05-10 00:00:17.100'
    ORDER BY Id ASC;
END;
