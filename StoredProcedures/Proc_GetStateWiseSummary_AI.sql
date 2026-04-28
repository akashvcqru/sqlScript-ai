USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[Proc_GetStateWiseSummary_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Proc_GetStateWiseSummary_AI]
      @Comp_Id VARCHAR(30),
      @datePreset NVARCHAR(20) = NULL,
      @Type NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;

DECLARE @StartDate DATE;
DECLARE @EndDate   DATE;

DECLARE @Today DATE = CAST(GETDATE() AS DATE);
DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

-- Monday as first day of week
SET DATEFIRST 1;

------------------------------------------------
-- START DATE (CALENDAR-BASED)
------------------------------------------------
SET @StartDate =
    CASE
        -- TODAY
        WHEN @Win = 'TODAY'
            THEN @Today

        -- CURRENT WEEK (Monday → Today)
        WHEN @Win = 'WEEK'
            THEN DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today)

        -- LAST WEEK (Previous Monday)
        WHEN @Win = 'LASTWEEK'
            THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0)

        -- CURRENT MONTH (1st → Today)
        WHEN @Win = 'MONTH'
            THEN DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)

        -- LAST MONTH (1st of previous month)
        WHEN @Win = 'LASTMONTH'
            THEN DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1))

        -- QUARTER (Rolling last 90 days)
        WHEN @Win = 'QUARTER'
            THEN DATEADD(DAY, -90, @Today)

        -- YEAR
        WHEN @Win = 'YEAR'
            THEN DATEFROMPARTS(YEAR(@Today), 1, 1)

        -- LAST YEAR
        WHEN @Win = 'LASTYEAR'
            THEN DATEFROMPARTS(YEAR(@Today) - 1, 1, 1)

        -- DEFAULT → CURRENT MONTH
        ELSE DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)
    END;

------------------------------------------------
-- END DATE (CALENDAR-BASED)
------------------------------------------------
SET @EndDate =
    CASE
        -- LAST WEEK → Previous Sunday
        WHEN @Win = 'LASTWEEK'
            THEN DATEADD(
                    DAY,
                    -1,
                    DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0)
                 )

        -- LAST MONTH → Last day of previous month
        WHEN @Win = 'LASTMONTH'
            THEN EOMONTH(@Today, -1)

        -- LAST YEAR → Last day of previous year
        WHEN @Win = 'LASTYEAR'
            THEN DATEADD(DAY, -1, DATEFROMPARTS(YEAR(@Today), 1, 1))

        -- ALL OTHERS → Today
        ELSE @Today
    END;

    -------------------------------------------------------------------
    -- BENEFITS REPORT
    -------------------------------------------------------------------
    IF UPPER(@Type) = 'BENEFITS'
    BEGIN

        -------------------------------------------------------------------
        -- RESULT 2️⃣ : REGION SUMMARY + % SHARE
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
            FROM BLoyaltyPointsEarned B WITH (NOLOCK)
            INNER JOIN M_Consumer C WITH (NOLOCK)
                ON B.M_ConsumerId = C.M_ConsumerId
            WHERE B.Compid = @Comp_Id
              AND CAST(B.UpdateDate AS DATE) BETWEEN @StartDate AND @EndDate
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
        -- RESULT 3️⃣ : UNIVERSAL REGION × LABEL HEATMAP
        -------------------------------------------------------------------
       ;WITH LabelSource AS (
            SELECT 
                CASE 
                    -- WEEK / LASTWEEK → Mon, Tue
                    WHEN @Win IN ('WEEK','LASTWEEK')
                        THEN LEFT(DATENAME(WEEKDAY, Dt), 3)
 
                    -- MONTH / LASTMONTH → 14 JAN 25
                    WHEN @Win IN ('MONTH','LASTMONTH')
                        THEN FORMAT(Dt, 'dd MMM yy', 'en-US')
 
                    -- QUARTER → JAN 25
                    WHEN @Win = 'QUARTER'
                        THEN FORMAT(Dt, 'MMM yy', 'en-US')

                    -- YEAR / LASTYEAR → JAN 25
                    WHEN @Win IN ('YEAR','LASTYEAR')
                        THEN FORMAT(Dt, 'MMM yy', 'en-US')
 
                    ELSE FORMAT(Dt, 'dd MMM yy', 'en-US')
                END AS Label,
                Dt
            FROM (
                SELECT DATEADD(DAY, v.number, @StartDate) AS Dt
                FROM master..spt_values v
                WHERE v.type = 'P'
                  AND v.number <= DATEDIFF(DAY, @StartDate, @EndDate)
            ) X
        ),
        Base AS (
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
                ISNULL(B.Points,0) AS Points
            FROM BLoyaltyPointsEarned B WITH (NOLOCK)
            INNER JOIN M_Consumer C WITH (NOLOCK)
                ON B.M_ConsumerId = C.M_ConsumerId
            WHERE B.Compid = @Comp_Id
              AND CAST(B.UpdateDate AS DATE) BETWEEN @StartDate AND @EndDate
        ),
        Mapped AS (
            SELECT 
                L.Label,
                L.Dt,
                B.Region,
                B.Points
            FROM LabelSource L
            LEFT JOIN Base B ON B.Dt = L.Dt
        )
        SELECT 
            Label,
            SUM(CASE WHEN Region = 'North' THEN Points END) AS North_Points,
            SUM(CASE WHEN Region = 'South' THEN Points END) AS South_Points,
            SUM(CASE WHEN Region = 'East'  THEN Points END) AS East_Points,
            SUM(CASE WHEN Region = 'West'  THEN Points END) AS West_Points,
            SUM(CASE WHEN Region = 'Other' THEN Points END) AS Other_Points
        FROM Mapped
        GROUP BY Label
        ORDER BY MIN(Dt);

        RETURN;
    END
END
