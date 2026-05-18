USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetScanPeakActivityHour_MAndM_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetScanPeakActivityHour_MAndM_AI]  
(  
    @Comp_Id NVARCHAR(50) = NULL,
    @CompId NVARCHAR(50) = NULL,  
    @datePreset NVARCHAR(20) = NULL     -- Allowed: TODAY, WEEK, MONTH, QUARTER, YEAR, LASTYEAR
)  
AS  
BEGIN  
  SET NOCOUNT ON;

  ---------------------------------------------------------
  -- Dual Parameter Normalization & SBU Company Logic
  ---------------------------------------------------------
  DECLARE @InputCompId NVARCHAR(50);
  IF @Comp_Id IS NULL AND @CompId IS NOT NULL
      SET @InputCompId = @CompId;
  ELSE
      SET @InputCompId = @Comp_Id;

  DECLARE @ActualCompId NVARCHAR(50) = @InputCompId;
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
  ELSE
  BEGIN
      -- Default to THIS WEEK
      SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
      SET @EndDate = CAST(GETDATE() AS DATE);
  END

  ---------------------------------------------------------
  -- SINGLE SCAN HOURS MATERIALIZATION (using pre-aggregated table)
  ---------------------------------------------------------
  IF OBJECT_ID('tempdb..#ScanHours') IS NOT NULL DROP TABLE #ScanHours;

  SELECT DATEPART(HOUR, pc.Enq_Date) AS ScanHour
  INTO #ScanHours
  FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
  LEFT JOIN dbo.UserData_MHCroneJob mc WITH (NOLOCK) ON mc.m_consumerid = pc.m_consumerid
  WHERE pc.Comp_ID = @ActualCompId
    AND pc.Enq_Date >= @CompRegDate
    AND pc.Enq_Date >= @StartDate
    AND pc.Enq_Date < DATEADD(DAY, 1, @EndDate)
    AND (
          (@IsSBUTeam = 0 AND (pc.distributedid <> 'SBUTEAM' OR pc.distributedid IS NULL) AND (mc.DealerCode <> 'SBUTEAM' OR mc.DealerCode IS NULL)) OR
          (@IsSBUTeam = 1 AND (pc.distributedid = 'SBUTEAM' OR mc.DealerCode = 'SBUTEAM'))
        );

  -----------------------------------------------------
  -- ⭐ FIRST RESULT SET
  --    TimeSlot | TotalScans | Percentage
  -----------------------------------------------------
  ;WITH SlotData AS
  (
      SELECT 
          CASE 
              WHEN ScanHour BETWEEN 0  AND 1  THEN '12AM - 02AM'
              WHEN ScanHour BETWEEN 2  AND 3  THEN '02AM - 04AM'
              WHEN ScanHour BETWEEN 4  AND 5  THEN '04AM - 06AM'
              WHEN ScanHour BETWEEN 6  AND 7  THEN '06AM - 08AM'
              WHEN ScanHour BETWEEN 8  AND 9  THEN '08AM - 10AM'
              WHEN ScanHour BETWEEN 10 AND 11 THEN '10AM - 12PM'
              WHEN ScanHour BETWEEN 12 AND 13 THEN '12PM - 02PM'
              WHEN ScanHour BETWEEN 14 AND 15 THEN '02PM - 04PM'
              WHEN ScanHour BETWEEN 16 AND 17 THEN '04PM - 06PM'
              WHEN ScanHour BETWEEN 18 AND 19 THEN '06PM - 08PM'
              WHEN ScanHour BETWEEN 20 AND 21 THEN '08PM - 10PM'
              WHEN ScanHour BETWEEN 22 AND 23 THEN '10PM - 12AM'
              ELSE 'Other'
          END AS TimeSlot
      FROM #ScanHours
  ),
  TotalScans AS
  (
      SELECT COUNT(*) AS TotalScanCount
      FROM SlotData
      WHERE TimeSlot IS NOT NULL
  )
  SELECT 
      SD.TimeSlot,
      COUNT(*) AS TotalScans,
      CAST(COUNT(*) * 100.0 / NULLIF((SELECT TotalScanCount FROM TotalScans), 0) AS DECIMAL(10,2)) AS PercentageOfTotal
  FROM SlotData SD
  WHERE SD.TimeSlot IS NOT NULL
  GROUP BY SD.TimeSlot
  ORDER BY 
      CASE SD.TimeSlot
          WHEN '12AM - 02AM' THEN 1
          WHEN '02AM - 04AM' THEN 2
          WHEN '04AM - 06AM' THEN 3
          WHEN '06AM - 08AM' THEN 4
          WHEN '08AM - 10AM' THEN 5
          WHEN '10AM - 12PM' THEN 6
          WHEN '12PM - 02PM' THEN 7
          WHEN '02PM - 04PM' THEN 8
          WHEN '04PM - 06PM' THEN 9
          WHEN '06PM - 08PM' THEN 10
          WHEN '08PM - 10PM' THEN 11
          WHEN '10PM - 12AM' THEN 12
          ELSE 13
      END;

  -----------------------------------------------------
  -- ⭐ SECOND RESULT SET
  --    MorningPeakSlot | MorningPercent |
  --    EveningPeakSlot | EveningPercent
  -----------------------------------------------------
  ;WITH SlotData AS
  (
      SELECT 
          CASE 
              WHEN ScanHour BETWEEN 0  AND 1  THEN '12AM - 02AM'
              WHEN ScanHour BETWEEN 2  AND 3  THEN '02AM - 04AM'
              WHEN ScanHour BETWEEN 4  AND 5  THEN '04AM - 06AM'
              WHEN ScanHour BETWEEN 6  AND 7  THEN '06AM - 08AM'
              WHEN ScanHour BETWEEN 8  AND 9  THEN '08AM - 10AM'
              WHEN ScanHour BETWEEN 10 AND 11 THEN '10AM - 12PM'
              WHEN ScanHour BETWEEN 12 AND 13 THEN '12PM - 02PM'
              WHEN ScanHour BETWEEN 14 AND 15 THEN '02PM - 04PM'
              WHEN ScanHour BETWEEN 16 AND 17 THEN '04PM - 06PM'
              WHEN ScanHour BETWEEN 18 AND 19 THEN '06PM - 08PM'
              WHEN ScanHour BETWEEN 20 AND 21 THEN '08PM - 10PM'
              WHEN ScanHour BETWEEN 22 AND 23 THEN '10PM - 12AM'
              ELSE 'Other'
          END AS TimeSlot
      FROM #ScanHours
  ),
  SlotSummary AS
  (
      SELECT 
          TimeSlot,
          COUNT(*) AS TotalScans
      FROM SlotData
      WHERE TimeSlot IS NOT NULL
      GROUP BY TimeSlot
  ),
  TotalScans AS
  (
      SELECT SUM(TotalScans) AS TotalScanCount
      FROM SlotSummary
  ),
  SlotSummaryWithPercent AS
  (
      SELECT 
          TimeSlot,
          TotalScans,
          CAST(TotalScans * 100.0 / NULLIF((SELECT TotalScanCount FROM TotalScans), 0) AS DECIMAL(10,2)) AS PercentOfTotal
      FROM SlotSummary
  ),
  Morning AS
  (
      SELECT TOP 1 *
      FROM SlotSummaryWithPercent
      WHERE TimeSlot IN ('06AM - 08AM', '08AM - 10AM', '10AM - 12PM', '12PM - 02PM')
      ORDER BY TotalScans DESC
  ),
  Evening AS
  (
      SELECT TOP 1 *
      FROM SlotSummaryWithPercent
      WHERE TimeSlot IN ('04PM - 06PM', '06PM - 08PM', '08PM - 10PM', '10PM - 12AM')
      ORDER BY TotalScans DESC
  )
  SELECT  
      COALESCE((SELECT TimeSlot FROM Morning), 'N/A') AS MorningPeakSlot,
      COALESCE((SELECT PercentOfTotal FROM Morning), 0) AS MorningPeakPercent,

      COALESCE((SELECT TimeSlot FROM Evening), 'N/A') AS EveningPeakSlot,
      COALESCE((SELECT PercentOfTotal FROM Evening), 0) AS EveningPeakPercent;

END
GO
