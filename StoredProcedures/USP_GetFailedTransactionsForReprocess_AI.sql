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
    -- (Pairs them chronologically by Comp_id, MobileNo, Amount and attempts on the same day)
    -- =========================================================================
    WITH UT_Ranked AS (
        SELECT Id, Comp_Id, MobileNo, Amount, OrderId, Remarks, Status, ReqDate, account_no,
               ROW_NUMBER() OVER(PARTITION BY Comp_Id, MobileNo, Amount, CAST(ReqDate AS DATE) ORDER BY ReqDate ASC) as AttemptNum
        FROM tblUPITransactionDetails
        WHERE Comp_Id = @Comp_ID OR @Comp_ID IS NULL
    ),
    CD_Ranked AS (
        SELECT Row_id, Comp_id, Mobileno, Amount, Isapproved, PaymentStatus, Claim_date,
               ROW_NUMBER() OVER(PARTITION BY Comp_id, Mobileno, Amount, CAST(Claim_date AS DATE) ORDER BY Claim_date ASC) as AttemptNum
        FROM ClaimDetails
        WHERE Comp_id = @Comp_ID OR @Comp_ID IS NULL
    ),
    MatchedSuccess AS (
        SELECT CD.Row_id, UT.OrderId, UT.Remarks, UT.ReqDate, UT.Status, UT.account_no, UT.Amount
        FROM UT_Ranked UT
        INNER JOIN CD_Ranked CD 
           ON UT.Comp_Id = CD.Comp_id
          AND UT.MobileNo = CD.Mobileno
          AND UT.Amount = CD.Amount
          AND UT.AttemptNum = CD.AttemptNum
        WHERE UT.Status = 'Success'
          AND CD.Isapproved <> 1
    )
    UPDATE CD
    SET CD.Isapproved = 1,
        CD.PaymentStatus = M.Status,
        CD.PaymentRemarks = M.Remarks,
        CD.BankRefID = M.OrderId,
        CD.TransactionDate = CONVERT(VARCHAR(30), M.ReqDate, 120),
        CD.vendor_comment = CASE WHEN M.account_no IS NOT NULL AND M.account_no <> '' THEN 'IMPS Claim' ELSE 'UPI Claim' END,
        CD.Points_Redeemed = CAST(M.Amount AS INT)
    FROM ClaimDetails CD
    INNER JOIN MatchedSuccess M ON CD.Row_id = M.Row_id;

    -- =========================================================================
    -- STEP 0.2: Auto-Reject other duplicate ClaimDetails attempts
    -- If a successful record exists, make sure other records on the same day are marked as Rejected (Isapproved = 2)
    -- =========================================================================
    WITH SuccessClaims AS (
        SELECT Comp_id, Mobileno, Amount, Row_id, Claim_date
        FROM ClaimDetails
        WHERE Isapproved = 1
          AND (Comp_id = @Comp_ID OR @Comp_ID IS NULL)
    )
    UPDATE CD
    SET CD.Isapproved = 2,
        CD.PaymentStatus = 'Failed',
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
    -- STEP 2: Auto-Reject duplicate failed claims for Non-Coupon/Manual Payouts
    -- If a Success record exists for the same consumer + amount in a 24h window,
    -- mark duplicate failed attempts as 'Cancelled'
    -- =========================================================================
    UPDATE UT
    SET UT.Status = 'Cancelled',
        UT.FinalStatus = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful manual payout'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND UT.Comp_Id = @Comp_ID
      AND (ISNULL(UT.Code1, '0') = '0' OR ISNULL(UT.Code2, '0') = '0')
      AND EXISTS (
          SELECT 1 FROM tblUPITransactionDetails UT2
          WHERE UT2.M_Consumerid = UT.M_Consumerid 
            AND UT2.Status = 'Success'
            AND UT2.Amount = UT.Amount
            AND UT2.ReqDate BETWEEN DATEADD(hour, -24, UT.ReqDate) AND DATEADD(hour, 24, UT.ReqDate)
            AND UT2.Id <> UT.Id
      );

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
