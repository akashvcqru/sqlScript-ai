ALTER   PROCEDURE [dbo].[USP_GetCompanyPointsClaimSummary_AI]
(
    @DatePreset NVARCHAR(50) = 'ALL',
    @FromDate NVARCHAR(30) = NULL,
    @ToDate NVARCHAR(30) = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------------
    -- Date Range
    -----------------------------------------
    DECLARE @StartDate DATETIME = NULL,
            @EndDate   DATETIME = NULL,
            @Preset    NVARCHAR(50);

    IF @FromDate IS NOT NULL AND LTRIM(RTRIM(@FromDate)) <> '' 
       AND @ToDate IS NOT NULL AND LTRIM(RTRIM(@ToDate)) <> ''
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
    BEGIN
        SET @Preset = UPPER(LTRIM(RTRIM(@DatePreset)));

        IF @Preset = 'TODAY'
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('YESTERDAY', 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF @Preset IN ('WEEK', 'THIS WEEK', 'THISWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTWEEK', 'LAST WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('MONTH', 'THIS MONTH', 'THISMONTH', 'MONTHS')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTMONTH', 'LAST MONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('QUARTER', 'THIS QUARTER', 'THISQUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTQUARTER', 'LAST QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF @Preset IN ('YEAR', 'THIS YEAR', 'THISYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF @Preset IN ('LASTYEAR', 'LAST YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF @Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> ''
        BEGIN
            SET @StartDate = CAST(@FromDate AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
        END
        ELSE IF @Preset IN ('ALL', 'NULL')
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;






	DECLARE @CRate DECIMAL(18,2) = 1.00;
 --add earnedpoints,Assinged points in 2nd table
 --job , for 7 comp sumary date()1 drill down , 2nd droll down , 3 drill down report , points 0 on some codes
--select @CRate = CashValue/PointValue from [dbo].[PointConversionRate] where Comp_ID = @Comp_ID and IsActive = 1
--select  @CRate
 --earned points ()
 
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
      --AND c.Comp_ID = @Comp_ID
	  c.Comp_ID in (select distinct comp_id from TempCodesActivityReport)  and 
       ISNULL(c.IsApproved, 0) <> 2
      AND ISNULL(c.Amount, 0) <> 0
),
PointsSummary AS
(
    SELECT Comp_ID,
        SUM
        (
            CAST(ISNULL(Points, 0) AS DECIMAL(18, 2))
        ) AS TotalPoints,
		 SUM
        (
            CAST(ISNULL(AssignPoint, 0) AS DECIMAL(18, 2))
        ) AS AssingedPoints
    FROM dbo.TempCodesActivityReport group by Comp_ID
    --WHERE MobileNo = @MobileNo
     -- AND Comp_ID = @Comp_ID
),
ClaimSummary AS
(
    SELECT Comp_ID,
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
    WHERE DuplicateRank = 1 group by Comp_ID
),
PayoutSummary AS
(
    SELECT Comp_ID,
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
     -- AND Comp_ID = @Comp_ID and  
	  code1 > 0 and BankStatus = 'Success' group by Comp_ID
)

 SELECT
 p.Comp_ID,d.comp_name,
    ISNULL(P.TotalPoints, 0) AS TotalPoints, AssingedPoints,
 
    ISNULL(C.TotalClaimAmount, 0) + ISNULL(U.TotalPaidPoints, 0) AS TotalClaimAmount,
 
   -- ISNULL(U.TotalPaidPoints, 0) AS TotalPaidPoints,
 
    ISNULL(P.TotalPoints, 0)
        - (ISNULL(C.TotalClaimAmount, 0)+ISNULL(U.TotalPaidPoints, 0)) AS AvailableBalance,
	(ISNULL(TotalClaimAmountPointsValue,0) + ISNULL(TotalPaidAmount,0)) as PaidAmount, (ISNULL(TotalClaimAmountPointsValuetds,0) + ISNULL(TotalPaidtds,0) ) as TDS
 
FROM PointsSummary P
inner JOIN ClaimSummary C on p.Comp_ID = c.Comp_ID
inner JOIN PayoutSummary U on c.Comp_ID = u.Comp_ID
inner join comp_reg d on  p.Comp_ID =  d.Comp_ID
 END
