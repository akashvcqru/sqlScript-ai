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
    -- PRE-STEP: Auto-Cancel Failed records where the claim is already paid.
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
      AND Remarks IN (
          'Insufficient wallet balance for debit'
         ,'Service Provider Downtime'
         ,'Insufficient Wallet Balance'
         ,'BENEFICIARY BANK IS DOWN'
         ,'Beneficiary Bank is not responding, try again later'
         ,'TRANSACTION TYPE NOT SUPPORTED'
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
