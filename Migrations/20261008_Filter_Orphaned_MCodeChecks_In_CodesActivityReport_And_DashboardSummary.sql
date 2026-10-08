-- Migration Script: Filter Orphaned MCode Checks (M_Consumer_MCOdeid <= 0) and Already-Scanned Codes from Section 3 of SP_BL_GetCodesActivityReport_AI and Section 4b of USP_GetDashboardSummary_AI
-- Date: 2026-10-08
-- Target DB: Production (Vcqru)
-- Description:
--   Prevents orphaned/corrupt code check entries (where BuiltLoyaltyMCodeCheck.M_Consumer_MCOdeid = 0)
--   from appearing as phantom extra rows with empty UniqueCode and 'SRV1001 Point' in SP_BL_GetCodesActivityReport_AI and USP_GetDashboardSummary_AI.

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetCodesActivityReport_AI]    Script Date: 9/17/2026 7:17:07 PM ******/
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
     @StateFilter NVARCHAR(100) = NULL,       -- Ã¢Å“â€¦ NEW
    @DialModeFilter NVARCHAR(50) = NULL,     -- Ã¢Å“â€¦ NEW
    @Page INT = NULL,                        -- Ã¢Å“â€¦ NEW
    @Limit INT = NULL,                      -- Ã¢Å“â€¦ NEW
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
    -- ENQUIRIES (TWO-PASS CODE SEARCH TO PRESERVE TRUE GLOBAL SCAN ORDER)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#SearchedCodes') IS NOT NULL DROP TABLE #SearchedCodes;
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
        END AS WornPoint,
        MAX(ServiceName) AS ServiceName
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
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10  -- old records: Points + 10%
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))             -- new records: Points as-is
                                END
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
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10  -- old records: Points + 10%
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))             -- new records: Points as-is
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint,
            ISNULL(MS.ServiceName, BL.ServiceName) AS ServiceName
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN #MCode M WITH (NOLOCK)
            ON MC.M_Codeid = M.M_Codeid
        LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK)
            ON SST.SST_Id = BL.SST_id
        LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK)
            ON SS.Subscribe_Id = SST.Subscribe_Id
        LEFT JOIN dbo.M_Service MS WITH (NOLOCK)
            ON MS.Service_ID = SS.Service_ID
        LEFT JOIN M_Consumer Cons WITH (NOLOCK)
            ON BL.M_Consumerid = Cons.M_Consumerid
        WHERE BL.compid = @Comp_Id

        UNION ALL

        SELECT
            MC.M_Codeid,
            Cons.MobileNo,
            CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @Comp_Id = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10  -- old records: Points + 10%
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))             -- new records: Points as-is
                                END
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
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10  -- old records: Points + 10%
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))             -- new records: Points as-is
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint,
            ISNULL(MS.ServiceName, BL.ServiceName) AS ServiceName
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN #MCode M WITH (NOLOCK) 
            ON MC.M_Codeid = M.M_Codeid
        INNER JOIN Pro_Reg PR WITH (NOLOCK) 
            ON M.Pro_ID = PR.Pro_ID
        LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK)
            ON SST.SST_Id = BL.SST_id
        LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK)
            ON SS.Subscribe_Id = SST.Subscribe_Id
        LEFT JOIN dbo.M_Service MS WITH (NOLOCK)
            ON MS.Service_ID = SS.Service_ID
        LEFT JOIN M_Consumer Cons WITH (NOLOCK)
            ON BL.M_Consumerid = Cons.M_Consumerid
        WHERE BL.compid IS NULL
          AND PR.Comp_ID = @Comp_Id
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
        TotalFrequency INT,
        ServiceName NVARCHAR(200)
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
                S.ServiceName AS ServiceName,
                ROW_NUMBER() OVER (
                    PARTITION BY MC.M_Codeid 
                    ORDER BY CASE WHEN SS.Service_ID = 'SRV1001' THEN 1 WHEN SS.Service_ID = 'SRV1005' THEN 2 ELSE 3 END,
                             SST.SST_Id DESC
                ) AS rn
            FROM #MCode MC
            INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
            INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
            LEFT JOIN dbo.M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
            WHERE SS.Comp_ID = 'Comp-1669'
              AND SS.IsActive = 1 AND SS.IsDelete = 0
              AND SST.IsActive = 1 AND SST.IsDelete = 0
              AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
              AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
              AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        )
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency, ServiceName)
        SELECT 
            M_Codeid,
            Frequency,
            ConfigPoints,
            AssignPoint,
            1 AS TotalFrequency,
            ServiceName
        FROM ConfigRanked
        WHERE rn = 1;
    END
    ELSE
    BEGIN
        -- STANDARD LOGIC FOR ALL OTHER COMPANIES (100% UNTOUCHED)
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency, ServiceName)
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
            SUM(ISNULL(SST.Frequency, 1)) AS TotalFrequency,
            MAX(S.ServiceName) AS ServiceName
        FROM #MCode MC
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        LEFT JOIN dbo.M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
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
            THEN CONCAT(
                ISNULL(MCd.Pro_ID, PR.Pro_ID), '-', 
                CASE WHEN LEN(CAST(MCd.Series_Order AS VARCHAR(20))) < 4 THEN RIGHT('0000' + CAST(MCd.Series_Order AS VARCHAR(20)), 4) ELSE CAST(MCd.Series_Order AS VARCHAR(20)) END, '-', 
                CASE WHEN LEN(CAST(MCd.Series_Serial AS VARCHAR(20))) < 4 THEN RIGHT('0000' + CAST(MCd.Series_Serial AS VARCHAR(20)), 4) ELSE CAST(MCd.Series_Serial AS VARCHAR(20)) END
            )
            WHEN E.Series_Order IS NOT NULL AND E.Series_Serial IS NOT NULL
            THEN CONCAT(
                ISNULL(MCd.Pro_ID, PR.Pro_ID), '-', 
                CASE WHEN LEN(CAST(E.Series_Order AS VARCHAR(20))) < 4 THEN RIGHT('0000' + CAST(E.Series_Order AS VARCHAR(20)), 4) ELSE CAST(E.Series_Order AS VARCHAR(20)) END, '-', 
                CASE WHEN LEN(CAST(E.Series_Serial AS VARCHAR(20))) < 4 THEN RIGHT('0000' + CAST(E.Series_Serial AS VARCHAR(20)), 4) ELSE CAST(E.Series_Serial AS VARCHAR(20)) END
            )
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
            WHEN E.Is_Success = 1 AND (E.rn_user = 1 AND (ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) THEN 
                ISNULL(P.Points, 0)
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
                CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(P.Points, 0)
                    WHEN ISNULL(P.Points, 0) > 0 THEN P.Points 
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS Points,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn_user = 1 AND (ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) THEN 'Verified'
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 'Verified'
            WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1)) THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
			E.Latitude,
			E.Longitude,
        CASE 
            WHEN E.Is_Success = 1 THEN 
                CASE 
                    WHEN ISNULL(CP.AssignPoint, 0) > 0 THEN CP.AssignPoint
                    WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint
                    ELSE ISNULL(CP.ConfigPoints, 0)
                END
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn_user = 1 AND (ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) THEN 
                ISNULL(P.WornPoint, 0)
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
			SELECT E_sub.*,
				   CASE 
					   WHEN E_sub.Is_Success = 1 
					   THEN ROW_NUMBER() OVER (
                           PARTITION BY E_sub.Received_Code1, E_sub.Received_Code2, E_sub.Is_Success 
                           ORDER BY 
                               CASE WHEN MC_sub.IsActive = 0 THEN 2 ELSE 1 END,
                               E_sub.Enq_Date ASC
                       )
					   ELSE 1
				   END AS rn,
				   CASE 
					   WHEN E_sub.Is_Success = 1 
					   THEN ROW_NUMBER() OVER (
                           PARTITION BY E_sub.Received_Code1, E_sub.Received_Code2, 
                                        CASE WHEN LEN(E_sub.MobileNo) >= 10 THEN RIGHT(E_sub.MobileNo, 10) ELSE E_sub.MobileNo END, 
                                        E_sub.Is_Success 
                           ORDER BY E_sub.Enq_Date ASC
                       )
					   ELSE 1
				   END AS rn_user
			FROM #Enq E_sub
            LEFT JOIN M_Consumer MC_sub WITH (NOLOCK) 
                ON (MC_sub.MobileNo = E_sub.MobileNo OR (LEN(E_sub.MobileNo) >= 10 AND RIGHT(MC_sub.MobileNo, 10) = RIGHT(E_sub.MobileNo, 10))) 
               AND MC_sub.IsDelete = 0
		) E
        LEFT JOIN M_Consumer MC ON (MC.MobileNo = E.MobileNo OR (LEN(E.MobileNo) >= 10 AND RIGHT(MC.MobileNo, 10) = RIGHT(E.MobileNo, 10))) AND MC.IsDelete = '0'
        LEFT JOIN tbl_Vendorvisekycstatus cc ON mc.M_Consumerid = cc.M_consumerId AND cc.comp_id = @comp_id
        LEFT JOIN #Geo G ON G.Code1 = E.Received_Code1 AND G.Code2 = E.Received_Code2 AND G.MobileNo = E.MobileNo
        LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid AND (P.MobileNo = E.MobileNo OR '91' + P.MobileNo = E.MobileNo OR P.MobileNo = '91' + E.MobileNo OR (LEN(P.MobileNo) >= 10 AND LEN(E.MobileNo) >= 10 AND RIGHT(P.MobileNo, 10) = RIGHT(E.MobileNo, 10)) OR P.MobileNo IS NULL)
        LEFT JOIN #MCode MCd ON MCd.M_Codeid = E.M_Codeid
        LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
        LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid
        LEFT JOIN #ScanReferrals R ON R.Code1 = E.Received_Code1 AND R.Code2 = E.Received_Code2
        WHERE (cc.comp_id = @comp_id OR cc.comp_id IS NULL)
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
            THEN CONCAT(
                ISNULL(C.Pro_ID, PR.Pro_ID), '-', 
                CASE WHEN LEN(CAST(C.Series_Order AS VARCHAR(20))) < 4 THEN RIGHT('0000' + CAST(C.Series_Order AS VARCHAR(20)), 4) ELSE CAST(C.Series_Order AS VARCHAR(20)) END, '-', 
                CASE WHEN LEN(CAST(C.Series_Serial AS VARCHAR(20))) < 4 THEN RIGHT('0000' + CAST(C.Series_Serial AS VARCHAR(20)), 4) ELSE CAST(C.Series_Serial AS VARCHAR(20)) END
            )
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
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                    THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10  -- old records: Points + 10%
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))             -- new records: Points as-is
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
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                    THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10  -- old records: Points + 10%
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))             -- new records: Points as-is
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
    WHERE (BL.compid = @Comp_Id OR (@Comp_Id = 'Comp-1669' AND BL.compid IS NULL AND PR.Pro_ID IS NOT NULL))
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND (
          BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          OR (
              ISNULL(BMC.M_Consumer_MCOdeid, 0) > 0 
              AND MCMC.M_Codeid IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1 FROM #Enq E 
                  WHERE (E.M_Codeid = MCMC.M_Codeid OR (BL.Code1 IS NOT NULL AND E.Received_Code1 = BL.Code1 AND E.Received_Code2 = BL.Code2))
                    AND (E.MobileNo = MC.MobileNo OR '91' + E.MobileNo = MC.MobileNo OR E.MobileNo = '91' + MC.MobileNo)
              )
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
USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetDashboardSummary_AI]    Script Date: 10/7/2026 11:04:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_GetDashboardSummary_AI]
(
    @M_Consumerid INT,
    @CompID VARCHAR(50),
    @OverallStatsOnly BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON; 

    DECLARE @MobileNo VARCHAR(20)
    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_Consumerid AND IsDelete = 0;

    IF @MobileNo IS NULL RETURN;

    -- Flag for service-wise gifts presence
    DECLARE @HasServiceWiseGifts BIT = 0;
    IF EXISTS (SELECT 1 FROM Claim_gift WHERE CompID = @CompID AND Service_id IS NOT NULL AND Isdelete = 0)
    BEGIN
        SET @HasServiceWiseGifts = 1;
    END

    ---------------------------------------------------------
    -- COMPANY FILTER PREPARATION
    ---------------------------------------------------------
    DECLARE @CompanyList TABLE (Comp_Id VARCHAR(50) PRIMARY KEY);
    INSERT INTO @CompanyList VALUES (@CompID);

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation 
    WHERE comp_id = @CompID AND isactive = 1 AND isdelete = 0;

    ---------------------------------------------------------
    -- 1. ENQUIRIES (ALL SCANS FOR THIS USER & COMPANY)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

    SELECT 
        PE.Received_Code1,
        PE.Received_Code2,
        PE.Enq_Date,
        PE.Dial_Mode,
        PE.Is_Success,
        PE.MobileNo,
        M.Row_ID AS M_Codeid,
        M.Series_Order,
        M.Series_Serial,
        M.Pro_ID
    INTO #Enq
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN M_code M WITH (NOLOCK) 
        ON PE.Received_Code1 = CAST(M.code1 AS VARCHAR(50))
       AND PE.Received_Code2 = CAST(M.Code2 AS VARCHAR(50))
    INNER JOIN Pro_Reg PR WITH (NOLOCK)
       ON PR.Pro_ID = M.Pro_ID
    WHERE PR.Comp_ID = @CompID
      AND RIGHT(PE.MobileNo, 10) = RIGHT(@MobileNo, 10);

    -- Rank scans identically to SP_BL_GetCodesActivityReport_AI
    IF OBJECT_ID('tempdb..#RankedScans') IS NOT NULL DROP TABLE #RankedScans;

    SELECT E_sub.*,
           CASE 
               WHEN E_sub.Is_Success = 1 
               THEN ROW_NUMBER() OVER (
                   PARTITION BY E_sub.Received_Code1, E_sub.Received_Code2, E_sub.Is_Success 
                   ORDER BY 
                       CASE WHEN MC_sub.IsActive = 0 THEN 2 ELSE 1 END,
                       E_sub.Enq_Date ASC
               )
               ELSE 1
           END AS rn,
           CASE 
               WHEN E_sub.Is_Success = 1 
               THEN ROW_NUMBER() OVER (
                   PARTITION BY E_sub.Received_Code1, E_sub.Received_Code2, 
                                CASE WHEN LEN(E_sub.MobileNo) >= 10 THEN RIGHT(E_sub.MobileNo, 10) ELSE E_sub.MobileNo END, 
                                E_sub.Is_Success 
                   ORDER BY E_sub.Enq_Date ASC
               )
               ELSE 1
           END AS rn_user
    INTO #RankedScans
    FROM #Enq E_sub
    LEFT JOIN M_Consumer MC_sub WITH (NOLOCK) 
        ON (MC_sub.MobileNo = E_sub.MobileNo OR (LEN(E_sub.MobileNo) >= 10 AND RIGHT(MC_sub.MobileNo, 10) = RIGHT(E_sub.MobileNo, 10))) 
       AND MC_sub.IsDelete = 0;

    ---------------------------------------------------------
    -- 2. POINTS FROM BLOYALTYPOINTSEARNED (FOR SCANS)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT
        M_Codeid,
        MobileNo,
        CASE 
            WHEN @CompID = 'Comp-1669' THEN SUM(Points)
            ELSE MAX(Points)
        END AS Points,
        CASE 
            WHEN @CompID = 'Comp-1669' THEN SUM(WornPoint)
            ELSE MAX(WornPoint)
        END AS WornPoint,
        MAX(ServiceName) AS ServiceName,
        MAX(Service_ID) AS Service_ID
    INTO #Points
    FROM (
        SELECT
            MC.M_Codeid,
            Cons.MobileNo,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint,
            ISNULL(MS.ServiceName, BL.ServiceName) AS ServiceName,
            SS.Service_ID
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN (SELECT DISTINCT M_Codeid FROM #Enq) M
            ON MC.M_Codeid = M.M_Codeid
        LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK)
            ON SST.SST_Id = BL.SST_id
        LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK)
            ON SS.Subscribe_Id = SST.Subscribe_Id
        LEFT JOIN dbo.M_Service MS WITH (NOLOCK)
            ON MS.Service_ID = SS.Service_ID
        LEFT JOIN M_Consumer Cons WITH (NOLOCK)
            ON BL.M_Consumerid = Cons.M_Consumerid
        WHERE BL.compid = @CompID

        UNION ALL

        SELECT
            MC.M_Codeid,
            Cons.MobileNo,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint,
            ISNULL(MS.ServiceName, BL.ServiceName) AS ServiceName,
            SS.Service_ID
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN (SELECT DISTINCT M_Codeid, Pro_ID FROM #Enq) M 
            ON MC.M_Codeid = M.M_Codeid
        INNER JOIN Pro_Reg PR WITH (NOLOCK) 
            ON M.Pro_ID = PR.Pro_ID
        LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK)
            ON SST.SST_Id = BL.SST_id
        LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK)
            ON SS.Subscribe_Id = SST.Subscribe_Id
        LEFT JOIN dbo.M_Service MS WITH (NOLOCK)
            ON MS.Service_ID = SS.Service_ID
        LEFT JOIN M_Consumer Cons WITH (NOLOCK)
            ON BL.M_Consumerid = Cons.M_Consumerid
        WHERE BL.compid IS NULL
          AND PR.Comp_ID = @CompID
    ) x
    GROUP BY M_Codeid, MobileNo;

    ---------------------------------------------------------
    -- 3. CONFIG POINTS (SUBSCRIPTIONS)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;
    CREATE TABLE #CodeConfigPoints (
        M_Codeid BIGINT,
        Frequency INT,
        ConfigPoints DECIMAL(18,2),
        AssignPoint DECIMAL(18,2),
        TotalFrequency INT,
        ServiceName NVARCHAR(200),
        Service_ID VARCHAR(50),
        ConfigCash DECIMAL(18,2)
    );

    IF @CompID = 'Comp-1669'
    BEGIN
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
                S.ServiceName AS ServiceName,
                SS.Service_ID,
                CAST(0.00 AS DECIMAL(18,2)) AS ConfigCash,
                ROW_NUMBER() OVER (
                    PARTITION BY MC.M_Codeid 
                    ORDER BY CASE WHEN SS.Service_ID = 'SRV1001' THEN 1 WHEN SS.Service_ID = 'SRV1005' THEN 2 ELSE 3 END,
                             SST.SST_Id DESC
                ) AS rn
            FROM (SELECT DISTINCT M_Codeid, Pro_ID, Series_Order, Series_Serial FROM #Enq) MC
            INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
            INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
            LEFT JOIN dbo.M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
            WHERE SS.Comp_ID = 'Comp-1669'
              AND SS.IsActive = 1 AND SS.IsDelete = 0
              AND SST.IsActive = 1 AND SST.IsDelete = 0
              AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
              AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
              AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        )
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency, ServiceName, Service_ID, ConfigCash)
        SELECT 
            M_Codeid, Frequency, ConfigPoints, AssignPoint, 1 AS TotalFrequency, ServiceName, Service_ID, ConfigCash
        FROM ConfigRanked
        WHERE rn = 1;
    END
    ELSE
    BEGIN
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency, ServiceName, Service_ID, ConfigCash)
        SELECT 
            MC.M_Codeid,
            MAX(ISNULL(SST.Frequency, 1)) AS Frequency,
            MAX(CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                    ELSE ISNULL(SST.IsCash, 0) * @Multiplier
                END 
            AS DECIMAL(18,2))) AS ConfigPoints,
            MAX(CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                    ELSE ISNULL(SST.IsCash, 0)
                END 
            AS DECIMAL(18,2))) AS AssignPoint,
            SUM(ISNULL(SST.Frequency, 1)) AS TotalFrequency,
            MAX(S.ServiceName) AS ServiceName,
            MAX(SS.Service_ID) AS Service_ID,
            MAX(CAST(ISNULL(SST.IsCash, 0) AS DECIMAL(18,2))) AS ConfigCash
        FROM (SELECT DISTINCT M_Codeid, Pro_ID, Series_Order, Series_Serial FROM #Enq) MC
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        LEFT JOIN dbo.M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
        WHERE SS.Comp_ID = @CompID 
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
          AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
          AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        GROUP BY MC.M_Codeid;
    END

    ---------------------------------------------------------
    -- 4. AGGREGATE SCAN & NON-SCAN EARNED ITEMS (SERVICE-WISE)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#AllEarnedItems') IS NOT NULL DROP TABLE #AllEarnedItems;

    CREATE TABLE #AllEarnedItems (
        Service_ID VARCHAR(50),
        Points DECIMAL(18,2),
        Cash DECIMAL(18,2),
        IsVerified BIT
    );

    -- 4a. Scan Items
    INSERT INTO #AllEarnedItems (Service_ID, Points, Cash, IsVerified)
    SELECT 
        COALESCE(P.Service_ID, CP.Service_ID, 'SRV1001') AS Service_ID,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn_user = 1 AND (ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) THEN 
                ISNULL(P.WornPoint, 0)
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
                CASE 
                    WHEN @CompID = 'Comp-1669' THEN ISNULL(P.WornPoint, 0)
                    WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint 
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS Points,
        CASE 
            WHEN @CompID = 'Comp-1669' THEN 0.00
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN ISNULL(CP.ConfigCash, 0)
            ELSE 0.00
        END AS Cash,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn_user = 1 AND (ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) THEN 1
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 1
            ELSE 0
        END AS IsVerified
    FROM #RankedScans E
    LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid AND (P.MobileNo = E.MobileNo OR '91' + P.MobileNo = E.MobileNo OR P.MobileNo = '91' + E.MobileNo OR (LEN(P.MobileNo) >= 10 AND LEN(E.MobileNo) >= 10 AND RIGHT(P.MobileNo, 10) = RIGHT(E.MobileNo, 10)) OR P.MobileNo IS NULL)
    LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid;

    -- 4b. Extra/Non-Scan Earned Items (Bonus, KYC, Repair, Invoice, etc. matching Section 3 of CodesActivityReport)
    INSERT INTO #AllEarnedItems (Service_ID, Points, Cash, IsVerified)
    SELECT 
        ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
        CAST(
            CASE 
                WHEN @CompID = 'Comp-1669' THEN
                    CASE
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                            CASE 
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                    THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                            END
                        WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                            CASE 
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                    THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            END
                        ELSE 0.00
                    END
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2)) AS Points,
        CAST(
            CASE 
                WHEN @CompID = 'Comp-1669' THEN 0.00
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE 0.00
            END 
        AS DECIMAL(18,2)) AS Cash,
        1 AS IsVerified
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    LEFT JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    LEFT JOIN M_Consumer_M_Code MCMC ON BMC.M_Consumer_MCOdeid = MCMC.M_Consumer_MCodeid
    LEFT JOIN M_Code C ON MCMC.M_Codeid = C.Row_ID
    LEFT JOIN Pro_Reg PR ON C.Pro_ID = PR.Pro_ID
    LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.SST_Id = BL.SST_id
    LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) ON SS.Subscribe_Id = SST.Subscribe_Id
    WHERE (BL.compid = @CompID OR (@CompID = 'Comp-1669' AND BL.compid IS NULL AND PR.Pro_ID IS NOT NULL))
      AND RIGHT(MC.MobileNo, 10) = RIGHT(@MobileNo, 10)
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND (
          BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          OR (
              ISNULL(BMC.M_Consumer_MCOdeid, 0) > 0 
              AND MCMC.M_Codeid IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1 FROM #Enq E 
                  WHERE (E.M_Codeid = MCMC.M_Codeid OR (BL.Code1 IS NOT NULL AND E.Received_Code1 = BL.Code1 AND E.Received_Code2 = BL.Code2))
                    AND (E.MobileNo = MC.MobileNo OR '91' + E.MobileNo = MC.MobileNo OR E.MobileNo = '91' + MC.MobileNo)
              )
          )
      );

    IF OBJECT_ID('tempdb..#ConfiguredPoints') IS NOT NULL DROP TABLE #ConfiguredPoints;

    SELECT 
        Service_ID,
        SUM(Points) AS ServiceTotalPoints,
        SUM(Cash) AS ServiceTotalCash
    INTO #ConfiguredPoints
    FROM #AllEarnedItems
    GROUP BY Service_ID;

    DECLARE @TotalConfigPoints DECIMAL(18,2) = 0;
    DECLARE @TotalConfigCash DECIMAL(18,2) = 0;

    SELECT 
        @TotalConfigPoints = ISNULL(SUM(ServiceTotalPoints), 0),
        @TotalConfigCash = ISNULL(SUM(ServiceTotalCash), 0)
    FROM #ConfiguredPoints;

    ---------------------------------------------------------
    -- 5. REFERRAL STATS
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#ReferralStats') IS NOT NULL DROP TABLE #ReferralStats;

    SELECT 
        ISNULL(SUM(CAST(
            CASE 
                WHEN LOWER(@CompID) = 'comp-1669' THEN ISNULL(BL.Points, 0) + ISNULL(BL.Cash, 0)
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
            END
        AS DECIMAL(18,2))), 0) as RefPoints,
        ISNULL(SUM(CAST(
            CASE 
                WHEN LOWER(@CompID) = 'comp-1669' THEN ISNULL(BL.Points, 0) + ISNULL(BL.Cash, 0)
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                ELSE 0.00
            END
        AS DECIMAL(18,2))), 0) as RefCash
    INTO #ReferralStats
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON (BL.compid = CL.Comp_Id OR (ISNULL(BL.compid, '') = '' AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL))
    WHERE (
          BL.M_Consumerid = @M_Consumerid 
          OR BL.M_Consumerid IN (
              SELECT M_Consumerid 
              FROM M_Consumer WITH (NOLOCK) 
              WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
          )
      )
      AND (
          LOWER(ISNULL(BL.ServiceName, '')) IN ('refral', 'referral')
      );

    ---------------------------------------------------------
    -- 6. REDEMPTIONS & CODE COUNTS
    ---------------------------------------------------------
    DECLARE @BPointsAmount DECIMAL(18,2) = 0;
    SELECT @BPointsAmount = ISNULL(SUM(ISNULL(RedeemPoints, 0)), 0)
    FROM BPointsTransaction WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON companyid = CL.Comp_Id
    WHERE bpstatus IN ('Accepted', 'SUCCESS')
      AND RedeemBy = @M_Consumerid
      AND (@CompID <> 'Comp-1669' OR Redeemdate >= '2026-09-08 17:27:20.650');

    DECLARE @TransactionsAmount DECIMAL(18,2) = 0;
    SELECT @TransactionsAmount = ISNULL(SUM(ISNULL(CAST(Amount AS DECIMAL(18,2)), 0)), 0)
    FROM Transactions WITH (NOLOCK)
    WHERE CompId = REPLACE(@CompID, 'Comp-', '')
      AND IsSuccess = 1
      AND M_CounserID = CAST(@M_Consumerid AS VARCHAR(50))
      AND (
        @CompID <> 'Comp-1152'
        OR TransactionDate > '2022-11-25'
      )
      AND (@CompID <> 'Comp-1669' OR TransactionDate >= '2026-09-08 17:27:20.650');

    DECLARE @UPIAmount DECIMAL(18,2) = 0;
    SELECT @UPIAmount = ISNULL(SUM(ISNULL(Amount, 0)), 0)
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @CompID
      AND Status = 'Success'
      AND LEN(Code1) > 3
      AND M_Consumerid = CAST(@M_Consumerid AS VARCHAR(50))
      AND (@CompID <> 'Comp-1669' OR ReqDate >= '2026-09-08 17:27:20.650');

    DECLARE @ClaimsAmount DECIMAL(18,2) = 0;
    SELECT @ClaimsAmount = ISNULL(SUM(CASE WHEN ISNULL(Amount, 0) > 0 THEN Amount ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue), 0) END), 0)
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON CD.Comp_id = CL.Comp_Id
    WHERE Isapproved <> 2
      AND RIGHT(CD.Mobileno, 10) = RIGHT(@MobileNo, 10)
      and @CompID = cl.comp_id AND ( @CompID <> 'Comp-1669' or  (@CompID = 'Comp-1669' and CD.Claim_date >= '2026-09-08 17:27:20.650'));

    DECLARE @PaytmAmount DECIMAL(18,2) = 0;
    SELECT @PaytmAmount = ISNULL(SUM(ISNULL(CAST(Amount AS DECIMAL(18,2)), 0)), 0)
    FROM paytmtransaction PT WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON PT.compId = CL.Comp_Id
    WHERE PT.pstatus IN ('ACCEPTED', '1', 'Success', 'SUCCESS')
      AND (
          PT.M_consumerid = CAST(@M_Consumerid AS VARCHAR(50)) 
          OR PT.M_consumerid IN (
              SELECT CAST(M_Consumerid AS VARCHAR(50))
              FROM M_Consumer WITH (NOLOCK) 
              WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
          )
          OR RIGHT(PT.mobileno, 10) = RIGHT(@MobileNo, 10)
      );

    DECLARE @RedeemAmount DECIMAL(18,2) = 0;
    IF LOWER(@CompID) = 'comp-1669'
    BEGIN
        DECLARE @Comp1669Paytm DECIMAL(18,2) = 0;
        SELECT @Comp1669Paytm = ISNULL(SUM(TRY_CAST(ISNULL(pt.Amount, 0) AS DECIMAL(18,2))), 0)
        FROM paytmtransaction pt WITH (NOLOCK)
        WHERE LOWER(pt.compId) = 'comp-1669'
          AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
          AND (
              pt.M_consumerid = CAST(@M_Consumerid AS VARCHAR(50)) 
              OR pt.M_consumerid IN (
                  SELECT CAST(M_Consumerid AS VARCHAR(50))
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
              )
              OR RIGHT(pt.mobileno, 10) = RIGHT(@MobileNo, 10)
          );

        DECLARE @Comp1669UPI DECIMAL(18,2) = 0;
        SELECT @Comp1669UPI = ISNULL(SUM(TRY_CAST(ISNULL(t.Amount, t.Points_Val) AS DECIMAL(18,2))), 0)
        FROM tblUPITransactionDetails t WITH (NOLOCK)
        WHERE LOWER(t.Comp_Id) = 'comp-1669'
          AND t.Status = 'Success'
          AND (
              t.M_Consumerid = CAST(@M_Consumerid AS VARCHAR(50)) 
              OR t.M_Consumerid IN (
                  SELECT CAST(M_Consumerid AS VARCHAR(50))
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
              )
          );

        SET @RedeemAmount = @Comp1669Paytm + @Comp1669UPI;
    END
    ELSE
    BEGIN
        SET @RedeemAmount = @BPointsAmount + @TransactionsAmount + @UPIAmount + @ClaimsAmount;
    END

    -- Calculate precise counts
    DECLARE @SuccessCodeCount INT = 0;
    SELECT @SuccessCodeCount = COUNT(*)
    FROM #AllEarnedItems
    WHERE IsVerified = 1;

    DECLARE @UnsuccessCodeCount INT = 0;
    SELECT @UnsuccessCodeCount = COUNT(pe.Received_Code1)
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_code M WITH (NOLOCK) ON pe.Received_Code1 = M.Code1 AND pe.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    WHERE RIGHT(pe.MobileNo, 10) = RIGHT(@MobileNo, 10)
      AND PR.Comp_ID = @CompID
      AND pe.Is_Success = '2';

    DECLARE @InvalidCodeCount INT = 0;
    SELECT @InvalidCodeCount = COUNT(pe.Received_Code1)
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_code M WITH (NOLOCK) ON pe.Received_Code1 = M.Code1 AND pe.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    WHERE RIGHT(pe.MobileNo, 10) = RIGHT(@MobileNo, 10)
      AND PR.Comp_ID = @CompID
      AND pe.Is_Success NOT IN ('1', '2');

    DECLARE @Comp1669TotalPoints DECIMAL(18,2) = 0;
    IF LOWER(@CompID) = 'comp-1669'
    BEGIN
        DECLARE @Comp1669PointsEarnedSum DECIMAL(18,2) = 0;
        DECLARE @Comp1669RefSum DECIMAL(18,2) = 0;

        SELECT 
            @Comp1669PointsEarnedSum = ISNULL(SUM(CAST(
                CASE 
                    WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                            ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                            ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                        END
                    ELSE 0.00
                END
            AS DECIMAL(18,2))), 0.00)
        FROM (
            SELECT BL.M_Consumerid, BL.Points, BL.Cash, BL.UpdateDate, BL.ServiceName
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
            WHERE LOWER(BL.compid) = 'comp-1669'
              AND (BL.M_Consumerid = @M_Consumerid OR BL.M_Consumerid IN (
                  SELECT M_Consumerid 
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
              ))

            UNION ALL

            SELECT BL.M_Consumerid, BL.Points, BL.Cash, BL.UpdateDate, BL.ServiceName
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
              AND PR.Comp_ID = 'Comp-1669'
              AND (BL.M_Consumerid = @M_Consumerid OR BL.M_Consumerid IN (
                  SELECT M_Consumerid 
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
              ))
        ) BL
        WHERE LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral');

        SELECT 
            @Comp1669RefSum = ISNULL(SUM(ISNULL(BL.Points, 0) + ISNULL(BL.Cash, 0)), 0)
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        WHERE LOWER(BL.compid) = 'comp-1669'
          AND (BL.M_Consumerid = @M_Consumerid OR BL.M_Consumerid IN (
              SELECT M_Consumerid 
              FROM M_Consumer WITH (NOLOCK) 
              WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
          ))
          AND LOWER(ISNULL(BL.ServiceName, '')) IN ('refral', 'referral');

        SET @Comp1669TotalPoints = CAST(@Comp1669PointsEarnedSum + @Comp1669RefSum AS DECIMAL(18,2));
    END

    -- Result Set 1: Overall Stats
    SELECT 
        (@SuccessCodeCount + @UnsuccessCodeCount + @InvalidCodeCount) as TotalCode,
        @RedeemAmount as ReedemPoints,
        @SuccessCodeCount as SuccessCode,
        @UnsuccessCodeCount as UnsuccessCode,
        CASE 
            WHEN @CompID = 'Comp-1274' THEN @TotalConfigPoints + (SELECT RefPoints FROM #ReferralStats)
            WHEN @CompID IN ('comp-1152', 'Comp-1152') THEN (SELECT ISNULL(SUM(TRY_CAST(cash AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) and Enq_Date >='2022-08-04 00:00:00.000' and Is_Success=1 )
            WHEN LOWER(@CompID) = 'comp-1669' THEN @Comp1669TotalPoints
            ELSE @TotalConfigCash + (SELECT RefCash FROM #ReferralStats)
        END as TotalCash,
        CASE 
            WHEN @CompID IN ('comp-1152', 'Comp-1152') THEN (SELECT ISNULL(SUM(TRY_CAST(points AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) and Enq_Date >='2022-08-04 00:00:00.000' and Is_Success=1 )
            WHEN LOWER(@CompID) = 'comp-1669' THEN @Comp1669TotalPoints
            ELSE @TotalConfigPoints + (SELECT RefPoints FROM #ReferralStats)
        END as TotalPoints,
        @HasServiceWiseGifts as HasServiceWiseGifts,
        @InvalidCodeCount as InvalidCode;

    IF @OverallStatsOnly = 1
    BEGIN
        DROP TABLE IF EXISTS #Enq;
        DROP TABLE IF EXISTS #RankedScans;
        DROP TABLE IF EXISTS #Points;
        DROP TABLE IF EXISTS #CodeConfigPoints;
        DROP TABLE IF EXISTS #AllEarnedItems;
        DROP TABLE IF EXISTS #ConfiguredPoints;
        DROP TABLE IF EXISTS #ReferralStats;
        RETURN;
    END

    -- Result Set 2: Service-Wise Stats
    DECLARE @ServiceWiseList NVARCHAR(MAX);
    SELECT TOP 1 @ServiceWiseList = ServiceWiseList FROM Comp_Reg WITH (NOLOCK) WHERE Comp_ID = @CompID;

    SELECT 
        ms.Service_ID,
        ms_name.ServiceName,
        ISNULL(cp.ServiceTotalPoints, 0) as ServiceTotalPoints,
        ISNULL(cp.ServiceTotalCash, 0) as ServiceTotalCash
    FROM (SELECT DISTINCT Service_ID, Comp_ID FROM M_ServiceSubscription WHERE IsActive = 1) ms
    LEFT JOIN M_Service ms_name ON ms_name.Service_ID = ms.Service_ID
    LEFT JOIN #ConfiguredPoints cp ON cp.Service_ID = ms.Service_ID
    WHERE ms.Comp_ID = @CompID 
      AND (
          @ServiceWiseList IS NULL 
          OR LTRIM(RTRIM(@ServiceWiseList)) = ''
          OR cp.Service_ID IN (
              SELECT LTRIM(RTRIM(value)) 
              FROM STRING_SPLIT(ISNULL(LTRIM(RTRIM(@ServiceWiseList)), ''), ',')
              WHERE LTRIM(RTRIM(value)) <> ''
          )
      )
    UNION ALL
    -- Include Referral/KYC if they have data
    SELECT 
        'SRV1000' as Service_ID, -- Generic ID for other rewards
        'Other Rewards' as ServiceName,
        RefPoints as ServiceTotalPoints,
        RefCash as ServiceTotalCash
    FROM #ReferralStats
    WHERE RefPoints > 0 OR RefCash > 0;

    -- Result Set 3: Claim Amounts Service-Wise
    SELECT Service_ID, SUM(ClaimAmount) as ClaimAmount
    FROM (
        SELECT 
            ISNULL(Service_ID, 'SRV1001') as Service_ID,
            Amount as ClaimAmount
        FROM ClaimDetails cl
        INNER JOIN @CompanyList CL2 ON cl.Comp_id = CL2.Comp_Id
        WHERE RIGHT(cl.Mobileno, 10) = RIGHT(@MobileNo, 10) AND cl.Isapproved <> 2
        UNION ALL
        SELECT 
            'SRV1029' as Service_ID,
            ISNULL(Points_Val, Amount) as ClaimAmount
        FROM tblUPITransactionDetails 
        WHERE RIGHT(Mobileno, 10) = RIGHT(@MobileNo, 10) 
          AND (Status = 'Success' OR (Status = 'Pending' AND ReqDate >= DATEADD(day, -30, GETDATE()))) 
          AND Comp_id = @CompID 
          AND Code2 > 0
    ) t
    GROUP BY Service_ID;

    -- Cleanup
    DROP TABLE IF EXISTS #Enq;
    DROP TABLE IF EXISTS #RankedScans;
    DROP TABLE IF EXISTS #Points;
    DROP TABLE IF EXISTS #CodeConfigPoints;
    DROP TABLE IF EXISTS #AllEarnedItems;
    DROP TABLE IF EXISTS #ConfiguredPoints;
    DROP TABLE IF EXISTS #ReferralStats;
END

GO

