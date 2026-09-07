USE [Vcqru]
GO

/****** 1. Fix SP_BL_GetCodesActivityReport_AI (Support 10-digit and 12-digit mobile search with country code) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_AI]
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate DATE  = NULL,                -- NEW
    @ToDate DATE  = NULL,                  -- NEW
    @CodeStatusFilter NVARCHAR(20) = NULL,     -- NEW (Verified, Already Scanned, Invalid)
    @StateFilter NVARCHAR(100) = NULL,       -- âœ… NEW
    @DialModeFilter NVARCHAR(50) = NULL,     -- âœ… NEW
    @Page INT = NULL,                        -- âœ… NEW
    @Limit INT = NULL,                      -- âœ… NEW
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
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            -- Default fallback (ALL)
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    -- Normalize filters early
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' OR @CodeStatusFilter = 'null' SET @CodeStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'null' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' OR @DialModeFilter = 'null' SET @DialModeFilter = NULL;

    DECLARE @SearchMobile NVARCHAR(30) = NULL;
    IF @Search IS NOT NULL
    BEGIN
        DECLARE @CleanSearchDigits NVARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Search, '+', ''), '-', ''), ' ', ''), '(', '');
        SET @CleanSearchDigits = REPLACE(@CleanSearchDigits, ')', '');
        IF @CleanSearchDigits NOT LIKE '%[^0-9]%' AND LEN(@CleanSearchDigits) >= 10
        BEGIN
            SET @SearchMobile = RIGHT(@CleanSearchDigits, 10);
        END
    END

    ----------------------------------------------------
    -- ENQUIRIES (EARLY SEARCH SHRINKING)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

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
    FROM Pro_Enq
	INNER JOIN M_code M 
	    ON Received_Code1 = CAST(code1 AS VARCHAR(50))
	 AND Received_Code2 = CAST(Code2 AS VARCHAR(50))
    INNER JOIN Pro_Reg PR
       ON PR.Pro_ID = M.Pro_ID
    WHERE PR.Comp_ID = @Comp_Id
      AND Enq_Date >= @StartDate
      AND Enq_Date <  @EndDate
      AND (@DialModeFilter IS NULL OR Dial_Mode = @DialModeFilter)
      AND (
          @Search IS NULL 
          OR MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND MobileNo LIKE '%' + @SearchMobile + '%')
          OR (Received_Code1 + Received_Code2) LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND (Received_Code1 + Received_Code2) LIKE '%' + @SearchMobile + '%')
      );

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
       AND (UT.Comp_ID = SD.Comp_id OR UT.Comp_ID = @Comp_Id)
       AND ISNULL(UT.IsDeleted, 0) = 0
    WHERE SD.TrackingId IN (SELECT LabelRequestId FROM #UniqueLabelRequests)
      AND SD.pointsdata IS NOT NULL 
      AND ISJSON(SD.pointsdata) = 1;

    CREATE INDEX IX_TempSoftCode ON #TempSoftCode(TrackingId, UserType);

    ----------------------------------------------------
    -- PRODUCTS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Pro') IS NOT NULL DROP TABLE #Pro;

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
    IF OBJECT_ID('tempdb..#Geo') IS NOT NULL DROP TABLE #Geo;

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
    -- POINTS (REFACTORED - ALIGNED WITH BENEFICIARIES REPORT)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation 
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;
 
    SELECT
        M_Codeid,
        MobileNo,
        CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN SUM(Points)
            ELSE MAX(Points)
        END AS Points,
        CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN SUM(WornPoint)
            ELSE MAX(WornPoint)
        END AS WornPoint
    INTO #Points
    FROM (
        SELECT
            MC.M_Codeid,
            Cons.MobileNo,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @Comp_Id = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @Comp_Id = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN #MCode M WITH (NOLOCK)
            ON MC.M_Codeid = M.M_Codeid
        LEFT JOIN M_Consumer Cons WITH (NOLOCK)
            ON BL.M_Consumerid = Cons.M_Consumerid
        WHERE BL.compid = @Comp_Id
          AND (@Comp_Id <> 'Comp-1669' OR LOWER(ISNULL(BL.ServiceName, '')) IN ('buildloyalty', 'srv1001'))

        UNION ALL

        SELECT
            MC.M_Codeid,
            Cons.MobileNo,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @Comp_Id = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @Comp_Id = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN #MCode M WITH (NOLOCK) 
            ON MC.M_Codeid = M.M_Codeid
        INNER JOIN Pro_Reg PR WITH (NOLOCK) 
            ON M.Pro_ID = PR.Pro_ID
        LEFT JOIN M_Consumer Cons WITH (NOLOCK)
            ON BL.M_Consumerid = Cons.M_Consumerid
        WHERE BL.compid IS NULL
          AND PR.Comp_ID = @Comp_Id
          AND (@Comp_Id <> 'Comp-1669' OR LOWER(ISNULL(BL.ServiceName, '')) IN ('buildloyalty', 'srv1001'))
    ) x
    GROUP BY M_Codeid, MobileNo;

    CREATE CLUSTERED INDEX IX_Points_MCodeid ON #Points(M_Codeid, MobileNo);

    ----------------------------------------------------
    -- REFERRAL POINTS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#ScanReferrals') IS NOT NULL DROP TABLE #ScanReferrals;

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
    -- CODE CONFIG POINTS (ISOLATED FOR COMP-1669)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;

    CREATE TABLE #CodeConfigPoints
    (
        M_Codeid BIGINT,
        Frequency INT,
        ConfigPoints DECIMAL(18,2),
        AssignPoint DECIMAL(18,2),
        TotalFrequency INT
    );
    CREATE CLUSTERED INDEX IX_CodeConfigPoints_MCodeid ON #CodeConfigPoints(M_Codeid);

    IF @Comp_Id = 'Comp-1669'
    BEGIN
        -- ISOLATED SPECIFICALLY FOR COMP-1669 (Loyalty Points SRV1001 Priority)
        ;WITH ConfigRanked AS (
            SELECT 
                MC.M_Codeid,
                ISNULL(SST.Frequency, 1) AS Frequency,
                CAST(
                    CASE 
                        WHEN SS.Service_ID = 'SRV1001' THEN ISNULL(SST.Points, 0)
                        WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                        ELSE ISNULL(SST.IsCash, 0)
                    END AS DECIMAL(18,2)
                ) AS ConfigPoints,
                CAST(
                    CASE 
                        WHEN SS.Service_ID = 'SRV1001' THEN ISNULL(SST.Points, 0)
                        WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                        ELSE ISNULL(SST.IsCash, 0)
                    END AS DECIMAL(18,2)
                ) AS AssignPoint,
                ROW_NUMBER() OVER (
                    PARTITION BY MC.M_Codeid 
                    ORDER BY CASE WHEN SS.Service_ID = 'SRV1001' THEN 1 WHEN SS.Service_ID = 'SRV1005' THEN 2 ELSE 3 END,
                             SST.SST_Id DESC
                ) AS rn
            FROM #MCode MC
            INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
            INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
            WHERE SS.Comp_ID = 'Comp-1669'
              AND SS.IsActive = 1 AND SS.IsDelete = 0
              AND SST.IsActive = 1 AND SST.IsDelete = 0
              AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
              AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
              AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        )
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency)
        SELECT 
            M_Codeid,
            Frequency,
            ConfigPoints,
            AssignPoint,
            1 AS TotalFrequency
        FROM ConfigRanked
        WHERE rn = 1;
    END
    ELSE
    BEGIN
        -- STANDARD LOGIC FOR ALL OTHER COMPANIES (100% UNTOUCHED)
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency)
        SELECT 
            MC.M_Codeid,
            MAX(ISNULL(SST.Frequency, 1)) AS Frequency,
            MAX(CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                    ELSE ISNULL(SST.IsCash, 0) * @Multiplier
                END 
            AS DECIMAL(18,2))) AS ConfigPoints,
            MAX(CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                    ELSE ISNULL(SST.IsCash, 0)
                END 
            AS DECIMAL(18,2))) AS AssignPoint,
            SUM(ISNULL(SST.Frequency, 1)) AS TotalFrequency
        FROM #MCode MC
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        WHERE SS.Comp_ID = @Comp_Id 
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
          AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
          AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        GROUP BY MC.M_Codeid;
    END

    ----------------------------------------------------
    -- COMBINE SCANS AND REGISTRATION REFERRALS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalReport') IS NOT NULL DROP TABLE #FinalReport;

    CREATE TABLE #FinalReport (
        UniqueCode VARCHAR(100),
        Enq_Date DATETIME,
        Dial_Mode VARCHAR(50),
        ConsumerName NVARCHAR(150),
        MobileNo VARCHAR(50),
        State NVARCHAR(100),
        Vrkabel_User_Type NVARCHAR(100),
        City NVARCHAR(100),
        Pro_Name NVARCHAR(200),
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
    INSERT INTO #FinalReport
    SELECT 
        (E.Received_Code1 + E.Received_Code2) AS UniqueCode,
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
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
                CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(P.Points, 0)
                    WHEN ISNULL(P.Points, 0) > 0 THEN P.Points 
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS Points,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 'Verified'
            WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1)) THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
			E.Latitude,
			E.Longitude,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
                CASE 
                    WHEN ISNULL(CP.AssignPoint, 0) > 0 THEN CP.AssignPoint
                    WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint
                    ELSE ISNULL(CP.ConfigPoints, 0)
                END
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
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
        LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid;

    -- 2. Insert registration referrals (virtual rows)
    INSERT INTO #FinalReport
    SELECT 
        '' AS UniqueCode,
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
    GROUP BY BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, MC.State, cc.Vrkabel_User_Type, MC.City, BL.UpdateDate;

    -- 3. Insert other/extra earn point entries (Bonus, Repair, KYC, Invoice, Team Scans, etc.)
    INSERT INTO #FinalReport
    SELECT 
        ISNULL(CAST(C.Code1 AS VARCHAR(50)) + CAST(C.Code2 AS VARCHAR(50)), '') AS UniqueCode,
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
        SUM(CAST(
            CASE 
                WHEN @Comp_Id = 'Comp-1669' THEN
                    CASE
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
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
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
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
    WHERE BL.compid = @Comp_Id
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND (
          (@Comp_Id = 'Comp-1669' AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('buildloyalty', 'srv1001'))
          OR
          (@Comp_Id <> 'Comp-1669' AND (
              BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
              OR NOT EXISTS (
                  SELECT 1 FROM #Enq E 
                  WHERE E.M_Codeid = MCMC.M_Codeid 
                    AND (E.MobileNo = MC.MobileNo OR '91' + E.MobileNo = MC.MobileNo OR E.MobileNo = '91' + MC.MobileNo)
              )
          ))
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
    GROUP BY BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, MC.State, cc.Vrkabel_User_Type, MC.City, BL.UpdateDate, BL.ServiceName, C.Code1, C.Code2, PR.Pro_Name, MCd.LabelRequestId;

    ----------------------------------------------------
    -- RESULT SET 1
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            FR.UniqueCode,
            FR.Enq_Date,
            FR.Dial_Mode,
            FR.ConsumerName,
            FR.MobileNo,
            FR.State,
            FR.City,
            FR.Pro_Name,
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
        )
        ORDER BY FR.Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT 
            FR.UniqueCode,
            FR.Enq_Date,
            FR.Dial_Mode,
            FR.ConsumerName,
            FR.MobileNo,
            FR.State,
            FR.City,
            FR.Pro_Name,
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
        );
    END
END
GO

/****** 2. Fix SP_Admin_GetCodesActivityReport_AI (Support 10-digit and 12-digit mobile search with country code) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Admin_GetCodesActivityReport_AI]
    @Comp_Id          VARCHAR(50)   = NULL,
    @datePreset       NVARCHAR(50)  = 'TODAY', -- Today (default), Week (7 days)
    @FromDate         DATE          = NULL,
    @ToDate           DATE          = NULL,
    @CodeStatusFilter NVARCHAR(50)  = NULL,    -- Verified, Already Scanned, Invalid
    @DialModeFilter   NVARCHAR(50)  = NULL,    -- Website, BL_APP, etc.
    @Search           NVARCHAR(100) = NULL,
    @Page             INT           = 1,
    @Limit            INT           = 10,
    @IsExport         BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------
    -- 0. CLEAN / NORMALIZE INPUTS
    ----------------------------------------------------
    SET @Comp_Id = NULLIF(LTRIM(RTRIM(@Comp_Id)), '');
    IF (UPPER(@Comp_Id) = 'ALL') SET @Comp_Id = NULL;

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' OR @CodeStatusFilter = 'null' OR UPPER(@CodeStatusFilter) = 'ALL' SET @CodeStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' OR @DialModeFilter = 'null' OR UPPER(@DialModeFilter) = 'ALL' SET @DialModeFilter = NULL;

    DECLARE @SearchMobile NVARCHAR(30) = NULL;
    IF @Search IS NOT NULL
    BEGIN
        DECLARE @CleanSearchDigits NVARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Search, '+', ''), '-', ''), ' ', ''), '(', '');
        SET @CleanSearchDigits = REPLACE(@CleanSearchDigits, ')', '');
        IF @CleanSearchDigits NOT LIKE '%[^0-9]%' AND LEN(@CleanSearchDigits) >= 10
        BEGIN
            SET @SearchMobile = RIGHT(@CleanSearchDigits, 10);
        END
    END

    ----------------------------------------------------
    -- 1. DATE RANGE CALCULATION (Matches BLReports datePreset logic)
    ----------------------------------------------------
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE IF (@FromDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = '2015-01-01';
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        DECLARE @Preset NVARCHAR(50) = UPPER(ISNULL(@datePreset, 'TODAY'));
        IF (@Preset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@Preset = 'YESTERDAY' OR @Preset = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@Preset = 'WEEK' OR @Preset = 'THIS WEEK' OR @Preset = 'LAST7DAYS')
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
        ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH' OR @Preset = 'LAST30DAYS')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@Preset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@Preset = 'QUARTER' OR @Preset = 'THIS QUARTER' OR @Preset = 'LAST90DAYS')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@Preset = 'YEAR' OR @Preset = 'THIS YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@Preset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF (@Preset = 'ALL' OR @Preset = 'CUSTOM')
        BEGIN
            SET @StartDate = '2015-01-01';
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    ----------------------------------------------------
    -- 2. ENQUIRIES (Filter by Date Range and Company)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

    SELECT 
        E.Received_Code1,
        E.Received_Code2,
        (E.Received_Code1 + E.Received_Code2) AS UniqueCode,
        E.Enq_Date,
        E.Dial_Mode,
        E.Is_Success,
        E.MobileNo,
        E.Latitude,
        E.Longitude,
        M.Row_ID AS M_Codeid,
        M.Series_Order,
        M.Series_Serial,
        M.Pro_ID,
        PR.Comp_ID,
        PR.Pro_Name
    INTO #Enq
    FROM dbo.Pro_Enq E WITH (NOLOCK)
    INNER JOIN dbo.M_Code M WITH (NOLOCK)
        ON E.Received_Code1 = M.Code1
       AND E.Received_Code2 = M.Code2
    INNER JOIN dbo.Pro_Reg PR WITH (NOLOCK)
        ON PR.Pro_ID = M.Pro_ID
    WHERE E.Enq_Date >= @StartDate
      AND E.Enq_Date <  @EndDate
      AND (@Comp_Id IS NULL OR PR.Comp_ID = @Comp_Id)
      AND (@DialModeFilter IS NULL OR E.Dial_Mode = @DialModeFilter)
      AND (
          @Search IS NULL 
          OR E.MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND E.MobileNo LIKE '%' + @SearchMobile + '%')
          OR (E.Received_Code1 + E.Received_Code2) LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND (E.Received_Code1 + E.Received_Code2) LIKE '%' + @SearchMobile + '%')
          OR PR.Comp_ID LIKE '%' + @Search + '%'
      );

    CREATE INDEX IX_Enq_Code   ON #Enq(Received_Code1, Received_Code2);
    CREATE INDEX IX_Enq_Mobile ON #Enq(MobileNo);
    CREATE INDEX IX_Enq_MCode  ON #Enq(M_Codeid);

    ----------------------------------------------------
    -- 3. POINTS FROM BLOYALTYPOINTS EARNED
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT
        MC.M_Codeid,
        E.MobileNo,
        MAX(CAST(
            CASE 
                WHEN BL.Points IS NOT NULL AND BL.Points > 0 THEN BL.Points
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash
                ELSE 0.00
            END AS DECIMAL(18,2)
        )) AS Points
    INTO #Points
    FROM dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN dbo.BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
        ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN dbo.M_Consumer_M_Code MC WITH (NOLOCK) 
        ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    INNER JOIN #Enq E 
        ON MC.M_Codeid = E.M_Codeid
    WHERE (@Comp_Id IS NULL OR BL.compid = @Comp_Id)
      AND LOWER(ISNULL(BL.ServiceName, '')) IN ('buildloyalty', 'srv1001', 'srv1005', 'srv1028', 'srv1029', 'srv1023', 'srv1024', 'srv1027')
    GROUP BY MC.M_Codeid, E.MobileNo;

    CREATE INDEX IX_Points_MCode ON #Points(M_Codeid, MobileNo);

    ----------------------------------------------------
    -- 4. FINAL REPORT TEMP TABLE
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalReport') IS NOT NULL DROP TABLE #FinalReport;

    CREATE TABLE #FinalReport (
        CompanyId   VARCHAR(50),
        CompanyName NVARCHAR(250),
        MobileNo    VARCHAR(50),
        UniqueCode  VARCHAR(100),
        Pro_Name    NVARCHAR(250),
        ServiceName NVARCHAR(150),
        Enq_Date    DATETIME,
        Dial_Mode   VARCHAR(50),
        Points      VARCHAR(50),
        Result      VARCHAR(50),
        Latitude    VARCHAR(50),
        Longitude   VARCHAR(50)
    );

    -- 5a. Insert scan enquiries (Verified, Already Scanned, Invalid)
    INSERT INTO #FinalReport (CompanyId, CompanyName, MobileNo, UniqueCode, Pro_Name, ServiceName, Enq_Date, Dial_Mode, Points, Result, Latitude, Longitude)
    SELECT 
        E.Comp_ID AS CompanyId,
        ISNULL(CR.Comp_Name, E.Comp_ID) AS CompanyName,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) >= 10 THEN RIGHT(MC.MobileNo, 10)
            WHEN LEN(ISNULL(E.MobileNo,'')) >= 10 THEN RIGHT(E.MobileNo, 10)
            ELSE ISNULL(MC.MobileNo, ISNULL(E.MobileNo,''))
        END AS MobileNo,
        E.UniqueCode,
        E.Pro_Name,
        'Code Check' AS ServiceName,
        E.Enq_Date,
        E.Dial_Mode,
        CAST(
            CASE 
                WHEN E.Is_Success = 1 THEN ISNULL(P.Points, 0.00)
                ELSE 0.00
            END AS VARCHAR(50)
        ) AS Points,
        CASE 
            WHEN E.Is_Success = 1 THEN 'Verified'
            WHEN E.Is_Success = 2 THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
        ISNULL(E.Latitude, '') AS Latitude,
        ISNULL(E.Longitude, '') AS Longitude
    FROM #Enq E
    LEFT JOIN dbo.Comp_Reg CR WITH (NOLOCK) ON CR.Comp_ID = E.Comp_ID
    LEFT JOIN dbo.M_Consumer MC WITH (NOLOCK) 
        ON (MC.MobileNo = E.MobileNo OR (LEN(E.MobileNo) >= 10 AND RIGHT(MC.MobileNo, 10) = RIGHT(E.MobileNo, 10))) 
       AND MC.IsDelete = 0
    LEFT JOIN #Points P 
        ON P.M_Codeid = E.M_Codeid 
       AND (P.MobileNo = E.MobileNo OR (LEN(P.MobileNo) >= 10 AND LEN(E.MobileNo) >= 10 AND RIGHT(P.MobileNo, 10) = RIGHT(E.MobileNo, 10)));

    -- 5b. Insert Referral Point entries (ServiceName = 'refral' or 'referral')
    INSERT INTO #FinalReport (CompanyId, CompanyName, MobileNo, UniqueCode, Pro_Name, ServiceName, Enq_Date, Dial_Mode, Points, Result, Latitude, Longitude)
    SELECT 
        BL.compid AS CompanyId,
        ISNULL(CR.Comp_Name, BL.compid) AS CompanyName,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) >= 10 THEN RIGHT(MC.MobileNo, 10)
            ELSE ISNULL(MC.MobileNo,'')
        END AS MobileNo,
        '' AS UniqueCode,
        'Referral Bonus' AS Pro_Name,
        'Referral' AS ServiceName,
        BL.UpdateDate AS Enq_Date,
        '' AS Dial_Mode,
        '0.00' AS Points,
        'Referral Point' AS Result,
        '' AS Latitude,
        '' AS Longitude
    FROM dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN dbo.M_Consumer MC WITH (NOLOCK) ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    LEFT JOIN dbo.Comp_Reg CR WITH (NOLOCK) ON CR.Comp_ID = BL.compid
    WHERE (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND (@Comp_Id IS NULL OR BL.compid = @Comp_Id)
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate <  @EndDate
      AND (
          @Search IS NULL
          OR MC.MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND MC.MobileNo LIKE '%' + @SearchMobile + '%')
          OR MC.ConsumerName LIKE '%' + @Search + '%'
          OR BL.compid LIKE '%' + @Search + '%'
      )
    GROUP BY BL.compid, CR.Comp_Name, BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, BL.UpdateDate, BL.ServiceName;

    -- 5c. Insert Other/Extra Earn Point entries (Bonus, Repair, KYC, Invoice)
    INSERT INTO #FinalReport (CompanyId, CompanyName, MobileNo, UniqueCode, Pro_Name, ServiceName, Enq_Date, Dial_Mode, Points, Result, Latitude, Longitude)
    SELECT 
        BL.compid AS CompanyId,
        ISNULL(CR.Comp_Name, BL.compid) AS CompanyName,
        CASE 
            WHEN LEN(ISNULL(MC.MobileNo,'')) >= 10 THEN RIGHT(MC.MobileNo, 10)
            ELSE ISNULL(MC.MobileNo,'')
        END AS MobileNo,
        ISNULL(CAST(C.Code1 AS VARCHAR(50)) + CAST(C.Code2 AS VARCHAR(50)), '') AS UniqueCode,
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
        BL.UpdateDate AS Enq_Date,
        '' AS Dial_Mode,
        CAST(SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash
                ELSE ISNULL(BL.Points, 0)
            END AS DECIMAL(18,2)
        )) AS VARCHAR(50)) AS Points,
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
        '' AS Longitude
    FROM dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN dbo.M_Consumer MC WITH (NOLOCK) ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    LEFT JOIN dbo.Comp_Reg CR WITH (NOLOCK) ON CR.Comp_ID = BL.compid
    LEFT JOIN dbo.BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    LEFT JOIN dbo.M_Consumer_M_Code MCMC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MCMC.M_Consumer_MCodeid
    LEFT JOIN dbo.M_Code C WITH (NOLOCK) ON MCMC.M_Codeid = C.Row_ID
    LEFT JOIN dbo.Pro_Reg PR WITH (NOLOCK) ON C.Pro_ID = PR.Pro_ID
    LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.SST_Id = BL.SST_id
    LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) ON SS.Subscribe_Id = SST.Subscribe_Id
    LEFT JOIN dbo.M_Service MS WITH (NOLOCK) ON MS.Service_ID = SS.Service_ID
    WHERE (@Comp_Id IS NULL OR BL.compid = @Comp_Id)
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
      AND BL.UpdateDate <  @EndDate
      AND (
          @Search IS NULL
          OR MC.MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND MC.MobileNo LIKE '%' + @SearchMobile + '%')
          OR MC.ConsumerName LIKE '%' + @Search + '%'
          OR BL.compid LIKE '%' + @Search + '%'
      )
    GROUP BY BL.compid, CR.Comp_Name, BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, BL.UpdateDate, MS.ServiceName, BL.ServiceName, C.Code1, C.Code2, PR.Pro_Name;

    ----------------------------------------------------
    -- 6. TOTAL RECORDS (Result Set 1)
    ----------------------------------------------------
    DECLARE @TotalRecords INT;

    SELECT @TotalRecords = COUNT(1)
    FROM #FinalReport FR
    WHERE (
        @CodeStatusFilter IS NULL
        OR FR.Result = @CodeStatusFilter
        OR (@CodeStatusFilter = 'Already Verified' AND FR.Result = 'Already Scanned')
    )
    AND (
        @Search IS NULL
        OR FR.MobileNo LIKE '%' + @Search + '%'
        OR (@SearchMobile IS NOT NULL AND FR.MobileNo LIKE '%' + @SearchMobile + '%')
        OR FR.UniqueCode LIKE '%' + @Search + '%'
        OR (@SearchMobile IS NOT NULL AND FR.UniqueCode LIKE '%' + @SearchMobile + '%')
        OR FR.CompanyId LIKE '%' + @Search + '%'
        OR FR.CompanyName LIKE '%' + @Search + '%'
        OR FR.ServiceName LIKE '%' + @Search + '%'
    );

    SELECT @TotalRecords AS TotalRecords;

    ----------------------------------------------------
    -- 7. PAGINATED DATA (Result Set 2)
    ----------------------------------------------------
    SELECT 
        FR.CompanyId,
        FR.CompanyName,
        FR.MobileNo,
        FR.UniqueCode,
        FR.Pro_Name,
        FR.ServiceName,
        FR.Enq_Date,
        FR.Dial_Mode,
        FR.Points,
        FR.Result,
        FR.Latitude,
        FR.Longitude
    FROM #FinalReport FR
    WHERE (
        @CodeStatusFilter IS NULL
        OR FR.Result = @CodeStatusFilter
        OR (@CodeStatusFilter = 'Already Verified' AND FR.Result = 'Already Scanned')
    )
    AND (
        @Search IS NULL
        OR FR.MobileNo LIKE '%' + @Search + '%'
        OR (@SearchMobile IS NOT NULL AND FR.MobileNo LIKE '%' + @SearchMobile + '%')
        OR FR.UniqueCode LIKE '%' + @Search + '%'
        OR (@SearchMobile IS NOT NULL AND FR.UniqueCode LIKE '%' + @SearchMobile + '%')
        OR FR.CompanyId LIKE '%' + @Search + '%'
        OR FR.CompanyName LIKE '%' + @Search + '%'
        OR FR.ServiceName LIKE '%' + @Search + '%'
    )
    ORDER BY FR.Enq_Date DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 1000000 ELSE @Limit END ROWS ONLY;
END
GO

/****** 3. Fix SP_BL_GetCodesActivityReport_MAndM_AI (Support 10-digit and 12-digit mobile search with country code) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_MAndM_AI]
(
    @Comp_Id NVARCHAR(15) = NULL,
    @CompId NVARCHAR(15) = NULL,
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Search NVARCHAR(20) = NULL,
    @Scheme NVARCHAR(10) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,
    @StateFilter NVARCHAR(50) = NULL,
    @DialModeFilter NVARCHAR(50) = NULL,
    @Lot NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize company ID parameter name
    IF @Comp_Id IS NULL AND @CompId IS NOT NULL
        SET @Comp_Id = @CompId;

    -- Normalize Lot parameter name (e.g., 'LOT8', 'Lot 8', 'lot8' -> '8')
    IF @Lot IS NOT NULL
    BEGIN
        SET @Lot = LTRIM(RTRIM(@Lot));
        IF UPPER(@Lot) LIKE 'LOT%'
        BEGIN
            SET @Lot = LTRIM(RTRIM(SUBSTRING(@Lot, 4, LEN(@Lot))));
        END
    END

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(15) = @Comp_Id;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

    ---------------------------------------------------------
    -- Normalize
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @Limit > 5000 SET @Limit = 5000;

    IF (@Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR @Search = 'NULL')
        SET @Search = NULL;

    DECLARE @SearchMobile NVARCHAR(30) = NULL;
    IF @Search IS NOT NULL
    BEGIN
        DECLARE @CleanSearchDigits NVARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Search, '+', ''), '-', ''), ' ', ''), '(', '');
        SET @CleanSearchDigits = REPLACE(@CleanSearchDigits, ')', '');
        IF @CleanSearchDigits NOT LIKE '%[^0-9]%' AND LEN(@CleanSearchDigits) >= 10
        BEGIN
            SET @SearchMobile = RIGHT(@CleanSearchDigits, 10);
        END
    END

    IF (@Scheme IS NULL OR LTRIM(RTRIM(@Scheme)) = '' OR @Scheme = 'NULL')
        SET @Scheme = NULL;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Date range calculation
    ---------------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @Win NVARCHAR(50) = @datePreset;

    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@Win = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);

        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END
        ELSE
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    ---------------------------------------------------------
    -- MATERIALIZE RESULT
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#ScanReferrals') IS NOT NULL DROP TABLE #ScanReferrals;

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
      AND MC.compid = @ActualCompId
    GROUP BY CAST(C.Code1 AS VARCHAR(50)), CAST(C.Code2 AS VARCHAR(50));

    CREATE INDEX IX_ScanReferrals ON #ScanReferrals(Code1, Code2);

    IF OBJECT_ID('tempdb..#FilteredData') IS NOT NULL DROP TABLE #FilteredData;

    SELECT
        pc.Comp_id,
        pc.M_ConsumerId,
        pc.Enq_Date,
        ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name) AS Pro_Name,
        pc.Code1,
        pc.Code2,
        CONCAT(pc.Code1, pc.Code2) AS uniquecode,
        CASE 
            WHEN pc.Is_Success = 1 THEN
                CASE 
                    WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, ISNULL(pc.Cash, 0))
                    ELSE CASE WHEN pc.Points IS NULL OR pc.Points = 0 THEN ISNULL(pc.Cash, 0) ELSE pc.Points END
                END
            ELSE 0
        END AS amount_won,
        CASE 
            WHEN pc.Is_Success = 1 THEN 'Verified'
            WHEN pc.Is_Success = 2 THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
        pc.Dial_Mode AS mode_of_verification,
        gc.City, 
        gc.State,
        gc.Latitude,
        gc.Longitude,
        mc.PinCode, 
        bk.Branch,
        ts.kycremark, 
        mc.ConsumerName, 
        pc.MobileNo,
        mc.AadharHolderName, 
        CAST(mc.aadharNumber AS VARCHAR(20)) AS aadharNumber, 
        mc.Address,
        mc.PanHolderName, 
        mc.pancard_number,
        bk.Bank_Name, 
        bk.Account_HolderNm,
        bk.Account_No, 
        bk.IFSC_Code,
        mc.employeeID AS [Mstar_TechMasterId],
        mc.distributorID AS DealerCode, 
        mc.transaction_status,
        mc.dealer_state, 
        mc.designation, 
        mc.DealerType,
        CASE 
            WHEN ts.VRKbl_KYC_status = 1 THEN 'APPROVED' 
            WHEN ts.VRKbl_KYC_status = 2 THEN 'REJECTED' 
            ELSE 'PENDING' 
        END AS KycStatus,
        CASE 
            WHEN ISNULL(pc.expireCodeAmount, 0) > 0 THEN 'EXPIRED' 
            ELSE 'ACTIVE' 
        END AS SchemeStatus,
        CASE 
            WHEN pc.Is_Success = 1 THEN
                CASE 
                    WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(sst.IsCash, 0) 
                    ELSE CASE WHEN sst.Points IS NULL OR sst.Points = 0 THEN ISNULL(sst.IsCash, 0) ELSE sst.Points END
                END
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN pc.Is_Success = 1 THEN
                CASE 
                    WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) 
                    ELSE CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END
                END
            ELSE 0 
        END AS WornPoint,
        ISNULL(R.ReferralPoints, 0) AS ReferralPoints,
        CASE 
            WHEN pc.Points IS NULL OR pc.Points = 0 THEN ISNULL(pc.Cash, 0)
            ELSE pc.Points
        END AS Points,
        ROW_NUMBER() OVER (
            PARTITION BY pc.Code1, pc.Code2, pc.Enq_Date
            ORDER BY pc.Enq_Date DESC, mc.dealer_state, mc.pancard_number, mc.aadharNumber, pc.Dial_Mode DESC
        ) AS rn
    INTO #FilteredData
    FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
    LEFT JOIN #ScanReferrals R ON R.Code1 = pc.Code1 AND R.Code2 = pc.Code2
    LEFT JOIN dbo.M_Consumer mc WITH (NOLOCK) ON mc.M_Consumerid = pc.m_consumerid AND mc.IsDelete = 0
    LEFT JOIN dbo.m_dealermaster md WITH (NOLOCK) ON md.DealerTechnicianId = mc.employeeID AND md.DealerCode = mc.distributorID
    LEFT JOIN dbo.tbl_VendorViseKYCStatus ts WITH (NOLOCK) ON ts.M_Consumerid = pc.m_consumerid AND ts.Comp_Id = pc.Comp_Id
    OUTER APPLY (
        SELECT TOP 1 mb.Bank_Name, mb.Account_HolderNm, mb.Account_No, mb.IFSC_Code, mb.Branch
        FROM dbo.M_BankAccount mb WITH (NOLOCK)
        WHERE mb.M_Consumerid = pc.m_consumerid
        ORDER BY mb.Entry_Date DESC, mb.Row_ID DESC
    ) bk
    LEFT JOIN dbo.GeoLocationData gc WITH (NOLOCK) ON gc.Code1 = pc.Code1 AND gc.Code2 = pc.Code2
    LEFT JOIN dbo.M_Code mcd WITH (NOLOCK) ON mcd.Code1 = pc.Code1 AND mcd.Code2 = pc.Code2
    LEFT JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mcd.Pro_ID
    LEFT JOIN dbo.M_ServiceSubscription ss WITH (NOLOCK) 
        ON ss.Pro_ID = mcd.Pro_ID
       AND CONCAT(FORMAT(mcd.Series_Order, '000#'), FORMAT(mcd.Series_Serial, '000#'))
           BETWEEN CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#'))
           AND CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
           AND ss.IsActive = 1 AND ss.IsDelete = 0
    LEFT JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) 
        ON sst.Subscribe_Id = ss.Subscribe_Id
       AND sst.IsActive = 1 AND sst.IsDelete = 0
    LEFT JOIN dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
        ON BL.Code1 = pc.Code1
       AND BL.Code2 = pc.Code2
       AND (BL.compid = @ActualCompId OR BL.compid IS NULL)
       AND BL.M_Consumerid = pc.M_Consumerid
    WHERE
        pc.Comp_Id = @ActualCompId
        AND (
            (@IsSBUTeam = 0 AND (pc.distributedid <> 'SBUTEAM' OR pc.distributedid IS NULL) AND (mc.distributorID <> 'SBUTEAM' OR mc.distributorID IS NULL)) OR
            (@IsSBUTeam = 1 AND (pc.distributedid = 'SBUTEAM' OR mc.distributorID = 'SBUTEAM'))
        )
        AND (@StartDate IS NULL OR pc.Enq_Date >= @StartDate)  and PC.Enq_Date >='2022-08-04 00:00:00.000'
        AND (@EndDate IS NULL OR pc.Enq_Date < DATEADD(DAY, 1, @EndDate))
        AND (@Scheme IS NULL OR ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name) LIKE '%' + @Scheme + '%')
        AND (@DialModeFilter IS NULL OR pc.Dial_Mode = @DialModeFilter)
        AND (@StateFilter IS NULL OR gc.State = @StateFilter)
        AND (
            @CodeStatusFilter IS NULL
            OR (@CodeStatusFilter = 'Verified' AND pc.Is_Success = 1)
            OR ((@CodeStatusFilter = 'Already Scanned' OR @CodeStatusFilter = 'Already Verified') AND pc.Is_Success = 2)
            OR (@CodeStatusFilter = 'Invalid' AND pc.Is_Success NOT IN (1,2))
        )
        AND (
            @Search IS NULL
            OR pc.MobileNo LIKE '%' + @Search + '%'
            OR (@SearchMobile IS NOT NULL AND pc.MobileNo LIKE '%' + @SearchMobile + '%')
            OR (pc.Code1 + pc.Code2) LIKE '%' + @Search + '%'
            OR (@SearchMobile IS NOT NULL AND (pc.Code1 + pc.Code2) LIKE '%' + @SearchMobile + '%')
        )
        AND (
            @Lot IS NULL
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 4) = @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 4) = 'MCS' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 4) = 'mcs' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 5) = '_' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 5) = '_MCS' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 5) = '_mcs' + @Lot
            OR ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name) LIKE '%' + @Lot
        ) OPTION (RECOMPILE);

    -- Insert registration referrals (virtual rows)
    INSERT INTO #FilteredData (
        Comp_id, M_ConsumerId, Enq_Date, Pro_Name, Code1, Code2, uniquecode, amount_won, Result,
        mode_of_verification, City, State, Latitude, Longitude, PinCode, Branch, kycremark,
        ConsumerName, MobileNo, AadharHolderName, aadharNumber, Address, PanHolderName,
        pancard_number, Bank_Name, Account_HolderNm, Account_No, IFSC_Code,
        Mstar_TechMasterId, DealerCode, transaction_status, dealer_state, designation, DealerType,
        KycStatus, SchemeStatus, AssignPoint, WornPoint, ReferralPoints, Points, rn
    )
    SELECT 
        BL.compid,
        BL.M_Consumerid,
        BL.UpdateDate AS Enq_Date,
        'Referral Bonus' AS Pro_Name,
        '' AS Code1,
        '' AS Code2,
        '' AS uniquecode,
        0 AS amount_won,
        'Referral' AS Result,
        'Referral' AS mode_of_verification,
        MC.City,
        MC.State,
        '' AS Latitude,
        '' AS Longitude,
        MC.PinCode,
        '' AS Branch,
        '' AS kycremark,
        MC.ConsumerName,
        MC.MobileNo,
        '' AS AadharHolderName,
        '' AS aadharNumber,
        MC.Address,
        '' AS PanHolderName,
        '' AS pancard_number,
        '' AS Bank_Name,
        '' AS Account_HolderNm,
        '' AS Account_No,
        '' AS IFSC_Code,
        '' AS Mstar_TechMasterId,
        '' AS DealerCode,
        '' AS transaction_status,
        '' AS dealer_state,
        '' AS designation,
        '' AS DealerType,
        '' AS KycStatus,
        'ACTIVE' AS SchemeStatus,
        0 AS AssignPoint,
        0 AS WornPoint,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralPoints,
        0 AS Points,
        1 AS rn
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    WHERE (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND BL.Code1 IS NULL
      AND BL.compid = @ActualCompId
      AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
      AND (@EndDate IS NULL OR BL.UpdateDate < DATEADD(DAY, 1, @EndDate))
      AND (@StateFilter IS NULL OR MC.State = @StateFilter)
      AND (@CodeStatusFilter IS NULL OR @CodeStatusFilter = 'Referral')
      AND @Scheme IS NULL
      AND @Lot IS NULL
      AND (
          @Search IS NULL
          OR MC.MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND MC.MobileNo LIKE '%' + @SearchMobile + '%')
      )
    GROUP BY BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, MC.State, MC.City, MC.PinCode, MC.Address, BL.compid, BL.UpdateDate;

    ---------------------------------------------------------
    -- EXPORT MODE
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            Enq_Date, Pro_Name, Code1, Code2, uniquecode, amount_won, Result, 
            mode_of_verification, City, State, Latitude, Longitude, PinCode, Branch, 
            kycremark, ConsumerName, MobileNo, AadharHolderName, aadharNumber, 
            Address, PanHolderName, pancard_number, Bank_Name, Account_HolderNm, 
            Account_No, IFSC_Code, Mstar_TechMasterId, DealerCode, 
            transaction_status, dealer_state, designation, DealerType, 
            KycStatus, SchemeStatus, AssignPoint, WornPoint, ReferralPoints, Points
        FROM #FilteredData 
        WHERE rn = 1 
        ORDER BY Enq_Date DESC;
        RETURN;
    END

    ---------------------------------------------------------
    -- NORMAL MODE → PAGINATION
    ---------------------------------------------------------
    SELECT *
    FROM #FilteredData
    WHERE rn = 1 
    ORDER BY Enq_Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ---------------------------------------------------------
    -- META
    ---------------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM #FilteredData
    WHERE rn = 1;

    DROP TABLE IF EXISTS #FilteredData, #ScanReferrals;
END;
GO
