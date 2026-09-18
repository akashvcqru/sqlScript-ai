-- Migration: 20260918_Add_Series_To_SP_BL_GetCodesActivityReport_AI.sql
-- Purpose: Adds Series column to SP_BL_GetCodesActivityReport_AI

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_AI]
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
     @FromDate DATE  = NULL,                -- NEW
    @ToDate DATE  = NULL,                  -- NEW
    @CodeStatusFilter NVARCHAR(20) = NULL,     -- NEW (Verified, Already Scanned, Invalid)
     @StateFilter NVARCHAR(100) = NULL,       -- ✅ NEW
    @DialModeFilter NVARCHAR(50) = NULL,     -- ✅ NEW
    @Page INT = NULL,                        -- ✅ NEW
    @Limit INT = NULL,                      -- ✅ NEW
     @IsExport BIT =NULL,
        @Search nvarchar(30) = null
AS
BEGIN
  SET NOCOUNT ON;

     ----------------------------------------------------
    -- Pagination Defaults
    ----------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ----------------------------------------------------
    -- Date Range (SAFE FOR DATE TYPE)
    ----------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    -- Explicit date range wins
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE    
    BEGIN
        SET @datePreset = UPPER(@datePreset);

        IF (@datePreset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@datePreset = 'WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF (@datePreset = 'ALL' OR @datePreset IS NULL OR LTRIM(RTRIM(@datePreset)) = '' OR @datePreset = 'NULL')
        BEGIN
            SET @StartDate = @CompanyStartDate;
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    -- Safe fallbacks
    IF (@StartDate IS NULL) SET @StartDate = @CompanyStartDate;
    IF (@EndDate   IS NULL) SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));

    ----------------------------------------------------
    -- Multiplier
    ----------------------------------------------------
    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation WITH (NOLOCK)
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;

    ----------------------------------------------------
    -- Clean Search
    ----------------------------------------------------
    IF (@Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR LOWER(LTRIM(RTRIM(@Search))) = 'null')
        SET @Search = NULL;
    ELSE
        SET @Search = LTRIM(RTRIM(@Search));

    DECLARE @SearchMobile NVARCHAR(30) = NULL;
    IF @Search IS NOT NULL
    BEGIN
        DECLARE @CleanDigits NVARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Search, '+', ''), '-', ''), ' ', ''), '(', '');
        SET @CleanDigits = REPLACE(@CleanDigits, ')', '');
        IF @CleanDigits NOT LIKE '%[^0-9]%' AND LEN(@CleanDigits) >= 10
        BEGIN
            SET @SearchMobile = RIGHT(@CleanDigits, 10);
        END
    END

    ----------------------------------------------------
    -- ENQUIRIES
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

    CREATE TABLE #Enq (
        Received_Code1 VARCHAR(50),
        Received_Code2 VARCHAR(50),
        Enq_Date DATETIME,
        Dial_Mode VARCHAR(50),
        Is_Success INT,
        MobileNo VARCHAR(50),
        Latitude VARCHAR(50),
        Longitude VARCHAR(50),
        M_Codeid BIGINT,
        Series_Order BIGINT,
        Series_Serial BIGINT
    );

    IF @Search IS NOT NULL
    BEGIN
        SELECT DISTINCT 
            PE.Received_Code1,
            PE.Received_Code2
        INTO #SearchedCodes
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_code M WITH (NOLOCK) 
            ON PE.Received_Code1 = CAST(M.code1 AS VARCHAR(50))
           AND PE.Received_Code2 = CAST(M.Code2 AS VARCHAR(50))
        INNER JOIN Pro_Reg PR WITH (NOLOCK)
           ON PR.Pro_ID = M.Pro_ID
        WHERE PR.Comp_ID = @Comp_Id
          AND PE.Enq_Date >= @StartDate
          AND PE.Enq_Date <  @EndDate
          AND (@DialModeFilter IS NULL OR PE.Dial_Mode = @DialModeFilter)
          AND (
              PE.MobileNo LIKE '%' + @Search + '%'
              OR (@SearchMobile IS NOT NULL AND PE.MobileNo LIKE '%' + @SearchMobile + '%')
              OR (PE.Received_Code1 + PE.Received_Code2) LIKE '%' + @Search + '%'
              OR (@SearchMobile IS NOT NULL AND (PE.Received_Code1 + PE.Received_Code2) LIKE '%' + @SearchMobile + '%')
          );

        CREATE INDEX IX_SearchedCodes ON #SearchedCodes(Received_Code1, Received_Code2);

        -- Load ALL scan attempts across ALL users for those matched codes to ensure accurate duplicate/first-scan ranking
        INSERT INTO #Enq (Received_Code1, Received_Code2, Enq_Date, Dial_Mode, Is_Success, MobileNo, Latitude, Longitude, M_Codeid, Series_Order, Series_Serial)
        SELECT 
            PE.Received_Code1,
            PE.Received_Code2,
            PE.Enq_Date,
            PE.Dial_Mode,
            PE.Is_Success,
            PE.MobileNo,
            PE.Latitude,
            PE.Longitude,
            M.Row_ID AS M_Codeid,
            M.Series_Order,
            M.Series_Serial
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN #SearchedCodes SC
            ON PE.Received_Code1 = SC.Received_Code1
           AND PE.Received_Code2 = SC.Received_Code2
        INNER JOIN M_code M WITH (NOLOCK) 
            ON PE.Received_Code1 = CAST(M.code1 AS VARCHAR(50))
           AND PE.Received_Code2 = CAST(M.Code2 AS VARCHAR(50))
        INNER JOIN Pro_Reg PR WITH (NOLOCK)
           ON PR.Pro_ID = M.Pro_ID
        WHERE PR.Comp_ID = @Comp_Id
          AND PE.Enq_Date >= @StartDate
          AND PE.Enq_Date <  @EndDate
          AND (@DialModeFilter IS NULL OR PE.Dial_Mode = @DialModeFilter);
    END
    ELSE
    BEGIN
        INSERT INTO #Enq (Received_Code1, Received_Code2, Enq_Date, Dial_Mode, Is_Success, MobileNo, Latitude, Longitude, M_Codeid, Series_Order, Series_Serial)
        SELECT 
            PE.Received_Code1,
            PE.Received_Code2,
            PE.Enq_Date,
            PE.Dial_Mode,
            PE.Is_Success,
            PE.MobileNo,
            PE.Latitude,
            PE.Longitude,
            M.Row_ID AS M_Codeid,
            M.Series_Order,
            M.Series_Serial
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_code M WITH (NOLOCK) 
            ON PE.Received_Code1 = CAST(M.code1 AS VARCHAR(50))
           AND PE.Received_Code2 = CAST(M.Code2 AS VARCHAR(50))
        INNER JOIN Pro_Reg PR WITH (NOLOCK)
           ON PR.Pro_ID = M.Pro_ID
        WHERE PR.Comp_ID = @Comp_Id
          AND PE.Enq_Date >= @StartDate
          AND PE.Enq_Date <  @EndDate
          AND (@DialModeFilter IS NULL OR PE.Dial_Mode = @DialModeFilter);
    END

    CREATE INDEX IX_Enq_Code   ON #Enq(Received_Code1, Received_Code2);
    CREATE INDEX IX_Enq_Mobile ON #Enq(MobileNo);

    ----------------------------------------------------
    -- UNIQUE CODES
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Codes') IS NOT NULL DROP TABLE #Codes;

    SELECT DISTINCT 
        Received_Code1,
        Received_Code2
    INTO #Codes
    FROM #Enq;

    CREATE INDEX IX_Codes ON #Codes(Received_Code1, Received_Code2);

    ----------------------------------------------------
    -- MCODES
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#MCode') IS NOT NULL DROP TABLE #MCode;

    SELECT 
        MCd.Code1,
        MCd.Code2,
        MCd.Pro_ID,
        MCd.Series_Order,
        MCd.Series_Serial,
        MCd.Row_ID AS M_Codeid,
        MCd.LabelRequestId
    INTO #MCode
    FROM M_Code MCd
    INNER JOIN #Codes C
        ON MCd.Code1 = C.Received_Code1
       AND MCd.Code2 = C.Received_Code2;

    CREATE INDEX IX_MCode ON #MCode(Code1, Code2);

    ----------------------------------------------------
    -- UNIQUE LABEL REQUESTS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#UniqueLabelRequests') IS NOT NULL DROP TABLE #UniqueLabelRequests;

    SELECT DISTINCT 
        LabelRequestId
    INTO #UniqueLabelRequests
    FROM #MCode
    WHERE LabelRequestId IS NOT NULL AND LTRIM(RTRIM(LabelRequestId)) <> '';

    CREATE INDEX IX_UniqueLabelRequests ON #UniqueLabelRequests(LabelRequestId);

    ----------------------------------------------------
    -- SOFT CODE GENERATE DETAILS (TEMP SOFT CODE)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#TempSoftCode') IS NOT NULL DROP TABLE #TempSoftCode;

    SELECT 
        SD.TrackingId,
        SD.Comp_id,
        j.UserType,
        j.Point,
        UT.Row_ID AS UserTypeId,
        UT.User_Type AS UserTypeName
    INTO #TempSoftCode 
    FROM tbl_SoftCodegenrate_Details SD WITH (NOLOCK)
    CROSS APPLY OPENJSON(SD.pointsdata)
    WITH (
        UserType NVARCHAR(100) '$.UserType',
        Point NVARCHAR(50) '$.Point'
    ) j
    LEFT JOIN User_Type UT WITH (NOLOCK)
        ON (UT.User_Type = j.UserType OR CAST(UT.Row_ID AS VARCHAR(50)) = j.UserType)
    INNER JOIN #UniqueLabelRequests ULR
        ON SD.TrackingId = ULR.LabelRequestId
    WHERE SD.Comp_id = @Comp_Id;

    CREATE INDEX IX_TempSoftCode_Tracking_UserType ON #TempSoftCode(TrackingId, UserTypeId);

    ----------------------------------------------------
    -- PRODUCTS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Pro') IS NOT NULL DROP TABLE #Pro;

    SELECT DISTINCT 
        PR.Pro_ID,
        PR.Pro_Name
    INTO #Pro
    FROM Pro_Reg PR WITH (NOLOCK)
    INNER JOIN #MCode MC ON PR.Pro_ID = MC.Pro_ID
    WHERE PR.Comp_ID = @Comp_Id;

    CREATE INDEX IX_Pro ON #Pro(Pro_ID);

    ----------------------------------------------------
    -- GEO LOCATION
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Geo') IS NOT NULL DROP TABLE #Geo;

    SELECT 
        Code1,
        Code2,
        MobileNo,
        State,
        City
    INTO #Geo
    FROM
    (
        SELECT 
            Code1,
            Code2,
            Mobile_No AS MobileNo,
            State,
            City,
            ROW_NUMBER() OVER(
                PARTITION BY Code1, Code2, Mobile_No 
                ORDER BY Entry_Date DESC
            ) rn
        FROM [dbo].[Table_CodeDetailsLocation] WITH (NOLOCK)
        WHERE Comp_Id = @Comp_Id
          AND Entry_Date >= @StartDate
          AND Entry_Date <  @EndDate
    ) g
    WHERE rn = 1;

    CREATE INDEX IX_Geo ON #Geo(Code1, Code2, MobileNo);

    ----------------------------------------------------
    -- POINTS EARNED (SCAN ONLY - FILTERED)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT 
        M_Codeid,
        MobileNo,
        ServiceName,
        Points,
        WornPoint,
        ReferralPoints
    INTO #Points
    FROM
    (
        SELECT 
            MCMC.M_Codeid,
            MC.MobileNo,
            ISNULL(MS.ServiceName, ISNULL(NULLIF(BL.ServiceName, ''), 'Scan & Win')) AS ServiceName,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN
                        CASE 
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN
                        CASE 
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS WornPoint,
            0 AS ReferralPoints,
            ROW_NUMBER() OVER(
                PARTITION BY MCMC.M_Codeid, MC.MobileNo 
                ORDER BY BL.UpdateDate DESC
            ) rn
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MCMC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MCMC.M_Consumer_MCodeid
        INNER JOIN #Codes C
            ON MCMC.Code1 = C.Received_Code1
           AND MCMC.Code2 = C.Received_Code2
        INNER JOIN M_Consumer MC WITH (NOLOCK) 
            ON BL.M_Consumerid = MC.M_Consumerid
        LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) 
            ON SST.SST_Id = BL.SST_id
        LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) 
            ON SS.Subscribe_Id = SST.Subscribe_Id
        LEFT JOIN dbo.M_Service MS WITH (NOLOCK) 
            ON MS.Service_ID = SS.Service_ID
        WHERE BL.compid = @Comp_Id
          AND BL.UpdateDate >= @StartDate
          AND BL.UpdateDate <  @EndDate
    ) p
    WHERE rn = 1;

    CREATE INDEX IX_Points ON #Points(M_Codeid, MobileNo);

    ----------------------------------------------------
    -- SCAN REFERRALS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#ScanReferrals') IS NOT NULL DROP TABLE #ScanReferrals;

    SELECT 
        CAST(BL.Code1 AS VARCHAR(50)) AS Code1,
        CAST(BL.Code2 AS VARCHAR(50)) AS Code2,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralPoints
    INTO #ScanReferrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN #Codes C
        ON CAST(BL.Code1 AS VARCHAR(50)) = C.Received_Code1
       AND CAST(BL.Code2 AS VARCHAR(50)) = C.Received_Code2
    WHERE BL.compid = @Comp_Id
      AND (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND BL.Code1 IS NOT NULL
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate <  @EndDate
    GROUP BY BL.Code1, BL.Code2;

    CREATE INDEX IX_ScanReferrals ON #ScanReferrals(Code1, Code2);

    ----------------------------------------------------
    -- CODE CONFIG POINTS & SERVICE NAME FALLBACK
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;

    SELECT 
        M_Codeid,
        ServiceName,
        ConfigPoints,
        AssignPoint,
        TotalFrequency
    INTO #CodeConfigPoints
    FROM
    (
        SELECT 
            MC.M_Codeid,
            MS.ServiceName,
            TRY_CAST(ISNULL(SST.Points, 0) AS DECIMAL(18,2)) AS ConfigPoints,
            TRY_CAST(ISNULL(SST.Points, 0) AS DECIMAL(18,2)) AS AssignPoint,
            ISNULL(SST.Frequency, 1) AS TotalFrequency,
            ROW_NUMBER() OVER(
                PARTITION BY MC.M_Codeid 
                ORDER BY SST.Entry_Date DESC
            ) rn
        FROM #MCode MC
        INNER JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) 
            ON SS.Comp_ID = @Comp_Id
           AND SS.Pro_ID = MC.Pro_ID
           AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
           AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        INNER JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) 
            ON SST.Subscribe_Id = SS.Subscribe_Id
           AND SST.IsActive = 1
        INNER JOIN dbo.M_Service MS WITH (NOLOCK) 
            ON MS.Service_ID = SS.Service_ID
        WHERE SS.IsActive = 1
    ) cp
    WHERE rn = 1;

    -- Fallback for Loyalty Service (Service_ID = 'SRV-1002')
    INSERT INTO #CodeConfigPoints (M_Codeid, ServiceName, ConfigPoints, AssignPoint, TotalFrequency)
    SELECT 
        cp_sub.M_Codeid,
        cp_sub.ServiceName,
        cp_sub.ConfigPoints,
        cp_sub.AssignPoint,
        cp_sub.TotalFrequency
    FROM
    (
        SELECT 
            MC.M_Codeid,
            MS.ServiceName,
            TRY_CAST(ISNULL(SST.Points, 0) AS DECIMAL(18,2)) AS ConfigPoints,
            TRY_CAST(ISNULL(SST.Points, 0) AS DECIMAL(18,2)) AS AssignPoint,
            ISNULL(SST.Frequency, 1) AS TotalFrequency,
            ROW_NUMBER() OVER(
                PARTITION BY MC.M_Codeid 
                ORDER BY SST.Entry_Date DESC
            ) rn
        FROM #MCode MC
        INNER JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) 
            ON SS.Comp_ID = @Comp_Id
           AND SS.Pro_ID = MC.Pro_ID
           AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
           AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        INNER JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) 
            ON SST.Subscribe_Id = SS.Subscribe_Id
           AND SST.IsActive = 1
        INNER JOIN dbo.M_Service MS WITH (NOLOCK) 
            ON MS.Service_ID = SS.Service_ID
        WHERE SS.IsActive = 1
          AND SS.Service_ID = 'SRV-1002'
          AND NOT EXISTS (SELECT 1 FROM #CodeConfigPoints x WHERE x.M_Codeid = MC.M_Codeid)
    ) cp_sub
    WHERE cp_sub.rn = 1;

    CREATE INDEX IX_CodeConfigPoints ON #CodeConfigPoints(M_Codeid);

    ----------------------------------------------------
    -- FINAL AGGREGATE
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalReport') IS NOT NULL DROP TABLE #FinalReport;

    CREATE TABLE #FinalReport (
        UniqueCode VARCHAR(100),
        Series VARCHAR(100),
        Enq_Date DATETIME,
        Dial_Mode VARCHAR(50),
        ConsumerName NVARCHAR(150),
        MobileNo VARCHAR(50),
        State NVARCHAR(100),
        Vrkabel_User_Type NVARCHAR(100),
        City NVARCHAR(100),
        Pro_Name NVARCHAR(200),
        ServiceName NVARCHAR(200),
        Points DECIMAL(18,2),
        Result VARCHAR(50),
        Latitude VARCHAR(50),
        Longitude VARCHAR(50),
        AssignPoint DECIMAL(18,2),
        WornPoint DECIMAL(18,2),
        ReferralPoints DECIMAL(18,2),
        LabelRequestId VARCHAR(50)
    );

    -- 1. Insert scan enquiries
    INSERT INTO #FinalReport (
        UniqueCode, Series, Enq_Date, Dial_Mode, ConsumerName, MobileNo, State, Vrkabel_User_Type, City, Pro_Name, ServiceName,
        Points, Result, Latitude, Longitude, AssignPoint, WornPoint, ReferralPoints, LabelRequestId
    )
    SELECT 
        (E.Received_Code1 + E.Received_Code2) AS UniqueCode,
        CASE 
            WHEN MCd.Series_Order IS NOT NULL AND MCd.Series_Serial IS NOT NULL 
            THEN CONCAT(ISNULL(MCd.Pro_ID, PR.Pro_ID), '-', MCd.Series_Order, '-', MCd.Series_Serial)
            WHEN E.Series_Order IS NOT NULL AND E.Series_Serial IS NOT NULL
            THEN CONCAT(ISNULL(MCd.Pro_ID, PR.Pro_ID), '-', E.Series_Order, '-', E.Series_Serial)
            ELSE '' 
        END AS Series,
        E.Enq_Date,
        E.Dial_Mode,
        MC.ConsumerName,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) >= 10 THEN RIGHT(MC.MobileNo, 10)
            WHEN LEN(ISNULL(E.MobileNo,'')) >= 10 THEN RIGHT(E.MobileNo, 10)
            ELSE ISNULL(MC.MobileNo, ISNULL(E.MobileNo,''))
        END AS MobileNo,
        G.State,cc.Vrkabel_User_Type,
        G.City,
        PR.Pro_Name,
        ISNULL(NULLIF(P.ServiceName, ''), ISNULL(CP.ServiceName, '')) AS ServiceName,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 
                CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(P.Points, 0)
                    WHEN ISNULL(P.Points, 0) > 0 THEN P.Points 
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS Points,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 'Verified'
            WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1)) THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
			E.Latitude,
			E.Longitude,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 
                CASE 
                    WHEN ISNULL(CP.AssignPoint, 0) > 0 THEN CP.AssignPoint
                    WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 
                CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(P.WornPoint, 0)
                    WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint 
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS WornPoint,
        ISNULL(R.ReferralPoints, 0) AS ReferralPoints,
        MCd.LabelRequestId
		FROM
		(
			SELECT *,
				   CASE 
					   WHEN Is_Success = 1 
					   THEN ROW_NUMBER() OVER (PARTITION BY Received_Code1, Received_Code2, Is_Success ORDER BY Enq_Date ASC)
					   ELSE 1
				   END AS rn
			FROM #Enq
		) E
        LEFT JOIN M_Consumer MC ON (MC.MobileNo = E.MobileNo OR (LEN(E.MobileNo) >= 10 AND RIGHT(MC.MobileNo, 10) = RIGHT(E.MobileNo, 10))) AND MC.IsDelete = '0'
        LEFT JOIN tbl_Vendorvisekycstatus cc ON mc.M_Consumerid = cc.M_consumerId AND cc.comp_id = @comp_id
        LEFT JOIN #Geo G ON G.Code1 = E.Received_Code1 AND G.Code2 = E.Received_Code2 AND G.MobileNo = E.MobileNo
        LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid AND (P.MobileNo = E.MobileNo OR '91' + P.MobileNo = E.MobileNo OR P.MobileNo = '91' + E.MobileNo OR (LEN(P.MobileNo) >= 10 AND LEN(E.MobileNo) >= 10 AND RIGHT(P.MobileNo, 10) = RIGHT(E.MobileNo, 10)) OR P.MobileNo IS NULL)
        LEFT JOIN #MCode MCd ON MCd.M_Codeid = E.M_Codeid
        LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
        LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid
        LEFT JOIN #ScanReferrals R ON R.Code1 = E.Received_Code1 AND R.Code2 = E.Received_Code2
        WHERE (cc.comp_id = @comp_id OR cc.comp_id IS NULL) and 
		  (E.Is_Success != 1 OR E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)
          AND (@StateFilter IS NULL OR G.State = @StateFilter);

    -- 2. Insert registration referrals (virtual rows)
    INSERT INTO #FinalReport (
        UniqueCode, Series, Enq_Date, Dial_Mode, ConsumerName, MobileNo, State, Vrkabel_User_Type, City, Pro_Name, ServiceName,
        Points, Result, Latitude, Longitude, AssignPoint, WornPoint, ReferralPoints, LabelRequestId
    )
    SELECT 
        '' AS UniqueCode,
        '' AS Series,
        BL.UpdateDate AS Enq_Date,
        '' AS Dial_Mode,
        MC.ConsumerName,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) >= 10 THEN RIGHT(MC.MobileNo, 10)
            ELSE ISNULL(MC.MobileNo,'')
        END AS MobileNo,
        MC.State,cc.Vrkabel_User_Type,
        MC.City,
        'Referral Bonus' AS Pro_Name,
        ISNULL(BL.ServiceName, 'Referral') AS ServiceName,
        0 AS Points,
        'Referral Point' AS Result,
        '' AS Latitude,
        '' AS Longitude,
        0 AS AssignPoint,
        0 AS WornPoint,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralPoints,
        '' AS LabelRequestId
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    LEFT JOIN tbl_Vendorvisekycstatus cc ON mc.M_Consumerid = cc.M_consumerId AND cc.comp_id = @comp_id
    WHERE (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND BL.compid = @Comp_Id
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate < @EndDate
      AND (@StateFilter IS NULL OR MC.State = @StateFilter)
      AND (
          @Search IS NULL
          OR MC.MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND MC.MobileNo LIKE '%' + @SearchMobile + '%')
          OR MC.ConsumerName LIKE '%' + @Search + '%'
      )
    GROUP BY BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, MC.State, cc.Vrkabel_User_Type, MC.City, BL.UpdateDate, BL.ServiceName;

    -- 3. Insert other/extra earn point entries (Bonus, Repair, KYC, Invoice, Team Scans, etc.)
    INSERT INTO #FinalReport (
        UniqueCode, Series, Enq_Date, Dial_Mode, ConsumerName, MobileNo, State, Vrkabel_User_Type, City, Pro_Name, ServiceName,
        Points, Result, Latitude, Longitude, AssignPoint, WornPoint, ReferralPoints, LabelRequestId
    )
    SELECT 
        ISNULL(CAST(C.Code1 AS VARCHAR(50)) + CAST(C.Code2 AS VARCHAR(50)), '') AS UniqueCode,
        CASE 
            WHEN C.Series_Order IS NOT NULL AND C.Series_Serial IS NOT NULL 
            THEN CONCAT(ISNULL(C.Pro_ID, PR.Pro_ID), '-', C.Series_Order, '-', C.Series_Serial)
            ELSE '' 
        END AS Series,
        BL.UpdateDate AS Enq_Date,
        '' AS Dial_Mode,
        MC.ConsumerName,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) >= 10 THEN RIGHT(MC.MobileNo, 10)
            ELSE ISNULL(MC.MobileNo,'')
        END AS MobileNo,
        MC.State, cc.Vrkabel_User_Type,
        MC.City,
        ISNULL(
            CASE 
                WHEN PR.Pro_Name IS NOT NULL AND LTRIM(RTRIM(PR.Pro_Name)) <> '' THEN PR.Pro_Name
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%repair%' THEN 'Repair Point'
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%cash%' THEN 'Cash Transfer'
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%kyc%' THEN 'KYC Bonus'
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%invoice%' THEN 'Invoice Bonus'
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%bonus%' THEN 'Bonus Point'
                WHEN LTRIM(RTRIM(ISNULL(BL.ServiceName, ''))) <> '' THEN BL.ServiceName + ' Point'
                ELSE 'Bonus Point'
            END, 'Bonus Point'
        ) AS Pro_Name,
        ISNULL(MS.ServiceName, ISNULL(NULLIF(BL.ServiceName, ''), 'Bonus')) AS ServiceName,
        SUM(CAST(
            CASE 
                WHEN @Comp_Id = 'Comp-1669' THEN
                    CASE
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                            CASE 
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                            END
                        WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                        ELSE 0.00
                    END
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS Points,
        CASE 
            WHEN PR.Pro_Name IS NOT NULL AND LTRIM(RTRIM(PR.Pro_Name)) <> '' THEN 'Verified'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%kyc%' THEN 'KYC Point'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%invoice%' THEN 'Invoice Point'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%refral%' OR LOWER(ISNULL(BL.ServiceName, '')) LIKE '%referral%' THEN 'Referral Point'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%repair%' THEN 'Repair Point'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%cash%' THEN 'Cash Transfer'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%bonus%' THEN 'Bonus Point'
            WHEN LTRIM(RTRIM(ISNULL(BL.ServiceName, ''))) <> '' THEN BL.ServiceName + ' Point'
            ELSE 'Bonus Point'
        END AS Result,
        '' AS Latitude,
        '' AS Longitude,
        0 AS AssignPoint,
        SUM(CAST(
            CASE 
                WHEN @Comp_Id = 'Comp-1669' THEN
                    CASE
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                            CASE 
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                            END
                        WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                        ELSE 0.00
                    END
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS WornPoint,
        0 AS ReferralPoints,
        ISNULL(MCd.LabelRequestId, '') AS LabelRequestId
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    LEFT JOIN tbl_Vendorvisekycstatus cc ON mc.M_Consumerid = cc.M_consumerId AND cc.comp_id = @comp_id
    LEFT JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    LEFT JOIN M_Consumer_M_Code MCMC ON BMC.M_Consumer_MCOdeid = MCMC.M_Consumer_MCodeid
    LEFT JOIN M_Code C ON MCMC.M_Codeid = C.Row_ID
    LEFT JOIN #Pro PR ON C.Pro_ID = PR.Pro_ID
    LEFT JOIN #MCode MCd ON MCMC.M_Codeid = MCd.M_Codeid
    LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.SST_Id = BL.SST_id
    LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) ON SS.Subscribe_Id = SST.Subscribe_Id
    LEFT JOIN dbo.M_Service MS WITH (NOLOCK) ON MS.Service_ID = SS.Service_ID
    WHERE BL.compid = @Comp_Id
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND (
          BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          OR NOT EXISTS (
              SELECT 1 FROM #Enq E 
              WHERE E.M_Codeid = MCMC.M_Codeid 
                AND (E.MobileNo = MC.MobileNo OR '91' + E.MobileNo = MC.MobileNo OR E.MobileNo = '91' + MC.MobileNo)
          )
      )
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate < @EndDate
      AND (@StateFilter IS NULL OR MC.State = @StateFilter)
      AND (
          @Search IS NULL
          OR MC.MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND MC.MobileNo LIKE '%' + @SearchMobile + '%')
          OR MC.ConsumerName LIKE '%' + @Search + '%'
      )
    GROUP BY BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, MC.State, cc.Vrkabel_User_Type, MC.City, BL.UpdateDate, MS.ServiceName, BL.ServiceName, C.Code1, C.Code2, PR.Pro_Name, MCd.LabelRequestId, C.Pro_ID, PR.Pro_ID, C.Series_Order, C.Series_Serial;

    ----------------------------------------------------
    -- RESULT SET 1
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            FR.UniqueCode,
            FR.Series,
            FR.Enq_Date,
            FR.Dial_Mode,
            FR.ConsumerName,
            FR.MobileNo,
            FR.State,
            FR.City,
            FR.Pro_Name,
            FR.ServiceName,
            FR.Points,
            FR.Result,
			FR.Latitude,
			FR.Longitude,
            CASE WHEN tsc.Point IS NULL THEN FR.AssignPoint ELSE ISNULL(TRY_CAST(tsc.Point AS DECIMAL(18,2)), FR.AssignPoint) END AS AssignPoint,
            FR.WornPoint,
            FR.ReferralPoints 
		FROM #FinalReport FR left join #TempSoftCode tsc on FR.LabelRequestId=tsc.TrackingId and fr.Vrkabel_User_Type = tsc.UserTypeId
        WHERE (
            @CodeStatusFilter IS NULL OR
            FR.Result = @CodeStatusFilter OR
            (@CodeStatusFilter = 'Already Verified' AND FR.Result = 'Already Scanned')
        )
        AND (
			 @Search IS NULL
			 OR LTRIM(RTRIM(@Search)) = ''
			 OR FR.MobileNo LIKE '%' + @Search + '%'
			 OR (@SearchMobile IS NOT NULL AND FR.MobileNo LIKE '%' + @SearchMobile + '%')
			 OR FR.UniqueCode LIKE '%' + @Search + '%'
			 OR (@SearchMobile IS NOT NULL AND FR.UniqueCode LIKE '%' + @SearchMobile + '%')
             OR FR.ServiceName LIKE '%' + @Search + '%'
             OR FR.Series LIKE '%' + @Search + '%'
        )
        ORDER BY FR.Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT 
            FR.UniqueCode,
            FR.Series,
            FR.Enq_Date,
            FR.Dial_Mode,
            FR.ConsumerName,
            FR.MobileNo,
            FR.State,
            FR.City,
            FR.Pro_Name,
            FR.ServiceName,
            FR.Points,
            FR.Result,
			FR.Latitude,
			FR.Longitude,
            CASE WHEN tsc.Point IS NULL THEN FR.AssignPoint ELSE ISNULL(TRY_CAST(tsc.Point AS DECIMAL(18,2)), FR.AssignPoint) END AS AssignPoint,
            FR.WornPoint,
            FR.ReferralPoints 
        FROM #FinalReport FR left join #TempSoftCode tsc on FR.LabelRequestId=tsc.TrackingId and fr.Vrkabel_User_Type = tsc.UserTypeId
        WHERE (
            @CodeStatusFilter IS NULL OR
            FR.Result = @CodeStatusFilter OR
            (@CodeStatusFilter = 'Already Verified' AND FR.Result = 'Already Scanned')
        )
        AND (
			 @Search IS NULL
			 OR LTRIM(RTRIM(@Search)) = ''
			 OR FR.MobileNo LIKE '%' + @Search + '%'
			 OR (@SearchMobile IS NOT NULL AND FR.MobileNo LIKE '%' + @SearchMobile + '%')
			 OR FR.UniqueCode LIKE '%' + @Search + '%'
			 OR (@SearchMobile IS NOT NULL AND FR.UniqueCode LIKE '%' + @SearchMobile + '%')
             OR FR.ServiceName LIKE '%' + @Search + '%'
             OR FR.Series LIKE '%' + @Search + '%'
        )
        ORDER BY FR.Enq_Date DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        ----------------------------------------------------
        -- META
        ----------------------------------------------------
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalReport FR left join #TempSoftCode tsc on FR.LabelRequestId=tsc.TrackingId and fr.Vrkabel_User_Type = tsc.UserTypeId
        WHERE (
            @CodeStatusFilter IS NULL OR
            FR.Result = @CodeStatusFilter OR
            (@CodeStatusFilter = 'Already Verified' AND FR.Result = 'Already Scanned')
        )
        AND (
			 @Search IS NULL
			 OR LTRIM(RTRIM(@Search)) = ''
			 OR FR.MobileNo LIKE '%' + @Search + '%'
			 OR (@SearchMobile IS NOT NULL AND FR.MobileNo LIKE '%' + @SearchMobile + '%')
			 OR FR.UniqueCode LIKE '%' + @Search + '%'
			 OR (@SearchMobile IS NOT NULL AND FR.UniqueCode LIKE '%' + @SearchMobile + '%')
             OR FR.ServiceName LIKE '%' + @Search + '%'
             OR FR.Series LIKE '%' + @Search + '%'
        );
    END
END
GO
