USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetFailedTransactionList_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Migration: 20260903_Add_OrderId_To_USP_GetFailedTransactionList_AI.sql
-- Purpose: Add OrderId from tblUPITransactionDetails to the SELECT list
--          and search filter conditions for /api/vendor/failedTransactions/FailedtransactionList.
-- ====================================================================
ALTER PROCEDURE [dbo].[USP_GetFailedTransactionList_AI]
    @Comp_ID    VARCHAR(50)  = NULL,
    @datePreset VARCHAR(50)  = NULL,
    @FromDate   VARCHAR(50)  = NULL,
    @ToDate     VARCHAR(50)  = NULL,
    @IsExport   BIT          = 0,
    @Search     VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 0. CLEAN / NORMALIZE INPUTS
    ---------------------------------------------------------
    SET @Comp_ID = NULLIF(LTRIM(RTRIM(@Comp_ID)), '');
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');

    DECLARE @ParsedFromDate DATETIME = NULL;
    DECLARE @ParsedToDate   DATETIME = NULL;

    -- Normalize datePreset if provided
    DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
    IF (@Win = '' OR @Win = 'NULL') SET @Win = 'ALL';

    -- Explicit date range overrides datePreset
    IF (ISNULL(@FromDate, '') <> '' AND ISNULL(@ToDate, '') <> '')
    BEGIN
        SET @ParsedFromDate = TRY_CAST(@FromDate AS DATETIME);
        SET @ParsedToDate   = TRY_CAST(@ToDate AS DATETIME);
    END
    ELSE IF (@Win = 'TODAY')
    BEGIN
        SET @ParsedFromDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
        SET @ParsedToDate   = @ParsedFromDate;
    END
    ELSE IF (@Win = 'LASTDAY' OR @Win = 'YESTERDAY')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @ParsedToDate   = @ParsedFromDate;
    END
    ELSE IF (@Win = 'WEEK')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @ParsedToDate   = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
    END
    ELSE IF (@Win = 'LASTWEEK')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(DAY, -(DATEPART(WEEKDAY, GETDATE()) + 6), CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @ParsedToDate   = CAST(DATEADD(DAY, -DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
    END
    ELSE IF (@Win = 'MONTH')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) AS DATETIME);
        SET @ParsedToDate   = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
    END
    ELSE IF (@Win = 'LASTMONTH')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0) AS DATETIME);
        SET @ParsedToDate   = CAST(EOMONTH(DATEADD(MONTH, -1, GETDATE())) AS DATETIME);
    END
    ELSE IF (@Win = 'QUARTER')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0) AS DATETIME);
        SET @ParsedToDate   = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
    END
    ELSE IF (@Win = 'YEAR')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0) AS DATETIME);
        SET @ParsedToDate   = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
    END
    ELSE IF (@Win = 'LASTYEAR')
    BEGIN
        SET @ParsedFromDate = CAST(DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) - 1, 0) AS DATETIME);
        SET @ParsedToDate   = CAST(DATEADD(DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)) AS DATETIME);
    END

    -- Baseline cutoff date to prevent unbounded historical scans
    DECLARE @CutoffDate DATETIME = '2026-05-10 00:00:17.100';

    -- =========================================================================
    -- PRE-STEP 1: Auto-Cancel Failed records for Non-Coupon/Manual Payouts
    -- Scoped strictly to @Comp_ID, @Search, date filters, and CutoffDate
    -- =========================================================================
    UPDATE UT
    SET UT.Status      = 'Cancelled',
        UT.FinalStatus  = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful coupon claim'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND (UT.Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
      AND UT.ReqDate > @CutoffDate
      AND (@ParsedFromDate IS NULL OR UT.ReqDate >= @ParsedFromDate)
      AND (@ParsedToDate IS NULL OR UT.ReqDate < DATEADD(DAY, 1, @ParsedToDate))
      AND (@Search IS NULL OR UT.OrderId LIKE '%' + @Search + '%' OR UT.MobileNo LIKE '%' + @Search + '%' OR UT.ConsumerName LIKE '%' + @Search + '%')
      AND (ISNULL(NULLIF(LTRIM(RTRIM(UT.Code1)), '0'), '') = '' OR ISNULL(NULLIF(LTRIM(RTRIM(UT.Code2)), '0'), '') = '')
      AND UT.Remarks IN (
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
          FROM ClaimDetails CD WITH (NOLOCK)
          WHERE CD.Comp_id  = UT.Comp_Id
            AND CD.Mobileno = UT.MobileNo
            AND CD.Amount   = UT.Amount
            AND CD.PaymentStatus = 'Success'
            AND CD.Isapproved    = 1
      );

    -- =========================================================================
    -- PRE-STEP 2: Auto-Reject duplicate failed claims for 13-Digit Coupons
    -- Scoped strictly to @Comp_ID, @Search, date filters, and CutoffDate
    -- =========================================================================
    UPDATE UT
    SET UT.Status = 'Cancelled',
        UT.FinalStatus = 'CANCELLED',
        UT.FinalRemarks = 'Duplicate attempt of successful coupon claim'
    FROM tblUPITransactionDetails UT
    WHERE UT.Status = 'Failed'
      AND (UT.Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
      AND UT.ReqDate > @CutoffDate
      AND (@ParsedFromDate IS NULL OR UT.ReqDate >= @ParsedFromDate)
      AND (@ParsedToDate IS NULL OR UT.ReqDate < DATEADD(DAY, 1, @ParsedToDate))
      AND (@Search IS NULL OR UT.OrderId LIKE '%' + @Search + '%' OR UT.MobileNo LIKE '%' + @Search + '%' OR UT.ConsumerName LIKE '%' + @Search + '%')
      AND ISNULL(UT.Code1, '0') <> '0' 
      AND ISNULL(UT.Code2, '0') <> '0' 
      AND LEN(UT.Code1) = 5 
      AND LEN(UT.Code2) = 8
      AND EXISTS (
          SELECT 1 FROM tblUPITransactionDetails UT2 WITH (NOLOCK)
          WHERE UT2.Code1 = UT.Code1 
            AND UT2.Code2 = UT.Code2
            AND UT2.Status = 'Success'
            AND UT2.Id <> UT.Id
      );

    -- =========================================================================
    -- PRE-STEP 3: Auto-Cancel failed Coupon check transaction records where the user
    -- has already successfully claimed/redeemed the amount via manual payout.
    -- Scoped strictly to @Comp_ID, @Search, date filters, and CutoffDate
    -- =========================================================================
    ;WITH FailedCouponTxns AS (
        SELECT 
            Id,
            OrderId,
            MobileNo,
            Comp_Id,
            Amount,
            ReqDate,
            SUM(Amount) OVER (PARTITION BY MobileNo, Comp_Id ORDER BY Id ASC) AS CumulativeFailed
        FROM tblUPITransactionDetails WITH (NOLOCK)
        WHERE Status = 'Failed'
          AND ReqDate > @CutoffDate
          AND (@ParsedFromDate IS NULL OR ReqDate >= @ParsedFromDate)
          AND (@ParsedToDate IS NULL OR ReqDate < DATEADD(DAY, 1, @ParsedToDate))
          AND (@Search IS NULL OR OrderId LIKE '%' + @Search + '%' OR MobileNo LIKE '%' + @Search + '%' OR ConsumerName LIKE '%' + @Search + '%')
          AND ISNULL(Code1, '0') <> '0'
          AND ISNULL(Code2, '0') <> '0'
          AND LEN(Code1) = 5
          AND LEN(Code2) = 8
          AND (Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
    ),
    SuccessfulManualPayouts AS (
        SELECT 
            Id,
            OrderId,
            MobileNo,
            Comp_Id,
            Amount,
            ReqDate,
            SUM(Amount) OVER (PARTITION BY MobileNo, Comp_Id ORDER BY Id ASC) AS CumulativePaid
        FROM tblUPITransactionDetails WITH (NOLOCK)
        WHERE Status = 'Success'
          AND ReqDate > @CutoffDate
          AND (ISNULL(NULLIF(LTRIM(RTRIM(Code1)), '0'), '') = '' OR ISNULL(NULLIF(LTRIM(RTRIM(Code2)), '0'), '') = '')
          AND (@Search IS NULL OR OrderId LIKE '%' + @Search + '%' OR MobileNo LIKE '%' + @Search + '%' OR ConsumerName LIKE '%' + @Search + '%')
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
    -- FINAL SELECT: Fast indexed seek with (NOLOCK)
    -- =========================================================================
    SELECT 
        UT.Id, 
        UT.OrderId,
        UT.Comp_Id, 
        UT.M_Consumerid, 
        UT.MobileNo, 
        UT.ConsumerName, 
        UT.ConsumerEmailId, 
        UT.Code1, 
        UT.Code2, 
        UT.Amount, 
        UT.UPI_Id, 
        CASE 
            WHEN ISNULL(MBA.Account_No, '') <> '' THEN MBA.Account_No
            WHEN ISNULL(UT.account_no, '') <> '' THEN UT.account_no
            ELSE ISNULL(MBAA.Account_No, '')
        END AS account_no, 
        CASE 
            WHEN ISNULL(MBA.Account_No, '') <> '' THEN MBA.IFSC_Code
            WHEN ISNULL(UT.account_no, '') <> '' THEN UT.ifsc_code
            ELSE ISNULL(MBAA.IFSC_Code, '')
        END AS ifsc_code, 
        CASE 
            WHEN ISNULL(MBA.Account_No, '') <> '' THEN MBA.Account_HolderNm
            WHEN ISNULL(UT.account_no, '') <> '' THEN UT.benef_name
            ELSE ISNULL(MBAA.Account_HolderNm, '')
        END AS benef_name,         
        UT.Remarks,
        UT.FinalRemarks,
        UT.FinalStatus,
        UT.ReqDate
    FROM tblUPITransactionDetails UT WITH (NOLOCK)
    OUTER APPLY (
        SELECT TOP 1 Account_No, IFSC_Code, Account_HolderNm 
        FROM dbo.M_BankAccount WITH (NOLOCK) 
        WHERE M_Consumerid = UT.M_Consumerid 
          AND ISNULL(Account_No, '') <> ''
        ORDER BY Row_ID DESC
    ) MBA
    OUTER APPLY (
        SELECT TOP 1 Account_No, IFSC_Code, Account_HolderNm 
        FROM dbo.M_BankAccount_Audit WITH (NOLOCK) 
        WHERE M_Consumerid = UT.M_Consumerid 
          AND ISNULL(Account_No, '') <> ''
        ORDER BY Row_ID DESC
    ) MBAA
    WHERE (
        (
            UT.Status = 'Failed'
            AND UT.Remarks IN (
                'Insufficient wallet balance for debit'
               ,'Service Provider Downtime'
               ,'Insufficient Wallet Balance'
               ,'BENEFICIARY BANK IS DOWN'
               ,'Beneficiary Bank is not responding, try again later'
               ,'TRANSACTION TYPE NOT SUPPORTED'
               ,'Invalid Account Number'
            )
        )
        OR (
            UT.OrderId LIKE 'TXN[2][0][2-9][0-9]%'
            AND LEN(UT.OrderId) = 17
        )
    )
      AND LEN(UT.Code1) = 5 
      AND LEN(UT.Code2) = 8
      AND (UT.Comp_Id = @Comp_ID OR @Comp_ID IS NULL)
      AND UT.ReqDate > @CutoffDate
      -- Sargable Date range filter
      AND (
          @ParsedFromDate IS NULL
          OR UT.ReqDate >= @ParsedFromDate
      )
      AND (
          @ParsedToDate IS NULL
          OR UT.ReqDate < DATEADD(DAY, 1, @ParsedToDate)
      )
      -- Search filter on mobile number, consumer name, code, etc.
      AND (
          @Search IS NULL
          OR UT.OrderId LIKE '%' + @Search + '%'
          OR UT.MobileNo LIKE '%' + @Search + '%'
          OR UT.ConsumerName LIKE '%' + @Search + '%'
          OR UT.Code1 LIKE '%' + @Search + '%'
          OR UT.Code2 LIKE '%' + @Search + '%'
          OR UT.UPI_Id LIKE '%' + @Search + '%'
          OR UT.account_no LIKE '%' + @Search + '%'
      )
    ORDER BY UT.ReqDate DESC;
END;
GO
