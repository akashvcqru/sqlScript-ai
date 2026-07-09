USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-09
-- Description: Retrieves daily fraud code check alert report (duplicate checks on valid codes), sorted by
--              enquiry date desc. Aligned with SP_BL_GetCodesActivityReport_AI logic.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_DailyFraudCodeCheckAlert_AI]
(
    @Comp_Id         NVARCHAR(50),
    @datePreset      NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, ALL, LAST7DAYS, CUSTOM
    @fromDate        NVARCHAR(30) = NULL,
    @toDate          NVARCHAR(30) = NULL,
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL,
    @Search          NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- DEFAULT PAGINATION & EXPORT FLAGS
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- DATE RANGE SETTING
    ---------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') 
    FROM Comp_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @CompanyName NVARCHAR(150);
    SELECT @CompanyName = ISNULL(Comp_Name, '') 
    FROM Comp_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    DECLARE @Preset NVARCHAR(20) = UPPER(ISNULL(@datePreset, ''));
    IF (@Preset = '' OR @Preset = 'NULL') 
    BEGIN
        IF (@fromDate IS NOT NULL AND @toDate IS NOT NULL)
            SET @Preset = 'CUSTOM';
        ELSE
            SET @Preset = 'LAST7DAYS';
    END

    IF (@Preset = 'TODAY')
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTDAY' OR @Preset = 'YESTERDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
        SET @EndDate   = CAST(GETDATE() AS DATE);
    END
    ELSE IF (@Preset = 'WEEK' OR @Preset = 'THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'QUARTER')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'YEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTYEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
    END
    ELSE IF (@Preset = 'LAST7DAYS' OR @Preset = '7DAYS')
    BEGIN
        SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'CUSTOM' AND @fromDate IS NOT NULL AND @toDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@fromDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@toDate AS DATE));
    END
    ELSE -- ALL or fallback
    BEGIN
        SET @StartDate = CAST(@CompanyStartDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    -- CLEANUP TEMP TABLES
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #Enq, #DuplicateCodes, #Codes, #MCode, #Pro, #Geo, #Points, #CodeConfigPoints, #CodeServices, #FinalReport, #PagedReport;

    ---------------------------------------------------------
    -- ENQUIRIES
    ---------------------------------------------------------
    SELECT 
        Received_Code1,
        Received_Code2,
        Enq_Date,
        Dial_Mode,
        Is_Success,
        MobileNo,
        Latitude,
        Longitude,
        M.Row_ID AS M_Codeid,
        M.Series_Order,
        M.Series_Serial
    INTO #Enq
    FROM Pro_Enq WITH (NOLOCK)
	INNER JOIN M_code M WITH (NOLOCK) 
	    ON Received_Code1 = CAST(code1 AS VARCHAR(50))
	   AND Received_Code2 = CAST(Code2 AS VARCHAR(50))
    INNER JOIN Pro_Reg PR WITH (NOLOCK)
        ON PR.Pro_ID = M.Pro_ID
    WHERE PR.Comp_ID = @Comp_Id
      AND Is_Success = 1
      AND Enq_Date >= @StartDate
      AND Enq_Date <  @EndDate;

    CREATE INDEX IX_Enq_Code   ON #Enq(Received_Code1, Received_Code2);
    CREATE INDEX IX_Enq_Mobile ON #Enq(MobileNo);

    ---------------------------------------------------------
    -- IDENTIFY CODES CHECKED MULTIPLE TIMES WITH IS_SUCCESS = 1 (OVERALL)
    ---------------------------------------------------------
    SELECT 
        Received_Code1,
        Received_Code2,
        COUNT(*) AS TotalChecks,
        COUNT(*) - 1 AS DuplicateCount
    INTO #DuplicateCodes
    FROM Pro_Enq WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id
      AND Is_Success = 1
    GROUP BY Received_Code1, Received_Code2
    HAVING COUNT(*) > 1;

    CREATE CLUSTERED INDEX IX_DuplicateCodes ON #DuplicateCodes(Received_Code1, Received_Code2);

    -- Keep only enquiries for duplicate codes
    DELETE E
    FROM #Enq E
    WHERE NOT EXISTS (
        SELECT 1 
        FROM #DuplicateCodes D 
        WHERE D.Received_Code1 = E.Received_Code1 
          AND D.Received_Code2 = E.Received_Code2
    );

    ---------------------------------------------------------
    -- UNIQUE CODES
    ---------------------------------------------------------
    SELECT DISTINCT 
        Received_Code1,
        Received_Code2
    INTO #Codes
    FROM #Enq;

    CREATE INDEX IX_Codes ON #Codes(Received_Code1, Received_Code2);

    ---------------------------------------------------------
    -- MCODES
    ---------------------------------------------------------
    SELECT 
        MCd.Code1,
        MCd.Code2,
        MCd.Pro_ID,
        MCd.Series_Order,
        MCd.Series_Serial,
        MCd.Row_ID AS M_Codeid
    INTO #MCode
    FROM M_Code MCd WITH (NOLOCK)
    INNER JOIN #Codes C
        ON MCd.Code1 = C.Received_Code1
       AND MCd.Code2 = C.Received_Code2;

    CREATE INDEX IX_MCode ON #MCode(Code1, Code2);

    ---------------------------------------------------------
    -- PRODUCTS
    ---------------------------------------------------------
    SELECT 
        Pro_ID,
        Pro_Name
    INTO #Pro
    FROM Pro_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id;

    CREATE INDEX IX_Pro ON #Pro(Pro_ID);

    ---------------------------------------------------------
    -- GEO
    ---------------------------------------------------------
    SELECT 
        Code1,
        Code2,
        MobileNo,
        State,
        City
    INTO #Geo
    FROM (
        SELECT 
            G.*,
            ROW_NUMBER() OVER (
                PARTITION BY G.Code1, G.Code2, G.MobileNo
                ORDER BY (SELECT NULL)
            ) rn
        FROM GeoLocationData G WITH (NOLOCK)
        INNER JOIN #Codes C
            ON G.Code1 = C.Received_Code1
           AND G.Code2 = C.Received_Code2
    ) X
    WHERE rn = 1;

    CREATE INDEX IX_Geo ON #Geo(Code1, Code2, MobileNo);

    ---------------------------------------------------------
    -- POINTS (REFACTORED - ID BASED)
    ---------------------------------------------------------
    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation WITH (NOLOCK)
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;
 
    SELECT
        MC.M_Codeid,
        MAX(CAST(
            CASE 
                WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
            END 
        AS DECIMAL(18,2))) AS Points,
        MAX(CAST(
            CASE 
                WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
            END 
        AS DECIMAL(18,2))) AS WornPoint
    INTO #Points
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN (
        SELECT Pkid, M_Consumer_MCOdeid, ROW_NUMBER() OVER (PARTITION BY M_Consumer_MCOdeid ORDER BY Createdate ASC) as rn
        FROM BuiltLoyaltyMCodeCheck WITH (NOLOCK)
    ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
    INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
    LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON BL.SST_id = sst.SST_Id
    LEFT JOIN M_ServiceSubscription ss WITH (NOLOCK) ON sst.Subscribe_Id = ss.Subscribe_Id
    WHERE BL.compid = @Comp_Id OR (BL.compid IS NULL AND PR.Comp_ID = @Comp_Id)
    GROUP BY MC.M_Codeid;

    CREATE INDEX IX_Points_MCodeid ON #Points(M_Codeid);

    ---------------------------------------------------------
    -- CODE CONFIG POINTS (PRECISE BY SERIES RANGE)
    ---------------------------------------------------------
    WITH RankedConfig AS (
        SELECT 
            MC.M_Codeid,
            SS.Service_ID,
            SST.Frequency,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SS.Service_ID = 'SRV1005' THEN ISNULL(SST.IsCash, 0)
                    ELSE CASE WHEN SST.Points IS NULL OR SST.Points = 0 THEN ISNULL(SST.IsCash, 0) ELSE SST.Points END
                END 
            AS DECIMAL(18,2)) AS ConfigPoints,
            CAST(
                CASE 
                    WHEN SS.Service_ID = 'SRV1005' THEN ISNULL(SST.IsCash, 0)
                    ELSE ISNULL(SST.Points, 0)
                END 
            AS DECIMAL(18,2)) AS AssignPoint,
            ROW_NUMBER() OVER (
                PARTITION BY MC.M_Codeid, SS.Service_ID 
                ORDER BY SST.Entry_Date DESC, SST.SST_Id DESC
            ) AS rn_service,
            SST.Entry_Date,
            SST.SST_Id
        FROM #MCode MC
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        WHERE SS.Comp_ID = @Comp_Id 
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
          AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
          AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
    ),
    UniqueServiceConfig AS (
        SELECT * 
        FROM RankedConfig 
        WHERE rn_service = 1
    ),
    FinalRankedConfig AS (
        SELECT 
            M_Codeid,
            Frequency,
            ConfigPoints,
            AssignPoint,
            ROW_NUMBER() OVER (
                PARTITION BY M_Codeid 
                ORDER BY Entry_Date DESC, SST_Id DESC
            ) AS rn_final
        FROM UniqueServiceConfig
    )
    SELECT 
        M_Codeid,
        Frequency,
        ConfigPoints,
        AssignPoint
    INTO #CodeConfigPoints
    FROM FinalRankedConfig
    WHERE rn_final = 1;

    CREATE INDEX IX_CodeConfigPoints_MCodeid ON #CodeConfigPoints(M_Codeid);

    ---------------------------------------------------------
    -- SERVICE NAMES ASSIGNED
    ---------------------------------------------------------
    SELECT 
        M.Row_ID AS M_Codeid,
        STRING_AGG(S.ServiceName, ', ') AS AssignedServices
    INTO #CodeServices
    FROM #Codes DC
    INNER JOIN M_Code M WITH (NOLOCK) 
        ON M.Code1 = TRY_CAST(DC.Received_Code1 AS NUMERIC(5,0)) 
       AND M.Code2 = TRY_CAST(DC.Received_Code2 AS NUMERIC(8,0))
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
    INNER JOIN M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
    WHERE SS.IsActive = 1 AND SS.IsDelete = 0 AND SS.Comp_ID = @Comp_Id
    GROUP BY M.Row_ID;

    CREATE CLUSTERED INDEX IX_CodeServices ON #CodeServices(M_Codeid);

    ---------------------------------------------------------
    -- COMPILE TEMPORARY FINAL REPORT
    ---------------------------------------------------------
    CREATE TABLE #FinalReport (
        CompanyName NVARCHAR(150),
        ProductName NVARCHAR(200),
        ServiceName NVARCHAR(500),
        AssignPoint DECIMAL(18,2),
        WornPoint DECIMAL(18,2),
        Frequency INT,
        MobileNumber VARCHAR(50),
        Code1 VARCHAR(100),
        Code2 VARCHAR(100),
        DuplicateCount INT,
        SuccessStatus VARCHAR(50),
        ModeOfVerification VARCHAR(50),
        EnquiryDate DATETIME,
        Location NVARCHAR(200)
    );

    INSERT INTO #FinalReport
    SELECT 
        @CompanyName AS CompanyName,
        PR.Pro_Name AS ProductName,
        CS.AssignedServices AS ServiceName,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(CP.AssignPoint, 0)
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(P.WornPoint, ISNULL(CP.ConfigPoints, 0)) 
            ELSE 0 
        END AS WornPoint,
        ISNULL(CP.Frequency, 1) AS Frequency,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) < 10 THEN ISNULL(E.MobileNo,'')
            ELSE MC.MobileNo
        END AS MobileNumber,
        E.Received_Code1 AS Code1,
        E.Received_Code2 AS Code2,
        DC.DuplicateCount,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN 'Genuine'
            ELSE 'Duplicate'
        END AS SuccessStatus,
        E.Dial_Mode AS ModeOfVerification,
        E.Enq_Date AS EnquiryDate,
        COALESCE(CONCAT(COALESCE(G.City, ''), CASE WHEN G.City IS NOT NULL AND G.State IS NOT NULL THEN ', ' ELSE '' END, COALESCE(G.State, '')), 
                 CONCAT(COALESCE(MC.City, ''), CASE WHEN MC.City IS NOT NULL AND MC.State IS NOT NULL THEN ', ' ELSE '' END, COALESCE(MC.State, ''))) AS Location
    FROM (
        SELECT *,
               CASE 
                   WHEN Is_Success = 1 
                   THEN ROW_NUMBER() OVER (PARTITION BY Received_Code1, Received_Code2, Is_Success ORDER BY Enq_Date)
                   ELSE 1
               END AS rn
        FROM #Enq
    ) E
    INNER JOIN #DuplicateCodes DC ON DC.Received_Code1 = E.Received_Code1 AND DC.Received_Code2 = E.Received_Code2
    LEFT JOIN M_Consumer MC ON MC.MobileNo = E.MobileNo AND MC.IsDelete = '0'
    LEFT JOIN #Geo G ON G.Code1 = E.Received_Code1 AND G.Code2 = E.Received_Code2 AND G.MobileNo = E.MobileNo
    LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid
    LEFT JOIN #MCode MCd ON MCd.M_Codeid = E.M_Codeid
    LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
    LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid
    LEFT JOIN #CodeServices CS ON CS.M_Codeid = E.M_Codeid;

    ---------------------------------------------------------
    -- FILTER AND SORT
    ---------------------------------------------------------
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY EnquiryDate DESC) AS RN
    INTO #PagedReport
    FROM #FinalReport
    WHERE (
        @Search IS NULL
        OR LTRIM(RTRIM(@Search)) = ''
        OR MobileNumber LIKE '%' + @Search + '%'
        OR Code1 LIKE '%' + @Search + '%'
        OR Code2 LIKE '%' + @Search + '%'
        OR ProductName LIKE '%' + @Search + '%'
    );

    ---------------------------------------------------------
    -- PAGINATION AND OUTPUT
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT 
            CompanyName, ProductName, ServiceName AS [Service name], AssignPoint, WornPoint, Frequency,
            MobileNumber, Code1, Code2, DuplicateCount, SuccessStatus, ModeOfVerification, EnquiryDate, Location
        FROM #PagedReport
        ORDER BY RN;
    END
    ELSE
    BEGIN
        SELECT 
            CompanyName, ProductName, ServiceName AS [Service name], AssignPoint, WornPoint, Frequency,
            MobileNumber, Code1, Code2, DuplicateCount, SuccessStatus, ModeOfVerification, EnquiryDate, Location
        FROM #PagedReport
        WHERE RN BETWEEN @Offset + 1 AND @Offset + @Limit
        ORDER BY RN;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #PagedReport;
    END
END
GO
