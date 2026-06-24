USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[Proc_GetStateWiseSummary_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Proc_GetStateWiseSummary_AI]
      @Comp_Id VARCHAR(30) = NULL,
      @CompId VARCHAR(30) = NULL,
      @datePreset NVARCHAR(20) = NULL,
      @Type NVARCHAR(20) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET DATEFIRST 1;

  ---------------------------------------------------------
  -- Dual Parameter Normalization & SBU Company Logic
  ---------------------------------------------------------
  DECLARE @InputCompId VARCHAR(30);
  IF @Comp_Id IS NULL AND @CompId IS NOT NULL
      SET @InputCompId = @CompId;
  ELSE
      SET @InputCompId = @Comp_Id;

  DECLARE @ActualCompId VARCHAR(30) = @InputCompId;
  DECLARE @IsSBUTeam INT = 0;

  IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @InputCompId AND SubCompTypeType = 'SBUTEAM')
  BEGIN
      SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @InputCompId AND SubCompTypeType = 'SBUTEAM';
      SET @IsSBUTeam = 1;
  END

  DECLARE @StartDate DATE;
  DECLARE @EndDate   DATE;

  DECLARE @Today DATE = CAST(GETDATE() AS DATE);
  DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

  -- Normalize the filter string (consistent with other dashboard SPs)
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

  ------------------------------------------------
  -- DATE RANGE LOGIC (Standardized with other SPs)
  ------------------------------------------------
  IF @Win = 'WEEK'
  BEGIN
      SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0); -- Monday
      SET @EndDate = CAST(GETDATE() AS DATE);
  END
  ELSE IF @Win = 'LASTWEEK'
  BEGIN
      SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0); -- Prev Monday
      SET @EndDate = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)); -- Prev Sunday
  END
  ELSE IF @Win = 'MONTH'
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

  -------------------------------------------------------------------
  -- BENEFITS REPORT
  -------------------------------------------------------------------
  IF UPPER(ISNULL(@Type, 'BENEFITS')) = 'BENEFITS'
  BEGIN

      -------------------------------------------------------------------
      -- MATERIALIZE RELEVANT POINTS & CASH DATA
      -------------------------------------------------------------------
      IF OBJECT_ID('tempdb..#TempPoints') IS NOT NULL DROP TABLE #TempPoints;

      SELECT 
          B.M_ConsumerId,
          B.Points,
          B.Cash,
          B.Enq_Date AS UpdateDate
      INTO #TempPoints
      FROM dbo.ConsumerPointsCashDetails B WITH (NOLOCK)
      WHERE B.Comp_id = @ActualCompId
        AND B.Enq_Date >= @CompRegDate
        AND B.Enq_Date >= @StartDate
        AND B.Enq_Date < DATEADD(DAY, 1, @EndDate);

      -------------------------------------------------------------------
      -- RESULT 1: REGION SUMMARY + % SHARE (Cards at bottom)
      -------------------------------------------------------------------
      ;WITH RegionPoints AS (
          SELECT 
              CASE 
                  WHEN C.State IN ('Delhi','Haryana','Punjab','Himachal Pradesh','Uttar Pradesh','Uttarakhand','Jammu & Kashmir')
                      THEN 'North India'
                  WHEN C.State IN ('Maharashtra','Goa','Gujarat','Madhya Pradesh','Rajasthan')
                      THEN 'West India'
                  WHEN C.State IN ('Bihar','Jharkhand','Odisha','West Bengal','Assam','Sikkim')
                      THEN 'East India'
                  WHEN C.State IN ('Tamil Nadu','Kerala','Karnataka','Andhra Pradesh','Telangana')
                      THEN 'South India'
                  ELSE 'Other'
              END AS Region,
              SUM(ISNULL(B.Points,0)) AS TotalEarnPoints,
              SUM(ISNULL(B.Cash,0)) AS TotalEarnCash
          FROM #TempPoints B
          INNER JOIN dbo.UserData_MHCroneJob C WITH (NOLOCK)
              ON B.M_ConsumerId = C.M_ConsumerId
          WHERE (
                  (@IsSBUTeam = 0 AND (C.DealerCode <> 'SBUTEAM' OR C.DealerCode IS NULL)) OR
                  (@IsSBUTeam = 1 AND C.DealerCode = 'SBUTEAM')
                )
          GROUP BY 
              CASE 
                  WHEN C.State IN ('Delhi','Haryana','Punjab','Himachal Pradesh','Uttar Pradesh','Uttarakhand','Jammu & Kashmir')
                      THEN 'North India'
                  WHEN C.State IN ('Maharashtra','Goa','Gujarat','Madhya Pradesh','Rajasthan')
                      THEN 'West India'
                  WHEN C.State IN ('Bihar','Jharkhand','Odisha','West Bengal','Assam','Sikkim')
                      THEN 'East India'
                  WHEN C.State IN ('Tamil Nadu','Kerala','Karnataka','Andhra Pradesh','Telangana')
                      THEN 'South India'
                  ELSE 'Other'
              END
      ),
      Totals AS (
          SELECT 
              SUM(TotalEarnPoints) AS GrandTotalPoints,
              SUM(TotalEarnCash) AS GrandTotalCash
          FROM RegionPoints
      )
      SELECT 
          R.Region,
          R.TotalEarnPoints,
          R.TotalEarnCash,
          CAST(ROUND(
              CASE WHEN T.GrandTotalPoints = 0 THEN 0 
                   ELSE (R.TotalEarnPoints * 100.0 / T.GrandTotalPoints)
              END, 2) AS DECIMAL(10,2)) AS PointsPercentShare,
          CAST(ROUND(
              CASE WHEN T.GrandTotalCash = 0 THEN 0 
                   ELSE (R.TotalEarnCash * 100.0 / T.GrandTotalCash)
              END, 2) AS DECIMAL(10,2)) AS CashPercentShare
      FROM RegionPoints R
      CROSS JOIN Totals T
      ORDER BY R.Region;

      -------------------------------------------------------------------
      -- RESULT 2: REGION × LABEL HEATMAP (Chart data)
      -- Weekly grouping for MONTH/QUARTER, daily for WEEK
      -------------------------------------------------------------------
     ;WITH Base AS (
          SELECT 
              CAST(B.UpdateDate AS DATE) AS Dt,
              CASE 
                  WHEN C.State IN ('Delhi','Haryana','Punjab','Himachal Pradesh','Uttar Pradesh','Uttarakhand','Jammu & Kashmir')
                      THEN 'North'
                  WHEN C.State IN ('Maharashtra','Goa','Gujarat','Madhya Pradesh','Rajasthan')
                      THEN 'West'
                  WHEN C.State IN ('Bihar','Jharkhand','Odisha','West Bengal','Assam','Sikkim')
                      THEN 'East'
                  WHEN C.State IN ('Tamil Nadu','Kerala','Karnataka','Andhra Pradesh','Telangana')
                      THEN 'South'
                  ELSE 'Other'
              END AS Region,
              CASE WHEN B.Points IS NULL OR B.Points = 0 THEN ISNULL(B.Cash, 0) ELSE B.Points END AS Points
          FROM #TempPoints B
          INNER JOIN dbo.UserData_MHCroneJob C WITH (NOLOCK)
              ON B.M_ConsumerId = C.M_ConsumerId
          WHERE (
                  (@IsSBUTeam = 0 AND (C.DealerCode <> 'SBUTEAM' OR C.DealerCode IS NULL)) OR
                  (@IsSBUTeam = 1 AND C.DealerCode = 'SBUTEAM')
                )
      )

      -- Dynamic label logic based on preset
      SELECT 
          CASE 
              -- WEEK / LASTWEEK → Day names (Mon, Tue, etc.)
              WHEN @Win IN ('WEEK','LASTWEEK')
                  THEN LEFT(DATENAME(WEEKDAY, Dt), 3)

              -- MONTH / LASTMONTH → Week N
              WHEN @Win IN ('MONTH','LASTMONTH')
                  THEN 'Week ' + CAST(
                      DATEDIFF(WEEK, @StartDate, Dt) + 1 
                      AS VARCHAR(2))

              -- QUARTER → Month name (Jan, Feb, etc.)
              WHEN @Win = 'QUARTER'
                  THEN LEFT(DATENAME(MONTH, Dt), 3)

              -- Default → Week N
              ELSE 'Week ' + CAST(
                  DATEDIFF(WEEK, @StartDate, Dt) + 1 
                  AS VARCHAR(2))
          END AS Label,

          SUM(CASE WHEN Region = 'North' THEN Points ELSE 0 END) AS North_Points,
          SUM(CASE WHEN Region = 'South' THEN Points ELSE 0 END) AS South_Points,
          SUM(CASE WHEN Region = 'East'  THEN Points ELSE 0 END) AS East_Points,
          SUM(CASE WHEN Region = 'West'  THEN Points ELSE 0 END) AS West_Points,
          SUM(CASE WHEN Region = 'Other' THEN Points ELSE 0 END) AS Other_Points
      FROM Base
      GROUP BY 
          CASE 
              WHEN @Win IN ('WEEK','LASTWEEK')
                  THEN LEFT(DATENAME(WEEKDAY, Dt), 3)
              WHEN @Win IN ('MONTH','LASTMONTH')
                  THEN 'Week ' + CAST(DATEDIFF(WEEK, @StartDate, Dt) + 1 AS VARCHAR(2))
              WHEN @Win = 'QUARTER'
                  THEN LEFT(DATENAME(MONTH, Dt), 3)
              ELSE 'Week ' + CAST(DATEDIFF(WEEK, @StartDate, Dt) + 1 AS VARCHAR(2))
          END
      ORDER BY MIN(Dt);

      RETURN;
  END
END
GO
