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
    @TimeWindow NVARCHAR(20) = NULL  -- Options: TODAY, WEEK, LASTWEEK, MONTH, QUARTER
)
AS
BEGIN
    SET NOCOUNT ON;

   DECLARE @StartDate DATE;
DECLARE @EndDate   DATE;

DECLARE @Today DATE = CAST(GETDATE() AS DATE);

-- Monday as first day of week
SET DATEFIRST 1;

------------------------------------------------
-- START DATE (CALENDAR-BASED)
------------------------------------------------
SET @StartDate =
    CASE
        -- TODAY
        WHEN UPPER(@TimeWindow) = 'TODAY'
            THEN @Today

        -- CURRENT WEEK (Monday → Today)
        WHEN UPPER(@TimeWindow) = 'WEEK'
            THEN DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today)

        -- LAST WEEK (Previous Monday)
        WHEN UPPER(@TimeWindow) = 'LASTWEEK'
            THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0)

        -- CURRENT MONTH (1st → Today)
        WHEN UPPER(@TimeWindow) = 'MONTH'
            THEN DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)

        -- LAST MONTH (1st of previous month)
        WHEN UPPER(@TimeWindow) = 'LASTMONTH'
            THEN DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1))

        -- QUARTER (Rolling last 90 days)
        WHEN UPPER(@TimeWindow) = 'QUARTER'
            THEN DATEADD(DAY, -90, @Today)

        -- DEFAULT → CURRENT MONTH
        ELSE DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)
    END;

------------------------------------------------
-- END DATE (CALENDAR-BASED)
------------------------------------------------
SET @EndDate =
    CASE
        -- LAST WEEK → Previous Sunday
        WHEN UPPER(@TimeWindow) = 'LASTWEEK'
            THEN DATEADD(
                    DAY,
                    -1,
                    DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0)
                 )

        -- LAST MONTH → Last day of previous month
        WHEN UPPER(@TimeWindow) = 'LASTMONTH'
            THEN EOMONTH(@Today, -1)

        -- ALL OTHERS → Today
        ELSE @Today
    END;


   ;WITH CTE_AllUsers AS (
    -- Base: Users linked with this company via KYC
    SELECT DISTINCT 
        V.M_ConsumerId,
        MC.MobileNo
    FROM tbl_VendorViseKYCStatus V
    LEFT JOIN M_Consumer MC ON MC.M_ConsumerId = V.M_ConsumerId
    WHERE V.Comp_Id = @CompId
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
       AND CAST(CD.action_date AS DATE) BETWEEN @StartDate AND @EndDate
    LEFT JOIN tblUPITransactionDetails UPI
        ON UPI.M_Consumerid = AU.M_ConsumerId
       AND UPI.Comp_Id = @CompId
       AND UPI.Status = 'Success'
	   AND LEN(UPI.Code1)>2
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
