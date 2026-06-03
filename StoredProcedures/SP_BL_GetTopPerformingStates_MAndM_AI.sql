USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetTopPerformingStates_MAndM_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetTopPerformingStates_MAndM_AI]
(
    @CompId NVARCHAR(50),
    @datePreset NVARCHAR(20) = NULL  -- Options: TODAY, WEEK, LASTWEEK, MONTH, QUARTER, YEAR, LASTYEAR
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(50) = @CompId;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @CompId AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @CompId AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

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
WHERE Comp_ID = @ActualCompId AND Status = 1;

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
    ELSE IF @Win = 'ALL' OR @Win = 'ALLTIME'
    BEGIN
        SET @StartDate = @CompRegDate;
        SET @EndDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE
    BEGIN
        -- Default to THIS MONTH for Mahindra Dashboard
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate = CAST(GETDATE() AS DATE);
    END


    IF OBJECT_ID('tempdb..#Users') IS NOT NULL DROP TABLE #Users;

    SELECT DISTINCT 
        V.M_ConsumerId,
        MC.MobileNo,
        ISNULL(NULLIF(LTRIM(RTRIM(MC.state)), ''), '') AS RegisteredState
    INTO #Users
    FROM tbl_VendorViseKYCStatus V WITH (NOLOCK)
    JOIN M_Consumer MC WITH (NOLOCK) ON MC.M_ConsumerId = V.M_ConsumerId
    WHERE V.Comp_Id = @ActualCompId 
      AND (MC.Entry_Date IS NULL OR MC.Entry_Date >= @CompRegDate)
      AND (
            (@IsSBUTeam = 0 AND (MC.distributorID <> 'SBUTEAM' OR MC.distributorID IS NULL)) OR
            (@IsSBUTeam = 1 AND MC.distributorID = 'SBUTEAM')
          );

    CREATE CLUSTERED INDEX IX_Users ON #Users (M_ConsumerId);
    CREATE NONCLUSTERED INDEX IX_Users_Mobile ON #Users (MobileNo);

    IF OBJECT_ID('tempdb..#GeoScans') IS NOT NULL DROP TABLE #GeoScans;

    SELECT 
        G.MobileNo,
        G.State,
        ROW_NUMBER() OVER (PARTITION BY G.MobileNo ORDER BY G.Enq_Date DESC) AS rn
    INTO #GeoScans
    FROM GeoLocationData G WITH (NOLOCK)
    WHERE G.Comp_Id = @ActualCompId
      AND G.Enq_Date >= @CompRegDate
      AND G.Enq_Date >= @StartDate
      AND G.Enq_Date < DATEADD(DAY, 1, @EndDate);

    CREATE CLUSTERED INDEX IX_GeoScans ON #GeoScans (MobileNo);

    IF OBJECT_ID('tempdb..#UserState') IS NOT NULL DROP TABLE #UserState;

    SELECT 
        U.M_ConsumerId,
        U.MobileNo,
        ISNULL(NULLIF(U.RegisteredState, ''), ISNULL(GS.State, '')) AS State
    INTO #UserState
    FROM #Users U
    LEFT JOIN #GeoScans GS ON GS.MobileNo = U.MobileNo AND GS.rn = 1;

    CREATE CLUSTERED INDEX IX_UserState ON #UserState (M_ConsumerId);

    IF OBJECT_ID('tempdb..#BLE') IS NOT NULL DROP TABLE #BLE;

    SELECT 
        US.State,
        SUM(CASE WHEN BLE.Points IS NULL OR BLE.Points = 0 THEN ISNULL(BLE.Cash, 0) ELSE BLE.Points END) AS TotalEarnedPoints
    INTO #BLE
    FROM BLoyaltyPointsEarned BLE WITH (NOLOCK)
    JOIN #UserState US ON BLE.M_ConsumerId = US.M_ConsumerId
    LEFT JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BLE.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    LEFT JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    WHERE ISNULL(BLE.Compid, MC.Compid) = @ActualCompId
      AND BLE.UpdateDate >= @CompRegDate
      AND BLE.UpdateDate >= @StartDate
      AND BLE.UpdateDate < DATEADD(DAY, 1, @EndDate)
    GROUP BY US.State;

    IF OBJECT_ID('tempdb..#Redeem') IS NOT NULL DROP TABLE #Redeem;

    SELECT 
        US.State,
        SUM(ISNULL(CD.Amount, 0)) AS ClaimRedeemAmt,
        SUM(ISNULL(UPI.Amount, 0)) AS UpiRedeemAmt,
        MAX(CD.action_date) AS LastActionDate
    INTO #Redeem
    FROM #UserState US
    LEFT JOIN ClaimDetails CD WITH (NOLOCK)
        ON CD.MobileNo = US.MobileNo
       AND CD.Comp_id = @ActualCompId
       AND CD.Isapproved = 1
       AND CD.action_date >= @CompRegDate
       AND CD.action_date >= @StartDate
       AND CD.action_date < DATEADD(DAY, 1, @EndDate)
    LEFT JOIN Transactions UPI WITH (NOLOCK)
        ON UPI.M_CounserID = US.M_ConsumerId
       AND UPI.CompId = REPLACE(@ActualCompId, 'Comp-', '')
       AND UPI.Issuccess = 1
       AND UPI.TransactionDate >= @CompRegDate
       AND UPI.TransactionDate >= @StartDate
       AND UPI.TransactionDate < DATEADD(DAY, 1, @EndDate)
    GROUP BY US.State;

    IF OBJECT_ID('tempdb..#ActiveUsers') IS NOT NULL DROP TABLE #ActiveUsers;

    SELECT 
        State,
        COUNT(DISTINCT M_ConsumerId) AS ActiveUsers
    INTO #ActiveUsers
    FROM #UserState
    WHERE State <> ''
    GROUP BY State;

    SELECT TOP 5
        COALESCE(AU.State, B.State, R.State) AS [State],
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
    FROM #ActiveUsers AU
    FULL JOIN #BLE B ON B.State = AU.State
    FULL JOIN #Redeem R ON R.State = COALESCE(AU.State, B.State)
    WHERE COALESCE(AU.State, B.State, R.State) IS NOT NULL AND COALESCE(AU.State, B.State, R.State) <> ''
    ORDER BY TotalEarnedPoints DESC;
END
