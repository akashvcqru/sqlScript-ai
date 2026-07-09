USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-09
-- Description: Retrieves verification scans and redemptions timeline for consumers who have a negative
--              point/cash balance under a specific company, sorted from highest negative balance to lowest.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetNegativeBalanceVerificationReport_AI]
(
    @Comp_Id         NVARCHAR(50),
    @datePreset      NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, ALL
    @fromDate        NVARCHAR(30) = NULL,
    @toDate          NVARCHAR(30) = NULL,
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL,
    @Search          NVARCHAR(30) = NULL,
    @MobileNumber    NVARCHAR(30) = NULL
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
    FROM Comp_Reg 
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @CompanyName NVARCHAR(150);
    SELECT @CompanyName = ISNULL(Comp_Name, '') 
    FROM Comp_Reg 
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    DECLARE @Preset NVARCHAR(20) = UPPER(ISNULL(@datePreset, ''));
    IF (@Preset = '') SET @Preset = 'LAST7DAYS';

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
    DROP TABLE IF EXISTS #ActiveConsumerIds, #ActiveConsumerMCodes, #FilteredBMC, #Users, #Benefit, #Referrals, #Claims, #UPI, #BPoints, #Balances, #Enq, #Codes, #MCode, #Pro, #Geo, #Points, #ScanReferrals, #CodeConfigPoints, #RawScans, #Redemptions, #CodeServices, #CombinedTimeline, #PagedTimeline;

    ---------------------------------------------------------
    -- IDENTIFY ALL REGISTERED CONSUMERS
    ---------------------------------------------------------
    -- Gather active consumers for this company
    SELECT DISTINCT M_ConsumerId
    INTO #ActiveConsumerIds
    FROM (
        SELECT M_Consumerid FROM dbo.BLoyaltyPointsEarned WITH (NOLOCK) WHERE compid = @Comp_Id AND M_Consumerid IS NOT NULL
        UNION
        SELECT MC.M_ConsumerId 
        FROM dbo.ClaimDetails CD WITH (NOLOCK)
        INNER JOIN dbo.M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = CD.Mobileno AND MC.IsDelete = 0
        WHERE CD.Comp_id = @Comp_Id
        UNION
        SELECT CAST(M_Consumerid AS INT) 
        FROM dbo.tblUPITransactionDetails WITH (NOLOCK) 
        WHERE Comp_Id = @Comp_Id AND ISNUMERIC(M_Consumerid) = 1
        UNION
        SELECT RedeemBy FROM dbo.BPointsTransaction WITH (NOLOCK) WHERE companyid = @Comp_Id AND RedeemBy IS NOT NULL
    ) AS ActiveUsers;

    CREATE CLUSTERED INDEX IX_ActiveConsumerIds ON #ActiveConsumerIds(M_ConsumerId);

    SELECT DISTINCT 
        MC.M_ConsumerId, 
        REPLACE(MC.MobileNo, '+', '') AS MobileNo,
        MC.City,
        MC.State
    INTO #Users
    FROM dbo.M_Consumer MC WITH (NOLOCK)
    INNER JOIN #ActiveConsumerIds A ON A.M_ConsumerId = MC.M_ConsumerId
    WHERE MC.IsDelete = 0;

    CREATE CLUSTERED INDEX IX_Users_ConsumerId ON #Users(M_ConsumerId);
    CREATE INDEX IX_Users_MobileNo ON #Users(MobileNo);

    ---------------------------------------------------------
    -- CALCULATE EARNED BENEFITS (SCAN POINTS)
    ---------------------------------------------------------
    CREATE TABLE #Benefit (MobileNo NVARCHAR(50) PRIMARY KEY, ScanPoints DECIMAL(18,2));

    INSERT INTO #Benefit (MobileNo, ScanPoints)
    SELECT 
        U.MobileNo,
        SUM(ISNULL(BL.Points, 0)) AS ScanPoints
    FROM #Users U
    INNER JOIN dbo.BLoyaltyPointsEarned BL WITH (NOLOCK) ON BL.M_Consumerid = U.M_ConsumerId
    WHERE BL.compid = @Comp_Id
      AND (BL.ServiceName IS NULL OR LOWER(BL.ServiceName) NOT IN ('refral', 'referral'))
    GROUP BY U.MobileNo;

    ---------------------------------------------------------
    -- CALCULATE REFERRAL EARNINGS
    ---------------------------------------------------------
    SELECT 
        U.MobileNo,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralAmount
    INTO #Referrals
    FROM #Users U
    INNER JOIN dbo.BLoyaltyPointsEarned BL WITH (NOLOCK) ON BL.M_Consumerid = U.M_ConsumerId
    WHERE BL.compid = @Comp_Id
      AND LOWER(BL.ServiceName) IN ('refral', 'referral')
    GROUP BY U.MobileNo;

    ---------------------------------------------------------
    -- CALCULATE REDEEMED REDEMPTIONS (CLAIMS)
    ---------------------------------------------------------
    SELECT
        CD.Mobileno AS MobileNo,
        SUM(ISNULL(CD.Amount, 0)) AS ClaimsPoints,
        SUM(ISNULL(CD.tdsAmount, 0)) AS TDSAmount
    INTO #Claims
    FROM dbo.ClaimDetails CD WITH (NOLOCK)
    WHERE CD.Comp_id = @Comp_Id
      AND CD.Isapproved = 1
    GROUP BY CD.Mobileno;

    ---------------------------------------------------------
    -- CALCULATE UPI PAYOUTS
    ---------------------------------------------------------
    SELECT
        U.MobileNo,
        SUM(ISNULL(UT.Amount, 0)) AS UPIAmount
    INTO #UPI
    FROM #Users U
    INNER JOIN dbo.tblUPITransactionDetails UT WITH (NOLOCK) ON UT.M_Consumerid = CAST(U.M_ConsumerId AS VARCHAR(50))
    WHERE UT.Comp_Id = @Comp_Id
      AND UT.Status = 'Success'
      AND LEN(ISNULL(UT.Code1, '')) > 1
      AND LEN(ISNULL(UT.Code2, '')) > 6
    GROUP BY U.MobileNo;

    ---------------------------------------------------------
    -- CALCULATE BPOINTS TRANSACTION REDEMPTIONS
    ---------------------------------------------------------
    SELECT
        U.MobileNo,
        SUM(ISNULL(BP.RedeemPoints, 0)) AS BPointsAmount
    INTO #BPoints
    FROM #Users U
    INNER JOIN dbo.BPointsTransaction BP WITH (NOLOCK) ON BP.RedeemBy = U.M_ConsumerId
    WHERE BP.companyid = @Comp_Id
      AND bpstatus IN ('Accepted', 'SUCCESS')
    GROUP BY U.MobileNo;

    ---------------------------------------------------------
    -- COMPUTE LIFETIME BALANCES & FIND NEGATIVE BALANCE USERS
    ---------------------------------------------------------
    SELECT
        U.MobileNo,
        (ISNULL(B.ScanPoints, 0) + ISNULL(R.ReferralAmount, 0)) - (ISNULL(C.ClaimsPoints, 0) + ISNULL(C.TDSAmount, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsAmount, 0)) AS FinalBalanceAmount
    INTO #Balances
    FROM #Users U
    LEFT JOIN #Benefit B ON B.MobileNo = U.MobileNo
    LEFT JOIN #Referrals R ON R.MobileNo = U.MobileNo
    LEFT JOIN #Claims C ON C.MobileNo = U.MobileNo
    LEFT JOIN #UPI UPI ON UPI.MobileNo = U.MobileNo
    LEFT JOIN #BPoints BP ON BP.MobileNo = U.MobileNo
    WHERE ((ISNULL(B.ScanPoints, 0) + ISNULL(R.ReferralAmount, 0)) - (ISNULL(C.ClaimsPoints, 0) + ISNULL(C.TDSAmount, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsAmount, 0))) < 0;

    CREATE CLUSTERED INDEX IX_Balances_MobileNo ON #Balances(MobileNo);

    ----------------------------------------------------
    -- ENQUIRIES (CodeCheck Scans for Negative Users)
    ----------------------------------------------------
    SELECT 
        Received_Code1,
        Received_Code2,
        Enq_Date,
        Dial_Mode,
        Is_Success,
        PE.MobileNo,
        Latitude,
        Longitude,
        M.Row_ID AS M_Codeid,
        M.Series_Order,
        M.Series_Serial
    INTO #Enq
    FROM Pro_Enq PE
    INNER JOIN #Balances BAL ON BAL.MobileNo = REPLACE(PE.MobileNo, '+', '')
    INNER JOIN M_code M 
        ON Received_Code1 = CAST(code1 AS VARCHAR(50))
       AND Received_Code2 = CAST(Code2 AS VARCHAR(50))
    INNER JOIN Pro_Reg PR
        ON PR.Pro_ID = M.Pro_ID
    WHERE PR.Comp_ID = @Comp_Id
      AND Enq_Date >= @StartDate
      AND Enq_Date <  @EndDate;

    CREATE INDEX IX_Enq_Code   ON #Enq(Received_Code1, Received_Code2);
    CREATE INDEX IX_Enq_Mobile ON #Enq(MobileNo);

    ----------------------------------------------------
    -- UNIQUE CODES
    ----------------------------------------------------
    SELECT DISTINCT 
        Received_Code1,
        Received_Code2
    INTO #Codes
    FROM #Enq;

    CREATE INDEX IX_Codes ON #Codes(Received_Code1, Received_Code2);

    ----------------------------------------------------
    -- MCODES
    ----------------------------------------------------
    SELECT 
        MCd.Code1,
        MCd.Code2,
        MCd.Pro_ID,
        MCd.Series_Order,
        MCd.Series_Serial,
        MCd.Row_ID AS M_Codeid
    INTO #MCode
    FROM M_Code MCd
    INNER JOIN #Codes C
        ON MCd.Code1 = C.Received_Code1
       AND MCd.Code2 = C.Received_Code2;

    CREATE INDEX IX_MCode ON #MCode(Code1, Code2);

    ----------------------------------------------------
    -- PRODUCTS
    ----------------------------------------------------
    SELECT 
        Pro_ID,
        Pro_Name
    INTO #Pro
    FROM Pro_Reg
    WHERE Comp_ID = @Comp_Id;

    CREATE INDEX IX_Pro ON #Pro(Pro_ID);

    ----------------------------------------------------
    -- GEO
    ----------------------------------------------------
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
        FROM GeoLocationData G
        INNER JOIN #Codes C
            ON G.Code1 = C.Received_Code1
           AND G.Code2 = C.Received_Code2
    ) X
    WHERE rn = 1;

    CREATE INDEX IX_Geo ON #Geo(Code1, Code2, MobileNo);

    ----------------------------------------------------
    -- POINTS (REFACTORED - ID BASED)
    ----------------------------------------------------
    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation 
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;
 
    -- 1. Gather active consumer MCode IDs for this company
    SELECT M_Consumer_MCodeid, M_Codeid
    INTO #ActiveConsumerMCodes
    FROM M_Consumer_M_Code WITH (NOLOCK)
    WHERE compid = @Comp_Id;

    CREATE CLUSTERED INDEX IX_ActiveConsumerMCodes ON #ActiveConsumerMCodes(M_Consumer_MCodeid);
    CREATE INDEX IX_ActiveConsumerMCodes_Code ON #ActiveConsumerMCodes(M_Codeid);

    -- 2. Filter BuiltLoyaltyMCodeCheck to only those relevant to this company
    SELECT 
        BMC.Pkid, 
        BMC.M_Consumer_MCOdeid,
        ROW_NUMBER() OVER (PARTITION BY BMC.M_Consumer_MCOdeid ORDER BY BMC.Createdate ASC) as rn
    INTO #FilteredBMC
    FROM BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK)
    INNER JOIN #ActiveConsumerMCodes AMC ON BMC.M_Consumer_MCOdeid = AMC.M_Consumer_MCodeid;

    CREATE CLUSTERED INDEX IX_FilteredBMC_Pkid ON #FilteredBMC(Pkid);

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
    INNER JOIN #FilteredBMC BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
    INNER JOIN #ActiveConsumerMCodes MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
    LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON BL.SST_id = sst.SST_Id
    LEFT JOIN M_ServiceSubscription ss WITH (NOLOCK) ON sst.Subscribe_Id = ss.Subscribe_Id
    WHERE BL.compid = @Comp_Id OR (BL.compid IS NULL AND PR.Comp_ID = @Comp_Id)
    GROUP BY MC.M_Codeid;

    CREATE INDEX IX_Points_MCodeid ON #Points(M_Codeid);

    ----------------------------------------------------
    -- REFERRAL POINTS
    ----------------------------------------------------
    SELECT 
        CAST(C.Code1 AS VARCHAR(50)) AS Code1, 
        CAST(C.Code2 AS VARCHAR(50)) AS Code2, 
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralPoints
    INTO #ScanReferrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    LEFT JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    LEFT JOIN BReferralMCodeCheck BRC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BRC.BReferralMCodeCheckid
    INNER JOIN M_Consumer_M_Code MC ON MC.M_Consumer_MCodeid = COALESCE(BMC.M_Consumer_MCOdeid, BRC.M_Consumer_MCOdeid)
    INNER JOIN M_Code C ON MC.M_Codeid = C.Row_ID
    WHERE (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND (
          (@Comp_Id IN ('Comp-1567','Comp-1650') AND MC.compid IN ('Comp-1567','Comp-1650'))
          OR
          (@Comp_Id NOT IN ('Comp-1567','Comp-1650') AND MC.compid = @Comp_Id)
      )
    GROUP BY CAST(C.Code1 AS VARCHAR(50)), CAST(C.Code2 AS VARCHAR(50));

    CREATE INDEX IX_ScanReferrals ON #ScanReferrals(Code1, Code2);

    ----------------------------------------------------
    -- CODE CONFIG POINTS (PRECISE BY SERIES RANGE)
    ----------------------------------------------------
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
            Service_ID,
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
        AssignPoint,
        Service_ID
    INTO #CodeConfigPoints
    FROM FinalRankedConfig
    WHERE rn_final = 1;

    CREATE INDEX IX_CodeConfigPoints_MCodeid ON #CodeConfigPoints(M_Codeid);

    ----------------------------------------------------
    -- RAW SCANS
    ----------------------------------------------------
    CREATE TABLE #RawScans (
        Comp_Id NVARCHAR(50),
        MobileNo NVARCHAR(50),
        Code1 NVARCHAR(100),
        Code2 NVARCHAR(100),
        EnquiryDate DATETIME,
        ModeOfVerification NVARCHAR(150),
        SuccessStatus NVARCHAR(50),
        Pro_ID NVARCHAR(50),
        ProductName NVARCHAR(200),
        ServiceID NVARCHAR(50),
        Frequency INT,
        Amount DECIMAL(18,2),
        RecordType NVARCHAR(20),
        SortOrder INT,
        AssignPoint DECIMAL(18,2),
        WornPoint DECIMAL(18,2),
        State NVARCHAR(100),
        City NVARCHAR(100)
    );

    INSERT INTO #RawScans (Comp_Id, MobileNo, Code1, Code2, EnquiryDate, ModeOfVerification, SuccessStatus, Pro_ID, ProductName, ServiceID, Frequency, Amount, RecordType, SortOrder, AssignPoint, WornPoint, State, City)
    SELECT
        @Comp_Id AS Comp_Id,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) < 10 THEN ISNULL(E.MobileNo,'')
            ELSE MC.MobileNo
        END AS MobileNo,
        E.Received_Code1 AS Code1,
        E.Received_Code2 AS Code2,
        E.Enq_Date AS EnquiryDate,
        E.Dial_Mode AS ModeOfVerification,
        'Verified' AS SuccessStatus,
        MCd.Pro_ID,
        PR.Pro_Name AS ProductName,
        CP.Service_ID AS ServiceID,
        ISNULL(CP.Frequency, 1) AS Frequency,
        ISNULL(P.Points, ISNULL(CP.ConfigPoints, 0)) AS Amount,
        'Scan' AS RecordType,
        1 AS SortOrder,
        ISNULL(CP.AssignPoint, 0) AS AssignPoint,
        ISNULL(P.WornPoint, ISNULL(CP.ConfigPoints, 0)) AS WornPoint,
        G.State,
        G.City
    FROM
    (
        SELECT *,
               CASE 
                   WHEN Is_Success = 1 
                   THEN ROW_NUMBER() OVER (PARTITION BY Received_Code1, Received_Code2, Is_Success ORDER BY Enq_Date)
                   ELSE 1
               END AS rn
        FROM #Enq
    ) E
    LEFT JOIN dbo.M_Consumer MC ON MC.MobileNo = E.MobileNo AND MC.IsDelete = 0
    LEFT JOIN #Geo G ON G.Code1 = E.Received_Code1 AND G.Code2 = E.Received_Code2 AND G.MobileNo = E.MobileNo
    LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid
    LEFT JOIN #MCode MCd ON MCd.M_Codeid = E.M_Codeid
    LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
    LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid
    LEFT JOIN #ScanReferrals R ON R.Code1 = E.Received_Code1 AND R.Code2 = E.Received_Code2
    WHERE E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1);

    ----------------------------------------------------
    -- REDEMPTIONS, CLAIMS, UPI, BPOINTS, TDS, REFERRALS
    ----------------------------------------------------
    CREATE TABLE #Redemptions (
        Comp_Id NVARCHAR(50),
        MobileNo NVARCHAR(50),
        Code1 NVARCHAR(100),
        Code2 NVARCHAR(100),
        EnquiryDate DATETIME,
        ModeOfVerification NVARCHAR(150),
        SuccessStatus NVARCHAR(50),
        Pro_ID NVARCHAR(50),
        ProductName NVARCHAR(200),
        ServiceID NVARCHAR(50),
        Frequency INT,
        Amount DECIMAL(18,2),
        RecordType NVARCHAR(20),
        SortOrder INT,
        AssignPoint DECIMAL(18,2),
        WornPoint DECIMAL(18,2),
        State NVARCHAR(100),
        City NVARCHAR(100)
    );

    -- 1. Referral Reward
    INSERT INTO #Redemptions (Comp_Id, MobileNo, Code1, Code2, EnquiryDate, ModeOfVerification, SuccessStatus, Pro_ID, ProductName, ServiceID, Frequency, Amount, RecordType, SortOrder, AssignPoint, WornPoint, State, City)
    SELECT
        BL.compid AS Comp_Id,
        REPLACE(MC.MobileNo, '+', '') AS MobileNo,
        NULL AS Code1,
        NULL AS Code2,
        BL.UpdateDate AS EnquiryDate,
        'Referral Reward' AS ModeOfVerification,
        'Earned' AS SuccessStatus,
        NULL AS Pro_ID,
        'Referral Bonus' AS ProductName,
        NULL AS ServiceID,
        NULL AS Frequency,
        CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS Amount,
        'Referral' AS RecordType,
        2 AS SortOrder,
        CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS AssignPoint,
        CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS WornPoint,
        MC.State,
        MC.City
    FROM dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN dbo.M_Consumer MC WITH (NOLOCK) ON MC.M_ConsumerId = BL.M_Consumerid
    INNER JOIN #Balances BAL ON BAL.MobileNo = REPLACE(MC.MobileNo, '+', '')
    WHERE BL.compid = @Comp_Id
      AND MC.IsDelete = 0
      AND LOWER(BL.ServiceName) IN ('refral', 'referral')
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate < @EndDate;

    -- 2. Claim Payout (Claims)
    INSERT INTO #Redemptions (Comp_Id, MobileNo, Code1, Code2, EnquiryDate, ModeOfVerification, SuccessStatus, Pro_ID, ProductName, ServiceID, Frequency, Amount, RecordType, SortOrder, AssignPoint, WornPoint, State, City)
    SELECT
        CD.Comp_id,
        CD.Mobileno AS MobileNo,
        NULL AS Code1,
        NULL AS Code2,
        CD.action_date AS EnquiryDate,
        'Claim Payout' AS ModeOfVerification,
        'Approved' AS SuccessStatus,
        NULL AS Pro_ID,
        NULL AS ProductName,
        CD.Service_ID AS ServiceID,
        NULL AS Frequency,
        -CD.Amount AS Amount,
        'Redemption' AS RecordType,
        3 AS SortOrder,
        -CD.Amount AS AssignPoint,
        -CD.Amount AS WornPoint,
        MC.State,
        MC.City
    FROM dbo.ClaimDetails CD WITH (NOLOCK)
    LEFT JOIN dbo.M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = CD.Mobileno AND MC.IsDelete = 0
    INNER JOIN #Balances BAL ON BAL.MobileNo = CD.Mobileno
    WHERE CD.Comp_id = @Comp_Id
      AND CD.Isapproved = 1
      AND CD.action_date >= @StartDate
      AND CD.action_date < @EndDate;

    -- 3. UPI Payout
    INSERT INTO #Redemptions (Comp_Id, MobileNo, Code1, Code2, EnquiryDate, ModeOfVerification, SuccessStatus, Pro_ID, ProductName, ServiceID, Frequency, Amount, RecordType, SortOrder, AssignPoint, WornPoint, State, City)
    SELECT
        UT.Comp_Id,
        REPLACE(MC.MobileNo, '+', '') AS MobileNo,
        NULL AS Code1,
        NULL AS Code2,
        UT.ReqDate AS EnquiryDate,
        'UPI Payout' AS ModeOfVerification,
        'Success' AS SuccessStatus,
        NULL AS Pro_ID,
        NULL AS ProductName,
        NULL AS ServiceID,
        NULL AS Frequency,
        -UT.Amount AS Amount,
        'Redemption' AS RecordType,
        3 AS SortOrder,
        -UT.Amount AS AssignPoint,
        -UT.Amount AS WornPoint,
        MC.State,
        MC.City
    FROM dbo.tblUPITransactionDetails UT WITH (NOLOCK)
    INNER JOIN dbo.M_Consumer MC WITH (NOLOCK) ON CAST(MC.M_ConsumerId AS VARCHAR(50)) = UT.M_Consumerid
    INNER JOIN #Balances BAL ON BAL.MobileNo = REPLACE(MC.MobileNo, '+', '')
    WHERE UT.Comp_Id = @Comp_Id
      AND UT.Status = 'Success'
      AND MC.IsDelete = 0
      AND LEN(ISNULL(UT.Code1, '')) > 1
      AND LEN(ISNULL(UT.Code2, '')) > 6
      AND UT.ReqDate >= @StartDate
      AND UT.ReqDate < @EndDate;

    -- 4. BPoints Redeem
    INSERT INTO #Redemptions (Comp_Id, MobileNo, Code1, Code2, EnquiryDate, ModeOfVerification, SuccessStatus, Pro_ID, ProductName, ServiceID, Frequency, Amount, RecordType, SortOrder, AssignPoint, WornPoint, State, City)
    SELECT
        BP.companyid AS Comp_Id,
        REPLACE(MC.MobileNo, '+', '') AS MobileNo,
        NULL AS Code1,
        NULL AS Code2,
        BP.Redeemdate AS EnquiryDate,
        'BPoints Redeem' AS ModeOfVerification,
        BP.bpstatus AS SuccessStatus,
        NULL AS Pro_ID,
        NULL AS ProductName,
        NULL AS ServiceID,
        NULL AS Frequency,
        -BP.RedeemPoints AS Amount,
        'Redemption' AS RecordType,
        3 AS SortOrder,
        -BP.RedeemPoints AS AssignPoint,
        -BP.RedeemPoints AS WornPoint,
        MC.State,
        MC.City
    FROM dbo.BPointsTransaction BP WITH (NOLOCK)
    INNER JOIN dbo.M_Consumer MC WITH (NOLOCK) ON MC.M_ConsumerId = BP.RedeemBy
    INNER JOIN #Balances BAL ON BAL.MobileNo = REPLACE(MC.MobileNo, '+', '')
    WHERE BP.companyid = @Comp_Id
      AND BP.bpstatus IN ('Accepted', 'SUCCESS')
      AND MC.IsDelete = 0
      AND BP.Redeemdate >= @StartDate
      AND BP.Redeemdate < @EndDate;

    -- 5. TDS Deduction
    INSERT INTO #Redemptions (Comp_Id, MobileNo, Code1, Code2, EnquiryDate, ModeOfVerification, SuccessStatus, Pro_ID, ProductName, ServiceID, Frequency, Amount, RecordType, SortOrder, AssignPoint, WornPoint, State, City)
    SELECT
        CD.Comp_id,
        CD.Mobileno AS MobileNo,
        NULL AS Code1,
        NULL AS Code2,
        CD.action_date AS EnquiryDate,
        'TDS Deduction' AS ModeOfVerification,
        'Approved' AS SuccessStatus,
        NULL AS Pro_ID,
        NULL AS ProductName,
        CD.Service_ID AS ServiceID,
        NULL AS Frequency,
        -CD.tdsAmount AS Amount,
        'TDS' AS RecordType,
        4 AS SortOrder,
        -CD.tdsAmount AS AssignPoint,
        -CD.tdsAmount AS WornPoint,
        MC.State,
        MC.City
    FROM dbo.ClaimDetails CD WITH (NOLOCK)
    LEFT JOIN dbo.M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = CD.Mobileno AND MC.IsDelete = 0
    INNER JOIN #Balances BAL ON BAL.MobileNo = CD.Mobileno
    WHERE CD.Comp_id = @Comp_Id
      AND CD.Isapproved = 1
      AND CD.tdsAmount > 0
      AND CD.action_date >= @StartDate
      AND CD.action_date < @EndDate;

    ---------------------------------------------------------
    -- AGGREGATE SERVICES ASSIGNED TO UNIQUE SCANNED CODES
    ---------------------------------------------------------
    SELECT 
        SC.Code1,
        SC.Code2,
        STRING_AGG(CONCAT(S.ServiceName, ' (', SS.Service_ID, ') (1)'), ', ') AS AssignedServices
    INTO #CodeServices
    FROM (
        SELECT DISTINCT Code1, Code2
        FROM #RawScans
        WHERE Code1 IS NOT NULL AND Code2 IS NOT NULL
    ) SC
    INNER JOIN dbo.M_Code M WITH (NOLOCK) 
        ON CAST(M.Code1 AS VARCHAR(50)) = SC.Code1 
       AND CAST(M.Code2 AS VARCHAR(50)) = SC.Code2
    INNER JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
    INNER JOIN dbo.M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
    WHERE SS.IsActive = 1 AND SS.IsDelete = 0
      AND SS.Comp_ID = @Comp_Id
      AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
      AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))
    GROUP BY SC.Code1, SC.Code2;

    CREATE CLUSTERED INDEX IX_CodeServices_Codes ON #CodeServices(Code1, Code2);

    ---------------------------------------------------------
    -- UNION EVERYTHING INTO TIMELINE & FILTER
    ---------------------------------------------------------
    SELECT
        CT_ID = ROW_NUMBER() OVER (ORDER BY CT.MobileNo, CT.EnquiryDate ASC, CT.SortOrder ASC),
        CT.*
    INTO #CombinedTimeline
    FROM (
        SELECT * FROM #RawScans
        UNION ALL
        SELECT * FROM #Redemptions
    ) CT
    WHERE (
        @Search IS NULL OR
        CT.MobileNo LIKE '%' + @Search + '%' OR
        CT.ProductName LIKE '%' + @Search + '%' OR
        CT.Code1 LIKE '%' + @Search + '%' OR
        CT.Code2 LIKE '%' + @Search + '%'
    )
    AND (
        @MobileNumber IS NULL OR
        CT.MobileNo = REPLACE(@MobileNumber, '+', '')
    );

    ---------------------------------------------------------
    -- COMPILE RESULTS & COMPUTE RUNNING BALANCE
    ---------------------------------------------------------
    SELECT
        @CompanyName AS CompanyName,
        CASE WHEN ProductName IS NOT NULL AND Pro_ID IS NOT NULL THEN CONCAT(ProductName, ' (', Pro_ID, ')') ELSE ProductName END AS ProductName,
        CS.AssignedServices AS ServiceName,
        Amount,
        -- Running Balance per user (MobileNo)
        SUM(Amount) OVER (PARTITION BY CT.MobileNo ORDER BY EnquiryDate ASC, SortOrder ASC, CT_ID ASC) AS Balance,
        AssignPoint,
        WornPoint,
        Frequency,
        CT.MobileNo AS MobileNumber,
        CT.Code1,
        CT.Code2,
        SuccessStatus,
        ModeOfVerification,
        EnquiryDate AS EnquiryTransactionDate,
        CONCAT(COALESCE(City, ''), CASE WHEN City IS NOT NULL AND State IS NOT NULL THEN ', ' ELSE '' END, COALESCE(State, '')) AS Location,
        CASE 
            WHEN RecordType = 'Scan' THEN 'VERIFICATION'
            WHEN RecordType = 'Redemption' THEN 'CLAIM'
            WHEN RecordType = 'Referral' THEN 'REFERRAL'
            ELSE UPPER(RecordType)
        END AS TransactionType,
        -- Sort: Enquiry/TransactionDate DESC
        ROW_NUMBER() OVER (ORDER BY EnquiryDate DESC, SortOrder ASC, CT_ID ASC) AS RN
    INTO #PagedTimeline
    FROM #CombinedTimeline CT
    INNER JOIN #Balances BAL ON BAL.MobileNo = CT.MobileNo
    LEFT JOIN #CodeServices CS ON CS.Code1 = CT.Code1 AND CS.Code2 = CT.Code2;

    ---------------------------------------------------------
    -- RETURN PAGINATED RESULTS
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT
            CompanyName, ProductName, ServiceName, Amount, AssignPoint, WornPoint, Frequency,
            MobileNumber, Code1, Code2, SuccessStatus, ModeOfVerification, EnquiryTransactionDate, Location, TransactionType
        FROM #PagedTimeline
        ORDER BY RN;
    END
    ELSE
    BEGIN
        SELECT
            CompanyName, ProductName, ServiceName, Amount, AssignPoint, WornPoint, Frequency,
            MobileNumber, Code1, Code2, SuccessStatus, ModeOfVerification, EnquiryTransactionDate, Location, TransactionType
        FROM #PagedTimeline
        WHERE RN BETWEEN @Offset + 1 AND @Offset + @Limit
        ORDER BY RN;

        ---------------------------------------------------------
        -- META
        ---------------------------------------------------------
        SELECT
            COUNT(*) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #PagedTimeline;
    END
END
GO
