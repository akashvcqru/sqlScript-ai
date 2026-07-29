ALTER   PROCEDURE [dbo].[USP_GetUserNegativeBalanceAnalysis_AI]
(
    @MobileNo   NVARCHAR(30),
    @Comp_Id    NVARCHAR(50),
    @DatePreset NVARCHAR(20) = 'ALL',
    @FromDate   NVARCHAR(30) = NULL,
    @ToDate     NVARCHAR(30) = NULL,
    @Page       INT = 1,
    @Limit      INT = 10,
    @Search     NVARCHAR(100) = NULL,
    @IsExport   BIT = 0
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
    ELSE IF (@Preset = 'YESTERDAY')
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




DECLARE @CRate DECIMAL(18,2);
 --add earnedpoints,Assinged points in 2nd table
 --job , for 7 comp sumary date()1 drill down , 2nd droll down , 3 drill down report , points 0 on some codes
select @CRate = CashValue/PointValue from [dbo].[PointConversionRate] where Comp_ID = @Comp_ID and IsActive = 1
--select  @CRate
 --earned points ()
 
--DECLARE @Comp_ID  VARCHAR(20) = 'Comp-1727';
--DECLARE @MobileNo VARCHAR(20) = '919785716405';
--DECLARE @CRate DECIMAL(18,2);

select @CRate = CashValue/PointValue from [dbo].[PointConversionRate] where Comp_ID = @Comp_ID and IsActive = 1
drop table if exists #temp

/*============================================================
  Transaction-wise report
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
    WHERE c.MobileNo = @MobileNo
      AND c.Comp_ID = @Comp_ID
      AND ISNULL(c.IsApproved, 0) <> 2
      AND ISNULL(c.Amount, 0) <> 0
      AND c.Claim_Date <= (
          SELECT MAX(p.ReqDate)
          FROM dbo.TempUPIPayoutReport p
          WHERE p.Comp_ID = c.Comp_ID
      )
),
TransactionData AS
(
    /* Points earned */
    SELECT
        a.Comp_Name,
        a.Comp_ID,
        a.Pro_Name,
        a.MobileNo,
        a.UniqueCode,
        a.Dial_Mode,
        a.Enq_Date AS TransactionDate,
        CAST(a.Result AS VARCHAR(50)) AS IsSuccess,
 
        CAST
        (
            ISNULL(a.Points, 0) AS DECIMAL(18, 2)
        ) AS TransactionValue,a.AssignPoint,
        CAST
        (
            ISNULL(a.Points, 0)* @CRate AS DECIMAL(18, 2)
        ) AS TransactionValue1,
	'' as tdsAmount,
        'Points Earned' AS TransactionType,
        NULL AS ApprovalStatus,
        1 AS AffectsBalance,
 
        ROW_NUMBER() OVER
        (
            PARTITION BY
                a.Comp_ID,
                a.MobileNo,
                a.UniqueCode,
                a.Enq_Date,
                a.Points
            ORDER BY
                a.Enq_Date DESC
        ) AS DuplicateRank
 
    FROM dbo.TempCodesActivityReport a
    WHERE a.MobileNo = @MobileNo
      AND a.Comp_ID = @Comp_ID
      --AND ISNULL(a.Points, 0) <> 0
 
 
    UNION ALL
 
 
    /* Unique claims only */
    SELECT
        NULL AS Comp_Name,
        c.Comp_ID,
        NULL AS Pro_Name,
        c.MobileNo,
        NULL AS UniqueCode,
        NULL AS Dial_Mode,
        c.Claim_Date AS TransactionDate,
        NULL AS IsSuccess,
 
        -CAST
        (
            ISNULL(c.Amount, 0) AS DECIMAL(18, 2)
        ) AS TransactionValue, 0 as AssignPoint,
        -CAST
        (
            ISNULL(c.pointsvalue, 0) AS DECIMAL(18, 2)
        ) AS TransactionValue1,
        c.tdsAmount,
        CASE 
            WHEN ISNULL(c.IsApproved, 0) = 0 THEN 'Claim Raised'
            WHEN c.IsApproved = 1 THEN 'Amount Claimed'
            ELSE 'Claim Raised'
        END AS TransactionType,
        CASE
            WHEN ISNULL(c.IsApproved, 0) = 0
                THEN 'Pending'
 
            WHEN c.IsApproved = 1
                THEN 'Approved'
 
            WHEN c.IsApproved = 2
                THEN 'Rejected'
 
            ELSE 'Other'
        END AS ApprovalStatus,
 
        1 AS AffectsBalance,
        1 AS DuplicateRank
 
    FROM UniqueClaims c
    WHERE c.DuplicateRank = 1
 
 
    UNION ALL
 
 
    /* Payout information only */
    SELECT
        p.Comp_Name,
        p.Comp_ID,
        NULL AS Pro_Name,
        p.MobileNo,
        NULL AS UniqueCode,
        NULL AS Dial_Mode,
        p.ReqDate AS TransactionDate,
        NULL AS IsSuccess,
 
        -CAST
        (
            ISNULL(p.Amount, 0) AS DECIMAL(18, 2)
        ) AS TransactionValue, 0 as AssignPoint,
		-CAST
        (
            ISNULL(p.FinalPayment, 0) AS DECIMAL(18, 2)
        ) AS TransactionValue1,
        p.tdsAmount as tdsAmount,
        'Amount Paid' AS TransactionType,
        'Paid' AS ApprovalStatus,
        0 AS AffectsBalance,
 
        ROW_NUMBER() OVER
        (
            PARTITION BY
                p.Comp_ID,
                p.MobileNo,
                p.ReqDate,
                p.Amount
            ORDER BY
                p.ReqDate DESC
        ) AS DuplicateRank
 
    FROM dbo.TempUPIPayoutReport p
    WHERE p.MobileNo = @MobileNo
      AND p.Comp_ID = @Comp_ID and   code1 >0 and BankStatus = 'Success'
      AND ISNULL(p.Amount, 0) <> 0
)
select * into #temp from TransactionData
    IF OBJECT_ID('tempdb..#Summary') IS NOT NULL
        DROP TABLE #Summary;

;WITH FinalData AS
(
    -- Original rows
    SELECT
        Comp_Name,
        Comp_ID,
        Pro_Name,
        MobileNo,
        UniqueCode,
        Dial_Mode,
        TransactionDate,
        IsSuccess,
        TransactionType,
        ApprovalStatus,
        AffectsBalance,
        TransactionValue,AssignPoint,
        TransactionValue1 AS AmountTransaction,
        tdsAmount AS tdsTransaction,
        2 AS SortOrder
    FROM #temp
    WHERE DuplicateRank = 1

    UNION ALL

    -- TDS Row (insert before Claim Raised & Amount Paid)
    SELECT
        NULL AS Comp_Name,
        Comp_ID,
        NULL AS Pro_Name,
        MobileNo,
        NULL AS UniqueCode,
        NULL AS Dial_Mode,
        DATEADD(MILLISECOND,-1,TransactionDate) AS TransactionDate, -- makes it appear before
        NULL AS IsSuccess,
        NULL AS TransactionType,
        NULL AS ApprovalStatus,
        NULL AS AffectsBalance,AssignPoint,
        NULL AS TransactionValue,
       -- CAST(tdsAmount AS DECIMAL(18,2)) AS AmountTransaction,
	   CAST(ISNULL(tdsAmount,0)*-1 AS DECIMAL(18,2)) AS AmountTransaction,
        NULL AS tdsTransaction,
        1 AS SortOrder
    FROM #temp
    WHERE DuplicateRank = 1
      AND TransactionType IN ('Claim Raised', 'Amount Claimed', 'Amount Paid')
      AND ISNULL(tdsAmount,0) > 0
)

    SELECT
        Comp_Name,
        Comp_ID,
        Pro_Name,
        MobileNo,
        UniqueCode,
        Dial_Mode,
        TransactionDate,
        IsSuccess,
        TransactionType,
        ApprovalStatus,
         AssignPoint,
        TransactionValue AS WonPoints,

        CASE
            WHEN TransactionType = 'Points Earned'
                THEN '+' + CONVERT(VARCHAR(30), TransactionValue)
            WHEN TransactionType IN ('Claim Raised', 'Amount Claimed', 'Amount Paid')
                THEN CONVERT(VARCHAR(30), TransactionValue)
            ELSE NULL
        END AS DisplayValue,

        AmountTransaction,
        tdsTransaction,
        SortOrder
    INTO #Summary
    FROM FinalData;

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #Summary;

    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY TransactionDate DESC, SortOrder;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY TransactionDate DESC, SortOrder
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        SELECT
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(@TotalRecords * 1.0 / @Limit) AS TotalPages;
    END

    DROP TABLE IF EXISTS #temp;
    DROP TABLE IF EXISTS #Summary;

END

