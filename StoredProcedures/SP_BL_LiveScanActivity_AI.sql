USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_LiveScanActivity_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_LiveScanActivity_AI]
(
    @CompId NVARCHAR(50),
    @TimeWindow NVARCHAR(20)=NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = Reg_Date FROM Comp_Reg WHERE Comp_ID = @CompId AND Status = 1;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @StartDate DATE;
    DECLARE @EndDate   DATE;

    SET DATEFIRST 1;

    SET @StartDate =
        CASE
            WHEN UPPER(@TimeWindow) = 'TODAY' THEN @Today
            WHEN UPPER(@TimeWindow) = 'YESTERDAY' THEN DATEADD(DAY, -1, @Today)
            WHEN UPPER(@TimeWindow) = 'WEEK' THEN DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today)
            WHEN UPPER(@TimeWindow) = 'LASTWEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0)
            WHEN UPPER(@TimeWindow) = 'MONTH' THEN DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)
            WHEN UPPER(@TimeWindow) = 'LASTMONTH' THEN DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1))
            WHEN UPPER(@TimeWindow) = 'QUARTER' THEN DATEADD(DAY, -90, @Today)
            ELSE DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1) -- default MONTH
        END;

    SET @EndDate =
        CASE
            WHEN UPPER(@TimeWindow) = 'YESTERDAY' THEN DATEADD(DAY, -1, @Today)
            WHEN UPPER(@TimeWindow) = 'LASTWEEK' THEN DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0))
            WHEN UPPER(@TimeWindow) = 'LASTMONTH' THEN EOMONTH(@Today, -1)
            ELSE @Today
        END;

    IF OBJECT_ID('tempdb..#Scans') IS NOT NULL DROP TABLE #Scans;

    SELECT
        PE.MobileNo,
        CAST(PE.Received_Code1 AS NVARCHAR(20)) AS Code1,
        CAST(PE.Received_Code2 AS NVARCHAR(20)) AS Code2,
        PE.Is_Success,
        PE.Enq_Date
    INTO #Scans
    FROM Pro_Enq PE WITH (NOLOCK)
    WHERE PE.Comp_ID = @CompId
      AND PE.Is_Success IN (1,2,0)
      AND PE.Enq_Date >= @StartDate 
      AND PE.Enq_Date < DATEADD(DAY,1,@EndDate);

    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT 
        CAST(Code1 AS NVARCHAR(20)) AS Code1,
        CAST(Code2 AS NVARCHAR(20)) AS Code2,
        SUM(ISNULL(Points,0)) AS TotalPoints
    INTO #Points
    FROM BLoyaltyPointsEarned WITH (NOLOCK)
    WHERE CompId = @CompId
    GROUP BY Code1, Code2;

    -- RESULT 1: Latest Scan Records
    SELECT TOP 50
        ISNULL(MC.ConsumerName, 'Not Registered') AS ConsumerName,
        PR.Pro_Name,
        G.[State],
        G.City,
        G.Postcode AS PinCode,
        G.Latitude,
        G.Longitude,
        S.MobileNo,
        ISNULL(P.TotalPoints,0) AS Points,
        CASE 
            WHEN S.Is_Success = 1 THEN 'VERIFIED'
            WHEN S.Is_Success = 2 THEN 'DUPLICATE'
            ELSE 'INVALID'
        END AS RESULT,
        (S.Code1 + S.Code2) AS UniqueCode,
        S.Enq_Date AS ScanDate
    FROM #Scans S
    INNER JOIN M_Code MCd WITH (NOLOCK)
            ON S.Code1 = CAST(MCd.Code1 AS NVARCHAR(20))
           AND S.Code2 = CAST(MCd.Code2 AS NVARCHAR(20))
    INNER JOIN Pro_Reg PR WITH (NOLOCK)
            ON PR.Pro_ID = MCd.Pro_ID
           AND PR.Comp_ID = @CompId
    LEFT JOIN #Points P ON P.Code1 = S.Code1 AND P.Code2 = S.Code2
    LEFT JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = S.MobileNo AND MC.IsDelete = 0
    LEFT JOIN GeoLocationData G WITH (NOLOCK) ON G.Code1 = S.Code1 AND G.Code2 = S.Code2 AND G.Comp_Id = @CompId
    ORDER BY S.Enq_Date DESC;

    -- RESULT 2: Summary Counts
    SELECT 
        CASE 
            WHEN Is_Success = 1 THEN 'VERIFIED'
            WHEN Is_Success = 2 THEN 'DUPLICATE'
            ELSE 'INVALID'
        END AS RESULT,
        COUNT(*) AS TotalScans
    FROM #Scans
    GROUP BY 
        CASE 
            WHEN Is_Success = 1 THEN 'VERIFIED'
            WHEN Is_Success = 2 THEN 'DUPLICATE'
            ELSE 'INVALID'
        END
    ORDER BY TotalScans DESC;
END
