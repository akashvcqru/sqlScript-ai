USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetScanPeakActivityHour_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetScanPeakActivityHour_AI]  
(  
    @CompId NVARCHAR(50),  
    @TimeWindow NVARCHAR(20) = NULL     -- Allowed: TODAY, WEEK, MONTH, QUARTER  
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


    -----------------------------------------------------
    -- ⭐ FIRST RESULT SET
    --    TimeSlot | TotalScans | Percentage
    -----------------------------------------------------
    ;WITH ScanData AS
    (
        SELECT DATEPART(HOUR, Enq_Date) AS ScanHour
        FROM Pro_Enq
        WHERE CAST(Enq_Date AS DATE) BETWEEN @StartDate AND @EndDate
          AND (@CompId IS NULL OR Comp_ID = @CompId)
    ),
    SlotData AS
    (
        SELECT 
            CASE 
                WHEN ScanHour BETWEEN 10 AND 11 THEN '10AM - 12PM'
                WHEN ScanHour BETWEEN 12 AND 13 THEN '12PM - 2PM'
                WHEN ScanHour BETWEEN 14 AND 15 THEN '2PM - 4PM'
                WHEN ScanHour BETWEEN 16 AND 17 THEN '4PM - 6PM'
                WHEN ScanHour BETWEEN 22 AND 23 THEN '10PM - 12AM'
                ELSE NULL
            END AS TimeSlot
        FROM ScanData
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
        CAST(COUNT(*) * 100.0 / (SELECT TotalScanCount FROM TotalScans) AS DECIMAL(10,2)) AS PercentageOfTotal
    FROM SlotData SD
    WHERE SD.TimeSlot IS NOT NULL
    GROUP BY SD.TimeSlot
    ORDER BY 
        CASE SD.TimeSlot
            WHEN '10AM - 12PM' THEN 1
            WHEN '12PM - 2PM'  THEN 2
            WHEN '2PM - 4PM'   THEN 3
            WHEN '4PM - 6PM'   THEN 4
            WHEN '10PM - 12AM' THEN 5
        END;


    -----------------------------------------------------
    -- ⭐ SECOND RESULT SET
    --    MorningPeakSlot | MorningPercent |
    --    EveningPeakSlot | EveningPercent
    -----------------------------------------------------

    ;WITH ScanData AS
    (
        SELECT DATEPART(HOUR, Enq_Date) AS ScanHour
        FROM Pro_Enq
        WHERE CAST(Enq_Date AS DATE) BETWEEN @StartDate AND @EndDate
          AND (@CompId IS NULL OR Comp_ID = @CompId)
    ),
    SlotData AS
    (
        SELECT 
            CASE 
                WHEN ScanHour BETWEEN 10 AND 11 THEN '10AM - 12PM'
                WHEN ScanHour BETWEEN 12 AND 13 THEN '12PM - 2PM'
                WHEN ScanHour BETWEEN 14 AND 15 THEN '2PM - 4PM'
                WHEN ScanHour BETWEEN 16 AND 17 THEN '4PM - 6PM'
                WHEN ScanHour BETWEEN 22 AND 23 THEN '10PM - 12AM'
                ELSE NULL
            END AS TimeSlot
        FROM ScanData
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
            CAST(TotalScans * 100.0 / (SELECT TotalScanCount FROM TotalScans) AS DECIMAL(10,2)) AS PercentOfTotal
        FROM SlotSummary
    ),
    Morning AS
    (
        SELECT TOP 1 *
        FROM SlotSummaryWithPercent
        WHERE TimeSlot IN ('10AM - 12PM', '12PM - 2PM')
        ORDER BY TotalScans DESC
    ),
    Evening AS
    (
        SELECT TOP 1 *
        FROM SlotSummaryWithPercent
        WHERE TimeSlot IN ('2PM - 4PM', '4PM - 6PM', '10PM - 12AM')
        ORDER BY TotalScans DESC
    )
    SELECT  
        (SELECT TimeSlot FROM Morning) AS MorningPeakSlot,
        (SELECT PercentOfTotal FROM Morning) AS MorningPeakPercent,

        (SELECT TimeSlot FROM Evening) AS EveningPeakSlot,
        (SELECT PercentOfTotal FROM Evening) AS EveningPeakPercent;

END
