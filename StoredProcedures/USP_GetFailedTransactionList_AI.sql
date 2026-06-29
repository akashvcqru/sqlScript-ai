USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetFailedTransactionList_AI]    Script Date: 5/13/2026 5:21:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Stored Procedure: USP_GetFailedTransactionList_AI
-- Purpose: Retrieves detailed list of failed transactions for reporting.
-- Used By: ReprocessTransactionService (Failed Transaction List API)
-- ====================================================================
ALTER   PROCEDURE [dbo].[USP_GetFailedTransactionList_AI]
    @Comp_ID    VARCHAR(50)  = NULL,
    @datePreset VARCHAR(50)  = NULL,
    @FromDate   VARCHAR(50)  = NULL,
    @ToDate     VARCHAR(50)  = NULL,
    @IsExport   BIT          = 0,
    @Search     VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- =========================================================================
    -- PRE-STEP 1: Auto-Cancel Failed records for Non-Coupon/Manual Payouts
    -- where the claim is already paid.
    -- Matches tblUPITransactionDetails (Failed) against ClaimDetails (Success)
    -- by Comp_Id + MobileNo + Amount. Ensures these never appear in the list.
    -- Sets FinalRemarks = 'Duplicate attempt of successful coupon claim'
    -- =========================================================================
    UPDATE UT
    SET UT.Status      = 'Cancelled',
        UT.FinalStatus  = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful coupon claim'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND (UT.Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
      AND (ISNULL(NULLIF(LTRIM(RTRIM(UT.Code1)), '0'), '') = '' OR ISNULL(NULLIF(LTRIM(RTRIM(UT.Code2)), '0'), '') = '')
      AND Remarks IN (
          'Insufficient wallet balance for debit'
         ,'Service Provider Downtime'
         ,'Insufficient Wallet Balance'
         ,'BENEFICIARY BANK IS DOWN'
         ,'Beneficiary Bank is not responding, try again later'
         ,'TRANSACTION TYPE NOT SUPPORTED'
		 ,'Invalid Account Number'
      )
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
    -- PRE-STEP 2: Auto-Reject duplicate failed claims for 13-Digit Coupons
    -- If a Success record exists for this code, mark all failed attempts as 'Cancelled'
    -- =========================================================================
    UPDATE UT
    SET UT.Status = 'Cancelled',
        UT.FinalStatus = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful coupon claim'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND (UT.Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
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
    -- PRE-STEP 3: Auto-Cancel failed Coupon check transaction records where the user
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

    SELECT         Id, 
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
		FinalStatus,
		 ReqDate
    FROM tblUPITransactionDetails 
    WHERE Status = 'Failed'
      AND Remarks IN (
          'Insufficient wallet balance for debit'
         ,'Service Provider Downtime'
         ,'Insufficient Wallet Balance'
         ,'BENEFICIARY BANK IS DOWN'
         ,'Beneficiary Bank is not responding, try again later'
         ,'TRANSACTION TYPE NOT SUPPORTED'
		 ,'Invalid Account Number'
      )
      AND LEN(Code1) = 5 AND LEN(Code2) = 8
      AND Comp_Id = @Comp_ID
      AND ReqDate > '2026-05-10 00:00:17.100'
      -- Date range filter (from @FromDate / @ToDate or @datePreset)
      AND (
          @FromDate IS NULL
          OR CAST(ReqDate AS DATE) >= CAST(@FromDate AS DATE)
      )
      AND (
          @ToDate IS NULL
          OR CAST(ReqDate AS DATE) <= CAST(@ToDate AS DATE)
      )
      -- Search filter on mobile number or consumer name
      AND (
          @Search IS NULL
          OR MobileNo LIKE '%' + @Search + '%'
          OR ConsumerName LIKE '%' + @Search + '%'
      )
    ORDER BY Id ASC;
END;
