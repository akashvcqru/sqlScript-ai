USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_LiveScanActivity_MAndM_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_LiveScanActivity_MAndM_AI]
(
    @Comp_Id NVARCHAR(50) = NULL,
    @CompId NVARCHAR(50) = NULL,
    @datePreset NVARCHAR(20)=NULL,
    @FromDate NVARCHAR(20)=NULL,
    @ToDate NVARCHAR(20)=NULL,
    @Filter NVARCHAR(50)=NULL
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
    WHERE Comp_ID = @ActualCompId AND Status = 1;

    IF @CompRegDate IS NULL 
        SET @CompRegDate = '2000-01-01';

    ------------------------------------------------
    -- DATE RANGE LOGIC
    ------------------------------------------------
    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATE);
        SET @EndDate = CAST(@ToDate AS DATE);
    END
    ELSE IF @Win = 'WEEK' OR @Win = 'THISWEEK'
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
    -- FETCH AND FILTER SCAN DATA (using pre-aggregated table)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Scans') IS NOT NULL DROP TABLE #Scans;

    SELECT
        pc.MobileNo,
        pc.Code1,
        pc.Code2,
        pc.Is_Success,
        pc.Enq_Date,
        pc.Pro_Name,
        pc.Points,
        pc.Cash,
        pc.M_ConsumerId
    INTO #Scans
    FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
    LEFT JOIN dbo.UserData_MHCroneJob mc WITH (NOLOCK) ON mc.m_consumerid = pc.m_consumerid
    WHERE pc.Comp_ID = @ActualCompId
      AND pc.Is_Success IN (1,2,0)
      AND pc.Enq_Date >= @CompRegDate
      AND pc.Enq_Date >= @StartDate 
      AND pc.Enq_Date < DATEADD(DAY,1,@EndDate)
      AND (
            (@IsSBUTeam = 0 AND (pc.distributedid <> 'SBUTEAM' OR pc.distributedid IS NULL) AND (mc.DealerCode <> 'SBUTEAM' OR mc.DealerCode IS NULL)) OR
            (@IsSBUTeam = 1 AND (pc.distributedid = 'SBUTEAM' OR mc.DealerCode = 'SBUTEAM'))
          );

    ---------------------------------------------------------
    -- RESULT 1: Latest Scan Records (Top 50)
    ---------------------------------------------------------
    SELECT TOP 50
        ISNULL(mc.ConsumerName, 'Not Registered') AS ConsumerName,
        S.Pro_Name,
        G.[State],
        G.City,
        G.Postcode AS PinCode,
        G.Latitude,
        G.Longitude,
        S.MobileNo,
        CASE WHEN S.Is_Success = 1 THEN 
            CASE WHEN S.Points IS NULL OR S.Points = 0 THEN CAST(S.Cash AS SQL_VARIANT) ELSE CAST(S.Points AS SQL_VARIANT) END 
            ELSE CAST(0 AS SQL_VARIANT) 
        END AS Points,
        CASE 
            WHEN S.Is_Success = 1 THEN 'VERIFIED'
            WHEN S.Is_Success = 2 THEN 'DUPLICATE'
            ELSE 'INVALID'
        END AS RESULT,
        (S.Code1 + S.Code2) AS UniqueCode,
        S.Enq_Date AS ScanDate
    FROM #Scans S
    LEFT JOIN dbo.UserData_MHCroneJob mc WITH (NOLOCK) ON mc.m_consumerid = S.M_ConsumerId
    LEFT JOIN GeoLocationData G WITH (NOLOCK) ON G.Code1 = S.Code1 AND G.Code2 = S.Code2 AND G.Comp_Id = @ActualCompId AND G.Enq_Date >= @CompRegDate
    WHERE (@Filter IS NULL OR 
           (@Filter = 'VERIFIED' AND S.Is_Success = 1) OR
           (@Filter = 'DUPLICATE' AND S.Is_Success = 2) OR
           (@Filter = 'INVALID' AND S.Is_Success = 0))
    ORDER BY S.Enq_Date DESC;

    ---------------------------------------------------------
    -- RESULT 2: Summary Counts
    ---------------------------------------------------------
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
GO
