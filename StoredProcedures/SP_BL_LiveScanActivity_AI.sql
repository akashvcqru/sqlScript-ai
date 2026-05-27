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
    @datePreset NVARCHAR(20)=NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE, @EndDate DATE;

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
      AND PE.Enq_Date >= @CompRegDate
      AND PE.Enq_Date >= @StartDate 
      AND PE.Enq_Date < DATEADD(DAY,1,@EndDate);

    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT 
        CAST(Code1 AS NVARCHAR(20)) AS Code1,
        CAST(Code2 AS NVARCHAR(20)) AS Code2,
        SUM(CASE WHEN Points IS NULL OR Points = 0 THEN ISNULL(Cash,0) ELSE Points END) AS TotalPoints
    INTO #Points
    FROM BLoyaltyPointsEarned WITH (NOLOCK)
    WHERE (CompId = @CompId OR CompId IS NULL) AND UpdateDate >= @CompRegDate
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
        CASE WHEN S.Is_Success = 1 THEN ISNULL(P.TotalPoints,0) ELSE 0 END AS Points,
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
    LEFT JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = S.MobileNo AND MC.IsDelete = 0 AND MC.Entry_Date >= @CompRegDate
    LEFT JOIN GeoLocationData G WITH (NOLOCK) ON G.Code1 = S.Code1 AND G.Code2 = S.Code2 AND G.Comp_Id = @CompId AND G.Enq_Date >= @CompRegDate
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
