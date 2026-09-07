USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetNegativeBalancePendingUsers_AI]    Script Date: 9/7/2026 3:23:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[USP_GetNegativeBalancePendingUsers_AI]
(
    @Comp_ID         NVARCHAR(50),
    @DatePreset      NVARCHAR(20) = 'ALL',   -- TODAY, TOMORROW, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, YEAR, ALL, CUSTOM
    @FromDate        NVARCHAR(30) = NULL,
    @ToDate          NVARCHAR(30) = NULL,
    @Page            INT = 1,
    @Limit           INT = 10,
    @Search          NVARCHAR(100) = NULL,
    @IsExport        BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    
    -----------------------------------------
    -- Date Range
    -----------------------------------------
    DECLARE @StartDate DATETIME,
            @EndDate   DATETIME,
            @Preset    NVARCHAR(20);

    SET @Preset = UPPER(ISNULL(@DatePreset, 'ALL'));

    IF (@Preset = 'TODAY')
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'TOMORROW')
    BEGIN
        SET @StartDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 2, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'YESTERDAY' OR @Preset = 'LASTDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
        SET @EndDate   = CAST(GETDATE() AS DATE);
    END
    ELSE IF (@Preset = 'WEEK' OR @Preset = 'THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH' OR @Preset = 'MONTHS')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'YEAR' OR @Preset = 'THIS YEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE
    BEGIN
        SET @StartDate = CAST('2015-01-01 00:00:00.000' AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    -----------------------------------------
    -- Temp Data
    -----------------------------------------
    


	DECLARE @CRate DECIMAL(18,2) = 1.00;
 --add earnedpoints,Assinged points in 2nd table
 --job , for 7 comp sumary date()1 drill down , 2nd droll down , 3 drill down report , points 0 on some codes
--select @CRate = CashValue/PointValue from [dbo].[PointConversionRate] where Comp_ID = @Comp_ID and IsActive = 1
--select  @CRate
 --earned points ()
 
    IF OBJECT_ID('tempdb..#Summary') IS NOT NULL
        DROP TABLE #Summary;

/*============================================================
  Remove duplicate claim records first
============================================================*/
;WITH UniqueClaims AS
(
    SELECT
        c.*,
        
        ROW_NUMBER() OVER
        (
            PARTITION BY
                c.Comp_ID,
                c.MobileNo,
                c.Claim_Date,
                c.Amount,
                ISNULL(c.IsApproved, 0)
            ORDER BY
                c.Claim_Date DESC
        ) AS DuplicateRank

    FROM dbo.ClaimDetails c
    WHERE --c.MobileNo = @MobileNo
       c.Comp_ID = @Comp_ID and
        ISNULL(c.IsApproved, 0) <> 2
      AND ISNULL(c.Amount, 0) <> 0
      AND c.Claim_Date <= (
          SELECT MAX(p.ReqDate)
          FROM dbo.TempUPIPayoutReport p
          WHERE p.Comp_ID = c.Comp_ID
      )
),
PointsSummary AS
(
    SELECT MobileNo,
        SUM
        (
            CAST(ISNULL(Points, 0) AS DECIMAL(18, 2))
        ) AS TotalPoints,
		 SUM
        (
            CAST(ISNULL(AssignPoint, 0) AS DECIMAL(18, 2))
        ) AS AssingedPoints,
        MAX(Enq_Date) AS LastCodeCheckDate
    FROM dbo.TempCodesActivityReport 
    WHERE --MobileNo = @MobileNo
      Comp_ID = @Comp_ID group by MobileNo
),
ClaimSummary AS
(
    SELECT mobileno,
        SUM
        (
            CAST(ISNULL(Amount, 0) AS DECIMAL(18, 2))
        ) AS TotalClaimAmount,
		  
        SUM
        (
            CAST(ISNULL(RequestAmmount, ISNULL(pointsvalue, 0) + ISNULL(tdsAmount, 0)) - ISNULL(tdsAmount, 0) AS DECIMAL(18, 2))
        ) AS TotalRsClaim,

		SUM
        (
            CAST(ISNULL(tdsAmount, 0) AS DECIMAL(18, 2))
        ) AS TotalClaimAmountPointsValuetds,
        MAX(Claim_Date) AS LastClaimDate

    FROM UniqueClaims
    WHERE Comp_ID = @comp_id and DuplicateRank = 1 group by mobileno
),
PayoutSummary AS
(
    SELECT MobileNo,
        SUM
        (
            CAST(ISNULL(Amount, 0) AS DECIMAL(18, 2))
        ) AS TotalPaidPoints ,
		 SUM
        (
            CAST(ISNULL(FinalPayment, 0) AS DECIMAL(18, 2))
        ) AS TotalRsPaid ,
		 SUM
        (
            CAST(ISNULL(tdsAmount, 0) AS DECIMAL(18, 2))
        ) AS TotalPaidtds,
        MAX(ReqDate) AS LastPaymentDate
    FROM dbo.TempUPIPayoutReport
    WHERE --MobileNo = @MobileNo
      Comp_ID = @Comp_ID and  
	  code1 > 0 and BankStatus = 'Success' group by MobileNo
),
AllTransactions AS
(
    SELECT 
        MobileNo,
        Enq_Date AS TransactionDate,
        ISNULL(Points, 0) AS WonPoints,
        'Points Earned' AS TransactionType
    FROM dbo.TempCodesActivityReport
    WHERE Comp_ID = @Comp_ID

    UNION ALL

    SELECT 
        MobileNo,
        Claim_Date AS TransactionDate,
        -ISNULL(Amount, 0) AS WonPoints,
        CASE 
            WHEN ISNULL(IsApproved, 0) = 0 THEN 'Claim Raised'
            WHEN IsApproved = 1 THEN 'Amount Claimed'
            ELSE 'Claim Raised'
        END AS TransactionType
    FROM UniqueClaims
    WHERE DuplicateRank = 1

    UNION ALL

    SELECT 
        MobileNo,
        ReqDate AS TransactionDate,
        -ISNULL(Amount, 0) AS WonPoints,
        'Amount Paid' AS TransactionType
    FROM dbo.TempUPIPayoutReport
    WHERE Comp_ID = @Comp_ID and code1 > 0 and BankStatus = 'Success'
),
RunningBalances AS
(
    SELECT 
        MobileNo,
        TransactionDate,
        TransactionType,
        SUM(WonPoints) OVER (
            PARTITION BY MobileNo 
            ORDER BY TransactionDate, WonPoints DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningBalance
    FROM AllTransactions
),
FraudClaims AS
(
    SELECT 
        MobileNo,
        MAX(TransactionDate) AS LastFraudClaimDate
    FROM RunningBalances
    WHERE RunningBalance < 0
      AND TransactionType IN ('Claim Raised', 'Amount Claimed', 'Amount Paid')
    GROUP BY MobileNo
)

    SELECT
        p.MobileNo,
        d.ConsumerName,
        ISNULL(P.TotalPoints, 0) AS TotalPoints,
        ISNULL(P.AssingedPoints, 0) AS AssingedPoints,
        ISNULL(C.TotalClaimAmount, 0) + ISNULL(U.TotalPaidPoints, 0) AS TotalClaimAmount,
        ISNULL(P.TotalPoints, 0) - (ISNULL(C.TotalClaimAmount, 0) + ISNULL(U.TotalPaidPoints, 0)) AS AvailableBalance,
        (ISNULL(C.TotalRsClaim, 0) + ISNULL(U.TotalRsPaid, 0)) AS PaidAmount,
        (ISNULL(TotalClaimAmountPointsValuetds, 0) + ISNULL(TotalPaidtds, 0)) AS TDS,
        P.LastCodeCheckDate,
        CASE
            WHEN C.LastClaimDate IS NULL THEN U.LastPaymentDate
            WHEN U.LastPaymentDate IS NULL THEN C.LastClaimDate
            WHEN C.LastClaimDate > U.LastPaymentDate THEN C.LastClaimDate
            ELSE U.LastPaymentDate
        END AS LastPaymentDate,
        F.LastFraudClaimDate
    INTO #Summary
    FROM PointsSummary P
    LEFT JOIN ClaimSummary C ON p.MobileNo = c.MobileNo
    LEFT JOIN PayoutSummary U ON p.MobileNo = u.MobileNo
    LEFT JOIN M_Consumer d ON p.MobileNo = d.MobileNo
    LEFT JOIN FraudClaims F ON p.MobileNo = f.MobileNo
    WHERE
        (ISNULL(P.TotalPoints, 0) - (ISNULL(C.TotalClaimAmount, 0) + ISNULL(U.TotalPaidPoints, 0))) < 0
        AND (
            @Search IS NULL
            OR @Search = ''
            OR p.MobileNo LIKE '%' + @Search + '%'
            OR d.ConsumerName LIKE '%' + @Search + '%'
        )
        AND P.LastCodeCheckDate >= @StartDate
        AND P.LastCodeCheckDate < @EndDate;

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #Summary;

    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY LastPaymentDate DESC;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY LastPaymentDate DESC
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        SELECT
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(@TotalRecords * 1.0 / @Limit) AS TotalPages;
    END

    DROP TABLE IF EXISTS #Summary;

END

