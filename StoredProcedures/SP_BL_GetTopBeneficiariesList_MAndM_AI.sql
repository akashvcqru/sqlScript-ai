USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetTopBeneficiariesList_MAndM_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetTopBeneficiariesList_MAndM_AI]
(  
    @CompId     NVARCHAR(50),  
    @datePreset NVARCHAR(20) = NULL
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

  DECLARE @StartDate DATETIME, @EndDate DATETIME;
  SET @EndDate = CAST(GETDATE() AS DATETIME);

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
      -- Default to THIS MONTH for Mahindra Dashboard
      SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
      SET @EndDate = CAST(GETDATE() AS DATE);
  END

    IF OBJECT_ID('tempdb..#Users') IS NOT NULL DROP TABLE #Users;

    SELECT 
        V.M_ConsumerId,
        MC.ConsumerName,
        MC.MobileNo,
        MC.PinCode
    INTO #Users
    FROM tbl_VendorViseKYCStatus V WITH (NOLOCK)
    JOIN M_Consumer MC WITH (NOLOCK) ON V.M_ConsumerId = MC.M_ConsumerId
    WHERE V.Comp_Id = @ActualCompId 
      AND MC.IsDelete='0' 
      AND MC.Entry_Date >= @CompRegDate
      AND (
            (@IsSBUTeam = 0 AND (MC.distributorID <> 'SBUTEAM' OR MC.distributorID IS NULL)) OR
            (@IsSBUTeam = 1 AND MC.distributorID = 'SBUTEAM')
          );

    CREATE CLUSTERED INDEX IX_Users ON #Users (M_ConsumerId);

    IF OBJECT_ID('tempdb..#State') IS NOT NULL DROP TABLE #State;

    SELECT 
        G.MobileNo,
        G.State,
        G.City,
        ROW_NUMBER() OVER (PARTITION BY G.MobileNo ORDER BY G.Enq_Date DESC) AS rn
    INTO #State
    FROM GeoLocationData G WITH (NOLOCK)
    WHERE G.Comp_Id = @ActualCompId
      AND G.Enq_Date >= @CompRegDate
      AND G.Enq_Date >= @StartDate
      AND G.Enq_Date < DATEADD(DAY, 1, @EndDate)
      AND EXISTS (SELECT 1 FROM #Users U WHERE U.MobileNo = G.MobileNo);

    IF OBJECT_ID('tempdb..#Benefit') IS NOT NULL DROP TABLE #Benefit;

    SELECT 
        BLE.M_ConsumerId,
        MAX(BLE.UpdateDate) AS LastActionDate,
        SUM(CASE WHEN BLE.Points IS NULL OR BLE.Points = 0 THEN ISNULL(BLE.Cash, 0) ELSE BLE.Points END) AS Benefit
    INTO #Benefit
    FROM BLoyaltyPointsEarned BLE WITH (NOLOCK)
    LEFT JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BLE.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    LEFT JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    WHERE 
        ISNULL(BLE.CompId, MC.Compid) = @ActualCompId
        AND BLE.UpdateDate >= @CompRegDate
        AND BLE.UpdateDate >= @StartDate
        AND BLE.UpdateDate < DATEADD(DAY, 1, @EndDate)
        AND BLE.M_ConsumerId IN (SELECT M_ConsumerId FROM #Users)
    GROUP BY BLE.M_ConsumerId; 

    IF OBJECT_ID('tempdb..#Claims') IS NOT NULL DROP TABLE #Claims;

    SELECT 
        CD.MobileNo,
        SUM(ISNULL(CD.Amount, 0)) AS ClaimsAmount
    INTO #Claims
    FROM ClaimDetails CD WITH (NOLOCK)
    WHERE CD.Comp_Id = @ActualCompId AND CD.Isapproved = 1 AND PaymentStatus = 'Success'
      AND CD.Claim_date >= @CompRegDate
      AND CD.Claim_date >= @StartDate AND CD.Claim_date < DATEADD(DAY, 1, @EndDate)
      AND EXISTS (SELECT 1 FROM #Users U WHERE U.MobileNo = CD.MobileNo)
    GROUP BY CD.MobileNo;

    IF OBJECT_ID('tempdb..#UPI') IS NOT NULL DROP TABLE #UPI;

    SELECT 
        UPI.M_CounserID AS M_Consumerid,
        SUM(ISNULL(CAST(UPI.Amount AS DECIMAL(18,2)), 0)) AS UPIAmount
    INTO #UPI
    FROM Transactions UPI WITH (NOLOCK)
    WHERE UPI.CompId = REPLACE(@ActualCompId, 'Comp-', '') AND UPI.Issuccess = 1
      AND UPI.TransactionDate >= @CompRegDate
      AND UPI.TransactionDate >= @StartDate AND UPI.TransactionDate < DATEADD(DAY, 1, @EndDate)
      AND EXISTS (SELECT 1 FROM #Users U WHERE U.M_ConsumerId = UPI.M_CounserID)
    GROUP BY UPI.M_CounserID;

    SELECT TOP 30
        U.ConsumerName,
        U.MobileNo,
        ISNULL(S.State, '') AS State,
        ISNULL(S.City, '') AS City,
        ISNULL(U.PinCode, '') AS PinCode,
        CAST(ISNULL(B.Benefit, 0) AS NVARCHAR(50)) AS Benefit,
        0 AS ClaimsAmount1,
        ISNULL(C.ClaimsAmount, 0) + ISNULL(P.UPIAmount, 0) AS ClaimsAmount,
        ISNULL(CONVERT(VARCHAR, B.LastActionDate, 103) + ' ' + CONVERT(VARCHAR, B.LastActionDate, 108), '') AS LastActionDate
    FROM #Users U
    JOIN #Benefit B ON B.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Claims C ON C.MobileNo = U.MobileNo
    LEFT JOIN #UPI P ON P.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #State S ON S.MobileNo = U.MobileNo AND S.rn = 1
    WHERE B.Benefit > 0
    ORDER BY B.Benefit DESC;
END
GO
