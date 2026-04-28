USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_TopBeneficiaries_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_TopBeneficiaries_AI]
(  
    @CompId     NVARCHAR(50),  
    @datePreset NVARCHAR(20) = NULL
)  
AS  
BEGIN  
  SET NOCOUNT ON;

  DECLARE @StartDate DATETIME, @EndDate DATETIME;
  SET @EndDate = CAST(GETDATE() AS DATETIME);

  DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, 'WEEK'))));
  
  IF @Win = 'TODAY'
  BEGIN
      SET @StartDate = CAST(CAST(@EndDate AS DATE) AS DATETIME);
  END
  ELSE IF @Win = 'WEEK'
  BEGIN
      SET @StartDate = DATEADD(DAY, -7, @EndDate);
  END
  ELSE IF @Win = 'LASTWEEK'
  BEGIN
      SET @StartDate = DATEADD(DAY, -14, @EndDate);
  END
  ELSE IF @Win = 'MONTH'
  BEGIN
      SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0);
      SET @EndDate = EOMONTH(@EndDate);
  END
  ELSE IF @Win = 'LASTMONTH'
  BEGIN
      SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
      SET @EndDate = EOMONTH(DATEADD(MONTH, -1, @EndDate));
  END
  ELSE IF @Win = 'QUARTER'
  BEGIN
      SET @StartDate = DATEADD(DAY, -90, @EndDate);
  END
  ELSE IF @Win = 'YEAR'
  BEGIN
      SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
      SET @EndDate = GETDATE();
  END
  ELSE IF @Win = 'LASTYEAR'
  BEGIN
      SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
      SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
  END
  ELSE IF @Win = 'ALL'
  BEGIN
      SET @StartDate = DATEADD(DAY, -10000, @EndDate);
  END
  ELSE
  BEGIN
      SET @StartDate = DATEADD(DAY, -7, @EndDate);
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
    WHERE V.Comp_Id = @CompId AND MC.IsDelete='0';

    CREATE CLUSTERED INDEX IX_Users ON #Users (M_ConsumerId);

    IF OBJECT_ID('tempdb..#State') IS NOT NULL DROP TABLE #State;

    SELECT 
        G.MobileNo,
        G.State,
        G.City,
        ROW_NUMBER() OVER (PARTITION BY G.MobileNo ORDER BY G.Enq_Date DESC) AS rn
    INTO #State
    FROM GeoLocationData G WITH (NOLOCK)
    WHERE G.Comp_Id = @CompId
      AND G.Enq_Date >= @StartDate
      AND G.Enq_Date < DATEADD(DAY, 1, @EndDate)
      AND EXISTS (SELECT 1 FROM #Users U WHERE U.MobileNo = G.MobileNo);

    IF OBJECT_ID('tempdb..#Benefit') IS NOT NULL DROP TABLE #Benefit;

    SELECT 
        BLE.M_ConsumerId,
        MAX(BLE.UpdateDate) AS LastActionDate,
        SUM(ISNULL(BLE.Points, 0)) AS Benefit
    INTO #Benefit
    FROM BLoyaltyPointsEarned BLE WITH (NOLOCK)
    WHERE 
        BLE.CompId = @CompId
        AND BLE.UpdateDate >= @StartDate
        AND BLE.UpdateDate < DATEADD(DAY, 1, @EndDate)
        AND EXISTS (SELECT 1 FROM #Users U WHERE U.M_ConsumerId = BLE.M_ConsumerId)
    GROUP BY BLE.M_ConsumerId; 

    IF OBJECT_ID('tempdb..#Claims') IS NOT NULL DROP TABLE #Claims;

    SELECT 
        CD.MobileNo,
        SUM(CASE WHEN @CompId = 'Comp-1727' THEN ISNULL(CD.PointsValue, 0)
                 ELSE ISNULL(CD.Amount, 0) END) AS ClaimsAmount
    INTO #Claims
    FROM ClaimDetails CD WITH (NOLOCK)
    WHERE CD.Comp_Id = @CompId AND CD.Isapproved = 1 AND PaymentStatus = 'Success'
      AND CD.Claim_date >= @StartDate AND CD.Claim_date < DATEADD(DAY, 1, @EndDate)
      AND EXISTS (SELECT 1 FROM #Users U WHERE U.MobileNo = CD.MobileNo)
    GROUP BY CD.MobileNo;

    IF OBJECT_ID('tempdb..#UPI') IS NOT NULL DROP TABLE #UPI;

    SELECT 
        UPI.M_Consumerid,
        SUM(ISNULL(UPI.Amount, 0)) AS UPIAmount
    INTO #UPI
    FROM tblUPITransactionDetails UPI WITH (NOLOCK)
    WHERE UPI.Comp_Id = @CompId AND UPI.Status = 'Success' AND LEN(UPI.Code1) > 3
      AND UPI.ReqDate >= @StartDate AND UPI.ReqDate < DATEADD(DAY, 1, @EndDate)
      AND EXISTS (SELECT 1 FROM #Users U WHERE U.M_ConsumerId = UPI.M_Consumerid)
    GROUP BY UPI.M_Consumerid;

    SELECT TOP 30
        U.ConsumerName,
        U.MobileNo,
        S.State,
        S.City,
        U.PinCode,
        B.Benefit,
        (SELECT COUNT(*) FROM Pro_Enq PE WHERE PE.MobileNo = U.MobileNo AND PE.Comp_ID = @CompId AND PE.Enq_Date >= @StartDate AND PE.Enq_Date < DATEADD(DAY, 1, @EndDate)) AS TotalScans,
        ISNULL(C.ClaimsAmount, 0) + ISNULL(P.UPIAmount, 0) AS ClaimsAmount,
        B.LastActionDate
    FROM #Users U
    LEFT JOIN #Benefit B ON B.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Claims C ON C.MobileNo = U.MobileNo
    LEFT JOIN #UPI P ON P.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #State S ON S.MobileNo = U.MobileNo AND S.rn = 1
    WHERE B.Benefit > 0
    ORDER BY B.Benefit DESC;
END
