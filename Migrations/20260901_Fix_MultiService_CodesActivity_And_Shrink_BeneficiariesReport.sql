-- Migration: Support Multi-Service Code Scans (SRV1001 + SRV1028) and Early Search Shrinking in SP_BL_GetCodesActivityReport_AI and SP_BL_GetBeneficiariesReport
-- Date: 2026-09-01

USE [Vcqru]
GO

-- ==============================================================================
-- 1. SP_BL_GetCodesActivityReport_AI (Multi-Service & Early Search Shrinking)
-- ==============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_AI]
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate DATE  = NULL,
    @ToDate DATE  = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,     -- (Verified, Already Scanned, Invalid)
    @StateFilter NVARCHAR(100) = NULL,
    @DialModeFilter NVARCHAR(50) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL,
    @Search NVARCHAR(30) = NULL
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
        MAX(Points) AS Points,
        MAX(WornPoint) AS WornPoint
    INTO #Points
    FROM (
        SELECT
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        WHERE BL.compid = @Comp_Id

        UNION ALL

        SELECT
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
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
        WHERE BL.compid IS NULL
          AND PR.Comp_ID = @Comp_Id
    ) x
    GROUP BY M_Codeid;

    CREATE CLUSTERED INDEX IX_Points_MCodeid ON #Points(M_Codeid);

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
    -- CODE CONFIG POINTS (ALIGNED WITH BENEFICIARIES REPORT)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;

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
    INTO #CodeConfigPoints
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

    CREATE CLUSTERED INDEX IX_CodeConfigPoints_MCodeid ON #CodeConfigPoints(M_Codeid);

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
				WHEN LEN(ISNULL(MC.MobileNo,'')) < 10 
					 THEN ISNULL(E.MobileNo,'')
				ELSE MC.MobileNo
			END AS MobileNo,
        G.State,cc.Vrkabel_User_Type,
        G.City,
        PR.Pro_Name,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
                CASE 
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
        LEFT JOIN M_Consumer MC ON MC.MobileNo = E.MobileNo AND MC.IsDelete = '0'
        LEFT JOIN tbl_Vendorvisekycstatus cc ON mc.M_Consumerid = cc.M_consumerId AND cc.comp_id = @comp_id
        LEFT JOIN #Geo G ON G.Code1 = E.Received_Code1 AND G.Code2 = E.Received_Code2 AND G.MobileNo = E.MobileNo
        LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid
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
        MC.MobileNo,
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
    inner join tbl_Vendorvisekycstatus cc on mc.M_Consumerid = cc.M_consumerId
    WHERE  cc.comp_id = @comp_id and (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND BL.Code1 IS NULL
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

    -- 3. Insert other/extra earn point entries (virtual rows)
    INSERT INTO #FinalReport
    SELECT 
        '' AS UniqueCode,
        BL.UpdateDate AS Enq_Date,
        '' AS Dial_Mode,
        MC.ConsumerName,
        MC.MobileNo,
        MC.State,cc.Vrkabel_User_Type,
        MC.City,
        ISNULL(NULLIF(BL.ServiceName, ''), 'Bonus Point') AS Pro_Name,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS Points,
        CASE 
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%kyc%' THEN 'KYC Point'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%invoice%' THEN 'Invoice Point'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%refral%' OR LOWER(ISNULL(BL.ServiceName, '')) LIKE '%referral%' THEN 'Referral Point'
            WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%bonus%' THEN 'Bonus Point'
            WHEN LTRIM(RTRIM(ISNULL(BL.ServiceName, ''))) <> '' THEN BL.ServiceName + ' Point'
            ELSE 'Bonus Point'
        END AS Result,
        '' AS Latitude,
        '' AS Longitude,
        0 AS AssignPoint,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS WornPoint,
        0 AS ReferralPoints,
        '' AS LabelRequestId
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    inner join tbl_Vendorvisekycstatus cc on mc.M_Consumerid = cc.M_consumerId
    WHERE  cc.comp_id = @comp_id and BL.compid = @Comp_Id
      AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate < @EndDate
      AND (@StateFilter IS NULL OR MC.State = @StateFilter)
      AND (
          @Search IS NULL
          OR MC.MobileNo LIKE '%' + @Search + '%'
          OR MC.ConsumerName LIKE '%' + @Search + '%'
      )
    GROUP BY BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, MC.State, cc.Vrkabel_User_Type, MC.City, BL.UpdateDate, BL.ServiceName;

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
GO


-- ==============================================================================
-- 2. SP_BL_GetBeneficiariesReport (Shrunk / Optimized)
-- ==============================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport]
(
    @Comp_Id         NVARCHAR(50),  
    @datePreset      NVARCHAR(20) = NULL,   -- TODAY, WEEK, LASTWEEK, MONTH, QUARTER, ALL
    @FromDate        DATE = NULL,
    @ToDate          DATE = NULL,
    @KYCStatusFilter NVARCHAR(20) = NULL,   -- Approved / Rejected / Pending
    @StateFilter     NVARCHAR(100) = NULL,
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL,
    @Search          NVARCHAR(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- DEFAULT PAGINATION
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- COMPANY FILTER PREPARATION
    ---------------------------------------------------------
    DECLARE @CompanyList TABLE (Comp_Id VARCHAR(50) PRIMARY KEY);
    INSERT INTO @CompanyList VALUES (@Comp_Id);

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (calculation_value / 100.0) 
    FROM loyalty_calculation WITH (NOLOCK)
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;

    ---------------------------------------------------------
    -- DATE RANGE
    ---------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') 
    FROM Comp_Reg WITH (NOLOCK) 
    WHERE Comp_ID = @Comp_Id AND ([Status] = 1 OR [Status] IS NULL);

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Normalize datePreset
    DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
    IF (@Win = '' OR @Win = 'NULL') SET @Win = 'ALL';

    -- Explicit date range overrides datePreset
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME)); -- Exclusive end date
    END
    ELSE IF (@Win = 'TODAY')
    BEGIN
        SET @StartDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@Win = 'WEEK' OR @Win = 'THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()) - 7, CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 7, @StartDate);
    END
    ELSE IF (@Win = 'MONTH' OR @Win = 'THIS MONTH')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME));
        SET @EndDate = DATEADD(MONTH, 1, @StartDate);
    END
    ELSE IF (@Win = 'QUARTER' OR @Win = 'THIS QUARTER')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
    END
    ELSE IF (@Win = 'LASTQUARTER')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
        SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
    END
    ELSE IF (@Win = 'YEAR' OR @Win = 'THIS YEAR')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'LASTYEAR')
    BEGIN
        SET @StartDate = DATEADD(YEAR, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME));
        SET @EndDate = DATEADD(YEAR, 1, @StartDate);
    END
    ELSE -- ALL / NULL
    BEGIN
        SET @StartDate = CAST(@CompanyStartDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    DROP TABLE IF EXISTS #Candidates, #Users, #UserMobiles, #State, #Benefit, #Claims, #UPI, #BPoints, #Transactions, #FinalData, #UniqueScans, #EarnedPoints, #ConfigPoints, #Referrals, #OtherEarnedPoints, #SearchMatchingUsers;

    -- Normalize filters early
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@KYCStatusFilter, ''))) = '' OR @KYCStatusFilter = 'null' SET @KYCStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'null' SET @StateFilter = NULL;

    ---------------------------------------------------------
    -- EARLY CANDIDATE SEARCH FILTER (SHRINKS SEARCH QUERY INSTANTLY)
    ---------------------------------------------------------
    CREATE TABLE #SearchMatchingUsers (M_ConsumerId INT PRIMARY KEY);

    IF @Search IS NOT NULL
    BEGIN
        INSERT INTO #SearchMatchingUsers (M_ConsumerId)
        SELECT DISTINCT M_ConsumerId
        FROM M_Consumer WITH (NOLOCK)
        WHERE (
            MobileNo LIKE '%' + @Search + '%'
            OR ConsumerName LIKE '%' + @Search + '%'
            OR City LIKE '%' + @Search + '%'
            OR State LIKE '%' + @Search + '%'
        );
    END

    ---------------------------------------------------------
    -- CANDIDATE USERS FOR THIS COMPANY (FAST DISCOVERY)
    ---------------------------------------------------------
    SELECT DISTINCT M_ConsumerId
    INTO #Candidates
    FROM (
        SELECT M_consumerId AS M_ConsumerId FROM tbl_VendorViseKYCStatus WITH (NOLOCK) WHERE Comp_id = @Comp_Id
        UNION
        SELECT MC.M_ConsumerId FROM ClaimDetails CD WITH (NOLOCK) INNER JOIN M_Consumer MC WITH (NOLOCK) ON CD.Mobileno = MC.MobileNo WHERE CD.Comp_id = @Comp_Id
        UNION
        SELECT M_Consumerid AS M_ConsumerId FROM BLoyaltyPointsEarned WITH (NOLOCK) WHERE compid = @Comp_Id
        UNION
        SELECT TRY_CAST(M_CounserID AS INT) AS M_ConsumerId FROM Transactions WITH (NOLOCK) WHERE (CompId = REPLACE(@Comp_Id, 'Comp-', '') OR CompId = @Comp_Id) AND Issuccess = 1
        UNION
        SELECT TRY_CAST(t.M_Consumerid AS INT) AS M_ConsumerId FROM tblUPITransactionDetails t WITH (NOLOCK) WHERE t.Comp_Id = @Comp_Id AND t.Status = 'Success' AND LEN(ISNULL(t.Code1, '')) > 3
    ) x
    WHERE M_ConsumerId IS NOT NULL
      AND (@Search IS NULL OR M_ConsumerId IN (SELECT M_ConsumerId FROM #SearchMatchingUsers));

    CREATE CLUSTERED INDEX IX_Candidates_ConsumerId ON #Candidates(M_ConsumerId);

    ---------------------------------------------------------
    -- USERS + KYC
    ---------------------------------------------------------
    SELECT DISTINCT
        C.M_ConsumerId,
        MC.ConsumerName,
        MC.MobileNo,
        MC.PinCode,
        MC.State,
        MC.City,
        V.VRKbl_KYC_status,
        CASE
            WHEN V.VRKbl_KYC_status = 1 THEN 'Approved'
            WHEN V.VRKbl_KYC_status = 2 THEN 'Rejected'
            ELSE 'Pending'
        END AS KYCStatus
    INTO #Users
    FROM #Candidates C
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON C.M_ConsumerId = MC.M_ConsumerId
    LEFT JOIN (
        SELECT M_consumerId AS M_ConsumerId, VRKbl_KYC_status, ROW_NUMBER() OVER (PARTITION BY M_consumerId ORDER BY Entry_date DESC) as rn
        FROM tbl_VendorViseKYCStatus WITH (NOLOCK)
        WHERE Comp_id = @Comp_Id
    ) V ON V.M_ConsumerId = C.M_ConsumerId AND V.rn = 1
    WHERE MC.IsDelete = 0;

    CREATE CLUSTERED INDEX IX_Users_ConsumerId ON #Users(M_ConsumerId);
    CREATE INDEX IX_Users_MobileNo ON #Users(MobileNo);

    -- Searchable Mobile Number Index for SARGable index seeks on Pro_Enq and ClaimDetails
    CREATE TABLE #UserMobiles (MobileNo NVARCHAR(50), M_ConsumerId INT);
    INSERT INTO #UserMobiles (MobileNo, M_ConsumerId)
    SELECT DISTINCT MobileNo, M_ConsumerId FROM #Users WHERE MobileNo IS NOT NULL AND LTRIM(RTRIM(MobileNo)) <> ''
    UNION
    SELECT DISTINCT RIGHT(MobileNo, 10), M_ConsumerId FROM #Users WHERE LEN(MobileNo) >= 10
    UNION
    SELECT DISTINCT '+91' + RIGHT(MobileNo, 10), M_ConsumerId FROM #Users WHERE LEN(MobileNo) >= 10
    UNION
    SELECT DISTINCT '91' + RIGHT(MobileNo, 10), M_ConsumerId FROM #Users WHERE LEN(MobileNo) >= 10
    UNION
    SELECT DISTINCT '0' + RIGHT(MobileNo, 10), M_ConsumerId FROM #Users WHERE LEN(MobileNo) >= 10;

    CREATE INDEX IX_UserMobiles_Mobile ON #UserMobiles(MobileNo);

    ---------------------------------------------------------
    -- LATEST STATE / CITY (OPTIMIZED)
    ---------------------------------------------------------
    SELECT *
    INTO #State
    FROM
    (
        SELECT
            U.M_ConsumerId,
            GE.State,
            GE.City,
            ROW_NUMBER() OVER (
                PARTITION BY U.M_ConsumerId
                ORDER BY GE.Enq_Date DESC
            ) AS rn
        FROM #Users U
        INNER JOIN GeoLocationData GE WITH (NOLOCK) ON GE.MobileNo = U.MobileNo
        WHERE GE.Comp_Id = @Comp_Id
    ) x
    WHERE rn = 1;

    CREATE CLUSTERED INDEX IX_State_ConsumerId ON #State(M_ConsumerId);

    ---------------------------------------------------------
    -- PRECISE POINT CALCULATION (OPTIMIZED WITH SARGABLE SEEK)
    ---------------------------------------------------------
    CREATE TABLE #UniqueScans
    (
        MobileNo NVARCHAR(50),
        M_Codeid BIGINT,
        Enq_Date DATETIME,
        Pro_ID NVARCHAR(50),
        Series_Order INT,
        Series_Serial INT,
        rn INT
    );

    -- 1. Get Enquiries (Source: Pro_Enq using SARGable Mobile Index Seek)
    INSERT INTO #UniqueScans (MobileNo, M_Codeid, Enq_Date, Pro_ID, Series_Order, Series_Serial, rn)
    SELECT 
        U.MobileNo,
        M.Row_ID AS M_Codeid,
        PE.Enq_Date,
        M.Pro_ID,
        M.Series_Order,
        M.Series_Serial,
        ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2, PE.Is_Success ORDER BY PE.Enq_Date) as rn
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN #UserMobiles UM ON PE.MobileNo = UM.MobileNo
    INNER JOIN #Users U ON UM.M_ConsumerId = U.M_ConsumerId
    INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    WHERE PR.Comp_Id = @Comp_Id
      AND PE.Is_Success = '1'
      AND (@StartDate IS NULL OR PE.Enq_Date >= @StartDate)
      AND (@EndDate IS NULL OR PE.Enq_Date < @EndDate);

    CREATE INDEX IX_UniqueScans_MCodeid ON #UniqueScans(M_Codeid) WHERE rn = 1;
    CREATE INDEX IX_UniqueScans_MobileNo ON #UniqueScans(MobileNo) WHERE rn = 1;

    -- 2. Get Earned Points
    SELECT
        M_Codeid,
        MAX(Points) AS Points
    INTO #EarnedPoints
    FROM (
        SELECT
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK)
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        WHERE BL.compid = @Comp_Id
          AND MC.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)

        UNION ALL

        SELECT
            MC.M_Codeid,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK)
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN M_Code M WITH (NOLOCK) 
            ON MC.M_Codeid = M.Row_ID
        INNER JOIN Pro_Reg PR WITH (NOLOCK) 
            ON M.Pro_ID = PR.Pro_ID
        WHERE BL.compid IS NULL
          AND PR.Comp_ID = @Comp_Id
          AND MC.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)
    ) x
    GROUP BY M_Codeid;

    CREATE CLUSTERED INDEX IX_EarnedPoints_MCodeid ON #EarnedPoints(M_Codeid);

    -- 3. Get Config Points
    SELECT 
        US.M_Codeid,
        MAX(CAST(
            CASE 
                WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                ELSE ISNULL(SST.IsCash, 0) * @Multiplier
            END 
        AS DECIMAL(18,2))) AS ConfigPoints
    INTO #ConfigPoints
    FROM #UniqueScans US
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    WHERE US.rn = 1
      AND SS.Comp_Id = @Comp_Id
      AND ISNULL(SS.IsActive, 1) = 1 AND ISNULL(SS.IsDelete, 0) = 0
      AND ISNULL(SST.IsActive, 1) = 1 AND ISNULL(SST.IsDelete, 0) = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
      AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
      AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
    GROUP BY US.M_Codeid;

    CREATE CLUSTERED INDEX IX_ConfigPoints_MCodeid ON #ConfigPoints(M_Codeid);

    -- 4. Aggregate into #Benefit
    SELECT
        MC.M_ConsumerId,
        SUM(CASE WHEN ISNULL(P.Points, 0) > 0 THEN P.Points ELSE ISNULL(CP.ConfigPoints, 0) END) AS Benefit,
        MAX(E.Enq_Date) AS LastScan
    INTO #Benefit
    FROM #UniqueScans E
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = E.MobileNo AND MC.IsDelete = 0
    LEFT JOIN #EarnedPoints P ON P.M_Codeid = E.M_Codeid
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = E.M_Codeid
    WHERE E.rn = 1
    GROUP BY MC.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_Benefit_ConsumerId ON #Benefit(M_ConsumerId);

    ---------------------------------------------------------
    -- OTHER EARNED POINTS (KYCRewards, InvoiceRewards, etc. from BLoyaltyPointsEarned)
    ---------------------------------------------------------
    SELECT 
        BL.M_Consumerid,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS OtherPoints
    INTO #OtherEarnedPoints
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    WHERE BL.compid = @Comp_Id
      AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND BL.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)
      AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR BL.UpdateDate < @EndDate)
    GROUP BY BL.M_Consumerid;

    CREATE CLUSTERED INDEX IX_OtherEarnedPoints_ConsumerId ON #OtherEarnedPoints(M_Consumerid);

    ---------------------------------------------------------
    -- REFERRAL POINTS
    ---------------------------------------------------------
    SELECT 
        BL.M_Consumerid,
        SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS ReferralPoints
    INTO #Referrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    WHERE BL.compid = @Comp_Id
      AND LOWER(BL.ServiceName) IN ('refral', 'referral')
      AND BL.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)
      AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR BL.UpdateDate < @EndDate)
    GROUP BY BL.M_Consumerid;

    CREATE CLUSTERED INDEX IX_Referrals_ConsumerId ON #Referrals(M_Consumerid);

    ---------------------------------------------------------
    -- CLAIMS / TRANSFERRED & TDS (Optimized with #UserMobiles)
    ---------------------------------------------------------
    SELECT 
        U.M_ConsumerId,
        SUM(TRY_CAST(CD.Amount AS DECIMAL(18,2))) AS Transferred,
        SUM(TRY_CAST(ISNULL(CD.tdsAmount, 0) AS DECIMAL(18,2))) AS TDS
    INTO #Claims
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN #UserMobiles UM ON CD.Mobileno = UM.MobileNo
    INNER JOIN #Users U ON UM.M_ConsumerId = U.M_ConsumerId
    WHERE CD.Comp_id = @Comp_Id
      AND CD.Isapproved = 1 AND CD.PaymentStatus = 'Success'
      AND (@StartDate IS NULL OR CD.Claim_date >= @StartDate)
      AND (@EndDate   IS NULL OR CD.Claim_date < @EndDate)
    GROUP BY U.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_Claims_ConsumerId ON #Claims(M_ConsumerId);

    ---------------------------------------------------------
    -- INSTANT CASH TRANSFERS (UPI Payouts with Codes)
    ---------------------------------------------------------
    SELECT 
        U.M_ConsumerId,
        SUM(TRY_CAST(ISNULL(t.Amount, t.Points_Val) AS DECIMAL(18,2))) AS UPIAmount
    INTO #UPI
    FROM tblUPITransactionDetails t WITH (NOLOCK)
    INNER JOIN #UserMobiles UM ON t.MobileNo = UM.MobileNo
    INNER JOIN #Users U ON UM.M_ConsumerId = U.M_ConsumerId
    WHERE t.Status = 'Success'
      AND t.Comp_Id = @Comp_Id
      AND LEN(ISNULL(t.Code1, '')) > 3
      AND (@StartDate IS NULL OR t.ReqDate >= @StartDate)
      AND (@EndDate   IS NULL OR t.ReqDate < @EndDate)
    GROUP BY U.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_UPI_ConsumerId ON #UPI(M_ConsumerId);

    ---------------------------------------------------------
    -- BPOINTS DEBITS (Gifts, Reversals, Manual Adjustments)
    ---------------------------------------------------------
    SELECT 
        BT.RedeemBy AS M_ConsumerId,
        SUM(TRY_CAST(ISNULL(BT.RedeemPoints, 0) AS DECIMAL(18,2))) AS BPointsDebited
    INTO #BPoints
    FROM BPointsTransaction BT WITH (NOLOCK)
    WHERE BT.companyid = @Comp_Id
      AND BT.bpstatus IN ('Accepted', 'SUCCESS', 'Debit')
      AND BT.RedeemBy IN (SELECT M_ConsumerId FROM #Users)
      AND (@StartDate IS NULL OR BT.Redeemdate >= @StartDate)
      AND (@EndDate   IS NULL OR BT.Redeemdate < @EndDate)
    GROUP BY BT.RedeemBy;

    CREATE CLUSTERED INDEX IX_BPoints_ConsumerId ON #BPoints(M_ConsumerId);

    ---------------------------------------------------------
    -- TRANSACTIONS (Wallet / Direct Cash Payouts)
    ---------------------------------------------------------
    SELECT 
        TRY_CAST(t.M_CounserID AS INT) AS M_ConsumerId,
        SUM(TRY_CAST(ISNULL(t.Amount, 0) AS DECIMAL(18,2))) AS TransactionsAmount
    INTO #Transactions
    FROM Transactions t WITH (NOLOCK)
    WHERE (t.CompId = REPLACE(@Comp_Id, 'Comp-', '') OR t.CompId = @Comp_Id)
      AND t.Issuccess = 1
      AND (@StartDate IS NULL OR t.TransactionDate >= @StartDate)
      AND (@EndDate   IS NULL OR t.TransactionDate <  @EndDate)
      AND TRY_CAST(t.M_CounserID AS INT) IN (SELECT M_ConsumerId FROM #Users)
    GROUP BY TRY_CAST(t.M_CounserID AS INT);

    CREATE CLUSTERED INDEX IX_Transactions_ConsumerId ON #Transactions(M_ConsumerId);

    ---------------------------------------------------------
    -- FINAL DATASET PREPARATION (Matching BeneficiariesReportModel DTO)
    ---------------------------------------------------------
    SELECT 
        U.ConsumerName,
        U.MobileNo,
        COALESCE(S.State, U.State) AS State,
        COALESCE(S.City, U.City) AS City,
        U.PinCode,
        U.KYCStatus,
        (ISNULL(B.Benefit, 0) + ISNULL(O.OtherPoints, 0)) AS PointsEarned,
        ISNULL(R.ReferralPoints, 0) AS RefralAmount,
        (ISNULL(C.Transferred, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsDebited, 0) + ISNULL(T.TransactionsAmount, 0)) AS RedeemAmount,
        ((ISNULL(B.Benefit, 0) + ISNULL(O.OtherPoints, 0) + ISNULL(R.ReferralPoints, 0)) - (ISNULL(C.Transferred, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsDebited, 0) + ISNULL(T.TransactionsAmount, 0))) AS BalanceAmount,
        ISNULL(C.TDS, 0) AS TDSAmount,
        B.LastScan,
        ROW_NUMBER() OVER (ORDER BY (ISNULL(B.Benefit, 0) + ISNULL(O.OtherPoints, 0)) DESC, U.M_ConsumerId) AS RN
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State S ON S.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Benefit B ON B.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #OtherEarnedPoints O ON O.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Referrals R ON R.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Claims C ON C.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #UPI UPI ON UPI.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #BPoints BP ON BP.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Transactions T ON T.M_ConsumerId = U.M_ConsumerId
    WHERE (
            (ISNULL(B.Benefit, 0) > 0 OR ISNULL(R.ReferralPoints, 0) > 0 OR ISNULL(O.OtherPoints, 0) > 0)
            OR
            ((ISNULL(B.Benefit, 0) + ISNULL(O.OtherPoints, 0) + ISNULL(R.ReferralPoints, 0)) - (ISNULL(C.Transferred, 0) + ISNULL(UPI.UPIAmount, 0) + ISNULL(BP.BPointsDebited, 0) + ISNULL(T.TransactionsAmount, 0)) <> 0)
          )
      AND (@KYCStatusFilter IS NULL OR U.KYCStatus = @KYCStatusFilter)
      AND (@StateFilter IS NULL OR S.State = @StateFilter OR (S.State IS NULL AND U.State = @StateFilter))
      AND (
          @Search IS NULL 
          OR LTRIM(RTRIM(@Search)) = ''
          OR U.ConsumerName LIKE '%' + @Search + '%'
          OR U.MobileNo LIKE '%' + @Search + '%'
          OR S.State LIKE '%' + @Search + '%'
          OR S.City LIKE '%' + @Search + '%'
      );

    ---------------------------------------------------------
    -- OUTPUT
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN 
        SELECT 
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RefralAmount,
            RedeemAmount,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        ORDER BY RN;
    END
    ELSE
    BEGIN
        SELECT 
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RefralAmount,
            RedeemAmount,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        WHERE RN BETWEEN @Offset + 1 AND (@Offset + @Limit)
        ORDER BY RN;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
