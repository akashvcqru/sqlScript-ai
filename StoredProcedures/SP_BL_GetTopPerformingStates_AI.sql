USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetTopPerformingStates_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetTopPerformingStates_AI]
(
    @CompId NVARCHAR(50),
    @datePreset NVARCHAR(20) = NULL  -- Options: TODAY, WEEK, LASTWEEK, MONTH, QUARTER, YEAR, LASTYEAR
)
AS
BEGIN
    SET NOCOUNT ON;

   DECLARE @StartDate DATE;
DECLARE @EndDate   DATE;

DECLARE @Today DATE = CAST(GETDATE() AS DATE);
DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

-- Normalize the filter string
SET @Win = REPLACE(@Win, ' ', '');
IF @Win = 'THISMONTH' SET @Win = 'MONTH';
IF @Win = 'THISWEEK' SET @Win = 'WEEK';
IF @Win = 'QUARTER(90DAYS)' SET @Win = 'QUARTER';

-- Fetch Company Registration Date for optimization
DECLARE @CompRegDate DATE;
SELECT TOP 1 @CompRegDate = CAST(Reg_Date AS DATE) 
FROM Comp_Reg WITH (NOLOCK) 
WHERE Comp_ID = @CompId AND Status = 1;

IF @CompRegDate IS NULL 
    SET @CompRegDate = '2000-01-01';

DECLARE @Days INT;
IF @Win = 'LASTWEEK'  SET @Days = 14;
ELSE IF @Win = 'WEEK' OR @Win = 'THISWEEK' SET @Days = 7;
ELSE IF @Win = 'QUARTER' SET @Days = 90;
ELSE SET @Days = 30; -- Default to Month/30 days

------------------------------------------------
-- DATE RANGE LOGIC
------------------------------------------------
IF @Win = 'WEEK' OR @Win = 'THISWEEK'
BEGIN
    SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0); -- Monday
    SET @EndDate = CAST(GETDATE() AS DATE);
END
ELSE IF @Win = 'LASTWEEK'
BEGIN
    SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0); -- Prev Monday
    SET @EndDate = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)); -- Prev Sunday
END
ELSE IF @Win = 'MONTH' OR @Win = 'THISMONTH'
BEGIN
    SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    SET @EndDate = CAST(GETDATE() AS DATE);
END
ELSE IF @Win = 'LASTMONTH'
BEGIN
    SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
    SET @EndDate = EOMONTH(DATEADD(MONTH, -1, GETDATE()));
END
ELSE IF @Win = 'QUARTER'
BEGIN
    SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
    SET @EndDate = DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0));
END
ELSE
BEGIN
    -- Default to THIS WEEK
    SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    SET @EndDate = CAST(GETDATE() AS DATE);
END


   ;WITH CTE_AllUsers AS (
    -- Base: Users linked with this company via KYC
    SELECT DISTINCT 
        V.M_ConsumerId,
        MC.MobileNo
    FROM tbl_VendorViseKYCStatus V
    LEFT JOIN M_Consumer MC ON MC.M_ConsumerId = V.M_ConsumerId
    WHERE V.Comp_Id = @CompId AND (MC.Entry_Date IS NULL OR MC.Entry_Date >= @CompRegDate)
),
CTE_State AS (
    -- Get latest scanned state for each user
    SELECT 
        AU.M_ConsumerId,
        AU.MobileNo,
        G.[State],
        ROW_NUMBER() OVER (PARTITION BY AU.M_ConsumerId ORDER BY G.Enq_Date DESC) AS rn
    FROM CTE_AllUsers AU
    LEFT JOIN GeoLocationData G
        ON G.MobileNo = AU.MobileNo
       AND G.Comp_Id = @CompId
       AND G.Enq_Date >= @CompRegDate
       AND CAST(G.Enq_Date AS DATE) BETWEEN @StartDate AND @EndDate
),
CTE_UserState AS (
    SELECT M_ConsumerId, MobileNo, [State]
    FROM CTE_State
    WHERE rn = 1   -- Latest State Only
),
CTE_BLE AS (
    SELECT 
        US.[State],
        SUM(BLE.Points) AS TotalEarnedPoints
    FROM CTE_AllUsers AU
    LEFT JOIN BLoyaltyPointsEarned BLE
        ON BLE.M_ConsumerId = AU.M_ConsumerId
       AND BLE.Compid = @CompId
       AND BLE.UpdateDate >= @CompRegDate
       AND CAST(BLE.UpdateDate AS DATE) BETWEEN @StartDate AND @EndDate
    LEFT JOIN CTE_UserState US
        ON US.M_ConsumerId = AU.M_ConsumerId
    GROUP BY US.[State]
),
CTE_Redeem AS (
    SELECT 
        US.[State],
        SUM(ISNULL(CD.Amount, 0)) AS ClaimRedeemAmt,
        SUM(ISNULL(UPI.Amount, 0)) AS UpiRedeemAmt,
        MAX(CD.action_date) AS LastActionDate
    FROM CTE_AllUsers AU
    LEFT JOIN ClaimDetails CD
        ON CD.MobileNo = AU.MobileNo
       AND CD.Comp_id = @CompId
       AND CD.Isapproved = 1
       AND CD.action_date >= @CompRegDate
       AND CAST(CD.action_date AS DATE) BETWEEN @StartDate AND @EndDate
    LEFT JOIN tblUPITransactionDetails UPI
        ON UPI.M_Consumerid = AU.M_ConsumerId
       AND UPI.Comp_Id = @CompId
       AND UPI.Status = 'Success'
	   AND LEN(UPI.Code1)>2
       AND UPI.ReqDate >= @CompRegDate
       AND CAST(UPI.ReqDate AS DATE) BETWEEN @StartDate AND @EndDate
    LEFT JOIN CTE_UserState US
        ON US.M_ConsumerId = AU.M_ConsumerId
    GROUP BY US.[State]
),
CTE_ActiveUsers AS (
    SELECT 
        US.[State],
        COUNT(DISTINCT AU.M_ConsumerId) AS ActiveUsers
    FROM CTE_AllUsers AU
    INNER JOIN CTE_UserState US ON US.M_ConsumerId = AU.M_ConsumerId
    WHERE US.[State] IS NOT NULL
    GROUP BY US.[State]
)

SELECT Top 5
    COALESCE(AU.[State], B.[State], R.[State]) AS [State],
    ISNULL(AU.ActiveUsers, 0) AS ActiveUsers,
    ISNULL(B.TotalEarnedPoints, 0) AS TotalEarnedPoints,
    ISNULL(R.ClaimRedeemAmt, 0) + ISNULL(R.UpiRedeemAmt, 0) AS RedeemAmount,
    CASE 
        WHEN ISNULL(B.TotalEarnedPoints, 0) = 0 THEN 0
        ELSE (
             (ISNULL(R.ClaimRedeemAmt, 0) + ISNULL(R.UpiRedeemAmt, 0)) * 100.0
             / NULLIF(B.TotalEarnedPoints, 0)
        )
    END AS GrowthPercentage,
    R.LastActionDate
FROM CTE_BLE B
FULL JOIN CTE_Redeem R ON R.[State] = B.[State]
FULL JOIN CTE_ActiveUsers AU ON AU.[State] = COALESCE(B.[State], R.[State])
WHERE COALESCE(AU.[State], B.[State], R.[State]) IS NOT NULL
ORDER BY TotalEarnedPoints DESC;
END
