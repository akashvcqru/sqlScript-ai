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
            CAST(ISNULL(pointsvalue, 0) AS DECIMAL(18, 2))
        ) AS TotalClaimAmountPointsValue,

		SUM
        (
            CAST(ISNULL(tdsAmount, 0) AS DECIMAL(18, 2))
        ) AS TotalClaimAmountPointsValuetds

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
        ) AS TotalPaidAmount ,
		SUM
        (
            CAST(ISNULL(tdsAmount, 0) AS DECIMAL(18, 2))
        ) AS TotalPaidtds
    FROM dbo.TempUPIPayoutReport
    WHERE --MobileNo = @MobileNo
      Comp_ID = @Comp_ID and  
	  code1 > 0 and BankStatus = 'Success' group by MobileNo
)

    SELECT
        p.MobileNo,
        d.ConsumerName,
        ISNULL(P.TotalPoints, 0) AS TotalPoints,
        ISNULL(P.AssingedPoints, 0) AS AssingedPoints,
        ISNULL(C.TotalClaimAmount, 0) + ISNULL(U.TotalPaidPoints, 0) AS TotalClaimAmount,
        ISNULL(P.TotalPoints, 0) - (ISNULL(C.TotalClaimAmount, 0) + ISNULL(U.TotalPaidPoints, 0)) AS AvailableBalance,
        (ISNULL(TotalClaimAmountPointsValue, 0) + ISNULL(TotalPaidAmount, 0)) AS PaidAmount,
        (ISNULL(TotalClaimAmountPointsValuetds, 0) + ISNULL(TotalPaidtds, 0)) AS TDS,
        P.LastCodeCheckDate
    INTO #Summary
    FROM PointsSummary P
    LEFT JOIN ClaimSummary C ON p.MobileNo = c.MobileNo
    LEFT JOIN PayoutSummary U ON p.MobileNo = u.MobileNo
    LEFT JOIN M_Consumer d ON p.MobileNo = d.MobileNo
    WHERE
        (ISNULL(P.TotalPoints, 0) - (ISNULL(C.TotalClaimAmount, 0) + ISNULL(U.TotalPaidPoints, 0))) < 0
        AND (
            @Search IS NULL
            OR @Search = ''
            OR p.MobileNo LIKE '%' + @Search + '%'
            OR d.ConsumerName LIKE '%' + @Search + '%'
        );

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #Summary;

    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY MobileNo;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #Summary
        ORDER BY MobileNo
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

