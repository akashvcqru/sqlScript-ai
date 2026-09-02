USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_FailedTransactionSummaryAdmin_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Migration: 20260902_Deduplicate_SP_FailedTransactionSummaryAdmin_AI.sql
-- Purpose: Remove duplicate transactions from FailedTransactionSummary:
--          1. Excludes transactions marked 'Duplicate Transaction' or '%Duplicate%'.
--          2. Excludes coupon records where ANY transaction with that Code1 & Code2 succeeded.
--          3. Excludes non-coupon records where ClaimDetails or tblUPITransactionDetails has a successful payout.
--          4. Deduplicates multiple retry attempts for coupons and non-coupons, keeping only the latest.
--          5. Adds CompleteCode (Code1 + Code2 merged).
--          6. If account_no is null or blank, falls back to UPI_Id.
--          7. Removes unused/null Service_ID and tblCashWalletBalance outer apply.
-- ====================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_FailedTransactionSummaryAdmin_AI]
    @CompId       NVARCHAR(50) = NULL,
    @Search       NVARCHAR(100) = NULL,
    @DatePreset   NVARCHAR(50) = NULL,
    @FromDate     DATETIME = NULL,
    @ToDate       DATETIME = NULL,
    @Offset       INT = 0,
    @Limit        INT = 10,
    @IsExport     BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Explicit Date Range overrides DatePreset
    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
        BEGIN
            SET @DatePreset = UPPER(LTRIM(RTRIM(@DatePreset)));
            
            IF @DatePreset = 'TODAY'
            BEGIN
                SET @StartDate = CAST(GETDATE() AS DATE);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset IN ('LASTDAY', 'YESTERDAY')
            BEGIN
                SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
                SET @EndDate   = CAST(GETDATE() AS DATE);
            END
            ELSE IF @DatePreset = 'WEEK'
            BEGIN
                SET DATEFIRST 1;
                SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTWEEK'
            BEGIN
                SET DATEFIRST 1;
                SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'MONTH'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTMONTH'
            BEGIN
                SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'QUARTER'
            BEGIN
                SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'YEAR'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTYEAR'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset IN ('ALL', 'NULL')
            BEGIN
                SET @StartDate = NULL;
                SET @EndDate   = NULL;
            END
        END
    END

    -- Total count query (only executed when not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(1) AS TotalRecords
        FROM (
            SELECT 
                u.Id,
                ROW_NUMBER() OVER (
                    PARTITION BY 
                        CASE 
                            WHEN ISNULL(u.Code1, '0') <> '0' AND ISNULL(u.Code2, '0') <> '0' 
                            THEN u.Comp_Id + '_' + u.Code1 + '_' + u.Code2
                            ELSE u.Comp_Id + '_' + u.MobileNo + '_' + CAST(u.Amount AS VARCHAR(30)) + '_' + ISNULL(u.account_no, ISNULL(u.UPI_Id, '')) + '_' + CONVERT(VARCHAR(10), u.ReqDate, 120)
                        END
                    ORDER BY u.ReqDate DESC, u.Id DESC
                ) AS rn
            FROM tblUPITransactionDetails u WITH (NOLOCK)
            WHERE (
                ISNULL(u.Status, '') NOT IN ('Success', 'Cancelled', 'CANCELLED')
                OR (
                    u.OrderId LIKE 'TXN[2][0][2-9][0-9]%'
                    AND LEN(u.OrderId) = 17
                )
            )
              AND ISNULL(u.Status, '') NOT IN ('Cancelled', 'CANCELLED')
              AND ISNULL(u.FinalStatus, '') NOT IN ('Cancelled', 'CANCELLED')
              AND ISNULL(u.Remarks, '') <> 'Duplicate Transaction'
              AND ISNULL(u.FinalRemarks, '') NOT LIKE '%Duplicate%'
              AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'ALL' OR u.Comp_Id = @CompId)
              AND (@StartDate IS NULL OR u.ReqDate >= @StartDate)
              AND (@EndDate IS NULL OR u.ReqDate < @EndDate)
              AND (
                  @Search IS NULL OR @Search = ''
                  OR u.MobileNo LIKE '%' + @Search + '%'
                  OR u.ConsumerName LIKE '%' + @Search + '%'
                  OR u.Code1 LIKE '%' + @Search + '%'
                  OR u.Code2 LIKE '%' + @Search + '%'
                  OR (u.Code1 + u.Code2) LIKE '%' + @Search + '%'
                  OR u.Comp_Id LIKE '%' + @Search + '%'
                  OR u.UPI_Id LIKE '%' + @Search + '%'
                  OR u.account_no LIKE '%' + @Search + '%'
                  OR u.ifsc_code LIKE '%' + @Search + '%'
                  OR u.Remarks LIKE '%' + @Search + '%'
                  OR u.FinalRemarks LIKE '%' + @Search + '%'
                  OR CAST(u.Id AS VARCHAR(20)) LIKE '%' + @Search + '%'
                  OR EXISTS (SELECT 1 FROM Comp_Reg cr WITH (NOLOCK) WHERE cr.Comp_ID = u.Comp_Id AND cr.Comp_Name LIKE '%' + @Search + '%')
              )
              AND NOT (
                  ISNULL(u.Code1, '0') <> '0' AND ISNULL(u.Code2, '0') <> '0'
                  AND EXISTS (
                      SELECT 1 FROM tblUPITransactionDetails s WITH (NOLOCK)
                      WHERE s.Code1 = u.Code1 AND s.Code2 = u.Code2 AND s.Status = 'Success'
                  )
              )
              AND NOT (
                  (ISNULL(u.Code1, '0') = '0' OR ISNULL(u.Code2, '0') = '0')
                  AND EXISTS (
                      SELECT 1 FROM ClaimDetails CD WITH (NOLOCK)
                      WHERE CD.Comp_id = u.Comp_Id
                        AND CD.Mobileno = u.MobileNo
                        AND CD.Amount = u.Amount
                        AND CD.PaymentStatus = 'Success'
                        AND CD.Isapproved = 1
                        AND CAST(CD.Claim_date AS DATE) = CAST(u.ReqDate AS DATE)
                  )
              )
              AND NOT (
                  (ISNULL(u.Code1, '0') = '0' OR ISNULL(u.Code2, '0') = '0')
                  AND EXISTS (
                      SELECT 1 FROM tblUPITransactionDetails s2 WITH (NOLOCK)
                      WHERE s2.Comp_Id = u.Comp_Id
                        AND s2.MobileNo = u.MobileNo
                        AND s2.Amount = u.Amount
                        AND s2.Status = 'Success'
                        AND CAST(s2.ReqDate AS DATE) = CAST(u.ReqDate AS DATE)
                        AND s2.Id <> u.Id
                  )
              )
        ) t
        WHERE t.rn = 1;
    END

    -- Data result set
    ;WITH FilteredTxns AS (
        SELECT 
            u.Id,
            u.Comp_Id,
            u.MobileNo,
            u.ConsumerName,
            u.Code1,
            u.Code2,
            u.Amount,
            u.Status,
            u.Remarks,
            u.FinalStatus,
            u.FinalRemarks,
            u.ReqDate,
            u.ifsc_code,
            u.account_no,
            u.UPI_Id,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    CASE 
                        WHEN ISNULL(u.Code1, '0') <> '0' AND ISNULL(u.Code2, '0') <> '0' 
                        THEN u.Comp_Id + '_' + u.Code1 + '_' + u.Code2
                        ELSE u.Comp_Id + '_' + u.MobileNo + '_' + CAST(u.Amount AS VARCHAR(30)) + '_' + ISNULL(u.account_no, ISNULL(u.UPI_Id, '')) + '_' + CONVERT(VARCHAR(10), u.ReqDate, 120)
                    END
                ORDER BY u.ReqDate DESC, u.Id DESC
            ) AS rn
        FROM tblUPITransactionDetails u WITH (NOLOCK)
        WHERE (
            ISNULL(u.Status, '') NOT IN ('Success', 'Cancelled', 'CANCELLED')
            OR (
                u.OrderId LIKE 'TXN[2][0][2-9][0-9]%'
                AND LEN(u.OrderId) = 17
            )
        )
          AND ISNULL(u.Status, '') NOT IN ('Cancelled', 'CANCELLED')
          AND ISNULL(u.FinalStatus, '') NOT IN ('Cancelled', 'CANCELLED')
          AND ISNULL(u.Remarks, '') <> 'Duplicate Transaction'
          AND ISNULL(u.FinalRemarks, '') NOT LIKE '%Duplicate%'
          AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'ALL' OR u.Comp_Id = @CompId)
          AND (@StartDate IS NULL OR u.ReqDate >= @StartDate)
          AND (@EndDate IS NULL OR u.ReqDate < @EndDate)
          AND (
              @Search IS NULL OR @Search = ''
              OR u.MobileNo LIKE '%' + @Search + '%'
              OR u.ConsumerName LIKE '%' + @Search + '%'
              OR u.Code1 LIKE '%' + @Search + '%'
              OR u.Code2 LIKE '%' + @Search + '%'
              OR (u.Code1 + u.Code2) LIKE '%' + @Search + '%'
              OR u.Comp_Id LIKE '%' + @Search + '%'
              OR u.UPI_Id LIKE '%' + @Search + '%'
              OR u.account_no LIKE '%' + @Search + '%'
              OR u.ifsc_code LIKE '%' + @Search + '%'
              OR u.Remarks LIKE '%' + @Search + '%'
              OR u.FinalRemarks LIKE '%' + @Search + '%'
              OR CAST(u.Id AS VARCHAR(20)) LIKE '%' + @Search + '%'
              OR EXISTS (SELECT 1 FROM Comp_Reg cr WITH (NOLOCK) WHERE cr.Comp_ID = u.Comp_Id AND cr.Comp_Name LIKE '%' + @Search + '%')
          )
          AND NOT (
              ISNULL(u.Code1, '0') <> '0' AND ISNULL(u.Code2, '0') <> '0'
              AND EXISTS (
                  SELECT 1 FROM tblUPITransactionDetails s WITH (NOLOCK)
                  WHERE s.Code1 = u.Code1 AND s.Code2 = u.Code2 AND s.Status = 'Success'
              )
          )
          AND NOT (
              (ISNULL(u.Code1, '0') = '0' OR ISNULL(u.Code2, '0') = '0')
              AND EXISTS (
                  SELECT 1 FROM ClaimDetails CD WITH (NOLOCK)
                  WHERE CD.Comp_id = u.Comp_Id
                    AND CD.Mobileno = u.MobileNo
                    AND CD.Amount = u.Amount
                    AND CD.PaymentStatus = 'Success'
                    AND CD.Isapproved = 1
                    AND CAST(CD.Claim_date AS DATE) = CAST(u.ReqDate AS DATE)
              )
          )
          AND NOT (
              (ISNULL(u.Code1, '0') = '0' OR ISNULL(u.Code2, '0') = '0')
              AND EXISTS (
                  SELECT 1 FROM tblUPITransactionDetails s2 WITH (NOLOCK)
                  WHERE s2.Comp_Id = u.Comp_Id
                    AND s2.MobileNo = u.MobileNo
                    AND s2.Amount = u.Amount
                    AND s2.Status = 'Success'
                    AND CAST(s2.ReqDate AS DATE) = CAST(u.ReqDate AS DATE)
                    AND s2.Id <> u.Id
              )
          )
    ),
    DedupPage AS (
        SELECT *
        FROM FilteredTxns
        WHERE rn = 1
        ORDER BY ReqDate DESC, Id DESC
        OFFSET (CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END) ROWS
        FETCH NEXT (CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END) ROWS ONLY
    )
    SELECT 
        d.Id,
        d.Comp_Id,
        ISNULL(c.Comp_Name, d.Comp_Id) AS CompanyName,
        d.MobileNo,
        d.ConsumerName,
        CASE 
            WHEN ISNULL(d.Code1, '') <> '' AND ISNULL(d.Code2, '') <> '' AND d.Code1 <> '0' AND d.Code2 <> '0'
            THEN d.Code1 + d.Code2
            ELSE ISNULL(NULLIF(d.Code1, '0'), ISNULL(NULLIF(d.Code2, '0'), ''))
        END AS CompleteCode,
        d.Amount,
        d.Status,
        d.Remarks,
        d.FinalStatus,
        d.FinalRemarks,
        d.ReqDate,
        d.ifsc_code AS IfscCode,
        CASE 
            WHEN ISNULL(LTRIM(RTRIM(d.account_no)), '') <> '' THEN d.account_no
            ELSE NULLIF(LTRIM(RTRIM(d.UPI_Id)), '')
        END AS AccountNo,
        ISNULL(NULLIF(LTRIM(RTRIM(d.UPI_Id)), ''), d.account_no) AS [UPI/AC]
    FROM DedupPage d
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = d.Comp_Id
    ORDER BY d.ReqDate DESC, d.Id DESC;
END
GO
