USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetCodesActivityReport_AI]    Script Date: 24-08-2026 17:02:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_AI]
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
          OR (Received_Code1 + Received_Code2) LIKE '%' + @Search + '%'
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
        LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid
        LEFT JOIN #ScanReferrals R ON R.Code1 = E.Received_Code1 AND R.Code2 = E.Received_Code2
        WHERE (cc.comp_id = @comp_id OR cc.comp_id IS NULL) and 
		  (E.Is_Success != 1 OR E.rn <= ISNULL(CP.TotalFrequency, 1))
          AND (@StateFilter IS NULL OR G.State = @StateFilter);

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
			 OR FR.UniqueCode LIKE '%' + @Search + '%'
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
			 OR FR.UniqueCode LIKE '%' + @Search + '%'
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
			 OR FR.UniqueCode LIKE '%' + @Search + '%'
        );
    END
END