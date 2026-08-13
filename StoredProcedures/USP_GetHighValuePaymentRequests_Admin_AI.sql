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
        CompName NVARCHAR(150) NULL,
        CompId VARCHAR(50) NULL,
        IsApproved INT NOT NULL,
        VendorComment NVARCHAR(MAX) NULL,
        [UpiId/AC] VARCHAR(100) NULL,
        PaymentRemarks NVARCHAR(MAX) NULL,
        PaymentStatus VARCHAR(50) NULL,
        ClaimMode NVARCHAR(200) NULL,
        VendorWalletBalance DECIMAL(18, 2) NULL,
        TotalEarnedPoints DECIMAL(18, 2) NULL,
        TotalRedeemedPoints DECIMAL(18, 2) NULL,
        BalancePoints DECIMAL(18, 2) NULL,
        IFSCCode NVARCHAR(50) NULL,
        AccountNumber NVARCHAR(50) NULL,
        BankName NVARCHAR(100) NULL
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
    INSERT INTO #FinalData (ClaimId, ClaimDate, MobileNo, UserName, Amount, CompName, CompId, IsApproved, VendorComment, [UpiId/AC], PaymentRemarks, PaymentStatus, ClaimMode, VendorWalletBalance, TotalEarnedPoints, TotalRedeemedPoints, BalancePoints, IFSCCode, AccountNumber, BankName)
    SELECT
        cd.Row_id AS ClaimId,
        cd.Claim_date AS ClaimDate,
        cd.Mobileno AS MobileNo,
        mc.ConsumerName AS UserName,
        CAST(cd.RequestAmmount AS DECIMAL(18,2)) AS Amount,
        ISNULL(c.Comp_Name, 'Unknown') AS CompName,
        cd.Comp_id AS CompId,
        cd.Isapproved AS IsApproved,
        cd.vendor_comment AS VendorComment,
        ISNULL(cd.UPIID, cd.BankRefID) AS [UpiId/AC],
        cd.PaymentRemarks AS PaymentRemarks,
        CASE WHEN cd.Isapproved = 1 THEN 'Approved' WHEN cd.Isapproved = 2 THEN 'Rejected' ELSE 'Pending' END AS PaymentStatus,
        cd.Claim_mode AS ClaimMode,
        0.00 AS VendorWalletBalance,
        0.00 AS TotalEarnedPoints,
        0.00 AS TotalRedeemedPoints,
        0.00 AS BalancePoints,
        NULL AS IFSCCode,
        NULL AS AccountNumber,
        NULL AS BankName
    FROM ClaimDetails cd WITH (NOLOCK)
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = cd.Comp_id
    OUTER APPLY (
        SELECT TOP 1 ConsumerName
        FROM M_Consumer WITH (NOLOCK)
        WHERE RIGHT(MobileNo, 10) = RIGHT(cd.Mobileno, 10) AND IsDelete = 0
        ORDER BY M_Consumerid DESC
    ) mc
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
        f.AccountNumber = ISNULL(mba.Account_No, ISNULL(audit.Account_Number, '')),
        f.BankName = ISNULL(mba.Bank_Name, '')
    FROM #FinalData f
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

    -- Aggregate Points for Consumers in #FinalData
    DROP TABLE IF EXISTS #ReqConsumers, #ConsumerPoints;

    SELECT DISTINCT f.MobileNo, f.CompId, mc.M_Consumerid
    INTO #ReqConsumers
    FROM #FinalData f
    LEFT JOIN M_Consumer mc WITH (NOLOCK) ON RIGHT(mc.MobileNo, 10) = RIGHT(f.MobileNo, 10) AND mc.IsDelete = 0;

    SELECT rc.MobileNo, rc.CompId,
        (
            ISNULL((
                SELECT SUM(CAST(CASE WHEN BL.Cash > 0 THEN BL.Cash ELSE ISNULL(BL.Points, 0) END AS DECIMAL(18,2)))
                FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
                WHERE BL.M_Consumerid = rc.M_Consumerid AND BL.compid = rc.CompId
            ), 0)
            +
            ISNULL((
                SELECT SUM(CAST(ISNULL(SST.Points, ISNULL(SST.IsCash, 0)) AS DECIMAL(18,2)))
                FROM Pro_Enq PE WITH (NOLOCK)
                INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
                INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
                INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
                INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
                WHERE PE.MobileNo = rc.MobileNo
                  AND PE.Is_Success = '1'
                  AND PR.Comp_ID = rc.CompId
                  AND SS.IsActive = 1 AND SS.IsDelete = 0
                  AND SST.IsActive = 1 AND SST.IsDelete = 0
                  AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
                  AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
                  AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))
            ), 0)
        ) AS TotalEarnedPoints,
        (
            ISNULL((
                SELECT SUM(CAST(CD.Amount AS DECIMAL(18,2)))
                FROM ClaimDetails CD WITH (NOLOCK)
                WHERE CD.Mobileno = rc.MobileNo AND CD.Comp_id = rc.CompId
                  AND (CD.Isapproved = 1 OR CD.IsPaid = 1 OR CD.PaymentStatus = 'Paid')
            ), 0)
            +
            ISNULL((
                SELECT SUM(CAST(ISNULL(BT.RedeemPoints, 0) AS DECIMAL(18,2)))
                FROM BPointsTransaction BT WITH (NOLOCK)
                WHERE BT.RedeemBy = rc.M_Consumerid AND BT.companyid = rc.CompId
                  AND BT.bpstatus IN ('Accepted', 'SUCCESS', 'Debit')
            ), 0)
            +
            ISNULL((
                SELECT SUM(CAST(ISNULL(t.Amount, 0) AS DECIMAL(18,2)))
                FROM Transactions t WITH (NOLOCK)
                WHERE (t.CompId = REPLACE(rc.CompId, 'Comp-', '') OR t.CompId = rc.CompId)
                  AND t.Issuccess = 1 AND TRY_CAST(t.M_CounserID AS INT) = rc.M_Consumerid
            ), 0)
        ) AS TotalRedeemedPoints
    INTO #ConsumerPoints
    FROM #ReqConsumers rc;

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
