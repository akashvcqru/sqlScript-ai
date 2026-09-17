USE [Vcqru]
GO

PRINT '====================================================='
PRINT '1. Deploying SP_BL_GetCodesActivityReport_Combined_AI'
PRINT '====================================================='
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_Combined_AI]
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
    -- Drop Temp Tables if exist
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;
    IF OBJECT_ID('tempdb..#Codes') IS NOT NULL DROP TABLE #Codes;
    IF OBJECT_ID('tempdb..#MCode') IS NOT NULL DROP TABLE #MCode;
    IF OBJECT_ID('tempdb..#Pro') IS NOT NULL DROP TABLE #Pro;
    IF OBJECT_ID('tempdb..#Geo') IS NOT NULL DROP TABLE #Geo;
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;
    IF OBJECT_ID('tempdb..#ScanReferrals') IS NOT NULL DROP TABLE #ScanReferrals;
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;
    IF OBJECT_ID('tempdb..#FinalReport') IS NOT NULL DROP TABLE #FinalReport;

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

    ----------------------------------------------------
    -- ENQUIRIES
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

    SELECT 
        Received_Code1,
        Received_Code2,
		code1,code2,
        Enq_Date,
        Dial_Mode,
        Is_Success,
        MobileNo,
        Latitude,
        Longitude,
        M.Row_ID as M_Codeid, M.Row_ID as Row_ID ,M.Pro_ID,
        M.Series_Order,
        M.Series_Serial
    INTO #Enq
    FROM Pro_Enq
	INNER JOIN M_code M 
	    ON Received_Code1 = CAST(code1 AS VARCHAR(50))
	 AND Received_Code2 = CAST(Code2 AS VARCHAR(50))
   INNER JOIN Pro_Reg PR
   ON PR.Pro_ID=M.Pro_ID
    WHERE PR.Comp_ID = @Comp_Id 
      AND (@Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR MobileNo = @Search);

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

    SELECT DISTINCT
        c.Code1,
        c.Code2,
        c.Pro_ID,
        c.Series_Order,
        c.Series_Serial,
        c.Row_ID AS M_Codeid,
        c.Row_ID AS Row_ID
    INTO #MCode FROM #Enq C;

    CREATE INDEX IX_MCode ON #MCode(Code1, Code2);

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
    -- POINTS (REFACTORED - ID BASED)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation 
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
        FROM BuiltLoyaltyMCodeCheck
    ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
    INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    INNER JOIN #MCode M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
    LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON BL.SST_id = sst.SST_Id
    LEFT JOIN M_ServiceSubscription ss WITH (NOLOCK) ON sst.Subscribe_Id = ss.Subscribe_Id
    WHERE BL.compid = @Comp_Id OR (BL.compid IS NULL AND PR.Comp_ID = @Comp_Id)
    GROUP BY MC.M_Codeid;

    CREATE INDEX IX_Points_MCodeid ON #Points(M_Codeid);

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
    -- CODE CONFIG POINTS (PRECISE BY SERIES RANGE)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;

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
                ORDER BY SST.Entry_Date DESC, SST_Id DESC
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

    ----------------------------------------------------
    -- COMBINE SCANS AND REGISTRATION REFERRALS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalReport') IS NOT NULL DROP TABLE #FinalReport;

    CREATE TABLE #FinalReport (
        Row_id BIGINT,
        UniqueCode VARCHAR(100),
        Enq_Date DATETIME,
        Dial_Mode VARCHAR(50),
        ConsumerName NVARCHAR(150),
        MobileNo VARCHAR(50),
        State NVARCHAR(100),
        City NVARCHAR(100),
        Pro_Name NVARCHAR(200),
        Points DECIMAL(18,2),
        Result VARCHAR(50),
        Latitude VARCHAR(50),
        Longitude VARCHAR(50),
        AssignPoint DECIMAL(18,2),
        WornPoint DECIMAL(18,2),
        ReferralPoints DECIMAL(18,2)
    );

    -- 1. Insert scan enquiries
    INSERT INTO #FinalReport
    SELECT 
        E.Row_id,
        (E.Received_Code1 + E.Received_Code2) AS UniqueCode,
        E.Enq_Date,
        E.Dial_Mode,
        MC.ConsumerName,
			CASE 
				WHEN LEN(ISNULL(MC.MobileNo,'')) < 10 
					 THEN ISNULL(E.MobileNo,'')
				ELSE MC.MobileNo
			END AS MobileNo,
        G.State,
        G.City,
        PR.Pro_Name,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(P.Points, ISNULL(CP.ConfigPoints, 0)) 
            ELSE 0 
        END AS Points,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN 'Verified'
            WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.Frequency, 1)) THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
			E.Latitude,
			E.Longitude,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(CP.AssignPoint, 0)
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(P.WornPoint, ISNULL(CP.ConfigPoints, 0)) 
            ELSE 0 
        END AS WornPoint,
        ISNULL(R.ReferralPoints, 0) AS ReferralPoints
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
        LEFT JOIN M_Consumer MC ON MC.MobileNo = E.MobileNo AND MC.IsDelete = '0'
        LEFT JOIN #Geo G ON G.Code1 = E.Received_Code1 AND G.Code2 = E.Received_Code2 AND G.MobileNo = E.MobileNo
        LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid
        LEFT JOIN #MCode MCd ON MCd.M_Codeid = E.M_Codeid
        LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
        LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid
        LEFT JOIN #ScanReferrals R ON R.Code1 = E.Received_Code1 AND R.Code2 = E.Received_Code2
        WHERE
		  (E.Is_Success != 1 OR E.rn <= ISNULL(CP.Frequency, 1))
          AND (@StateFilter IS NULL OR G.State = @StateFilter);

    -- 2. Insert registration referrals (virtual rows)
    INSERT INTO #FinalReport
    SELECT 
        NULL AS Row_id,
        '' AS UniqueCode,
        BL.UpdateDate AS Enq_Date,
        'Referral' AS Dial_Mode,
        MC.ConsumerName,
        MC.MobileNo,
        MC.State,
        MC.City,
        'Referral Bonus' AS Pro_Name,
        0 AS Points,
        'Referral' AS Result,
        '' AS Latitude,
        '' AS Longitude,
        0 AS AssignPoint,
        0 AS WornPoint,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralPoints
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    WHERE (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND BL.Code1 IS NULL
      AND (
          (@Comp_Id IN ('Comp-1567','Comp-1650') AND BL.compid IN ('Comp-1567','Comp-1650'))
          OR
          (@Comp_Id NOT IN ('Comp-1567','Comp-1650') AND BL.compid = @Comp_Id)
      )
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate < @EndDate
      AND (@StateFilter IS NULL OR MC.State = @StateFilter)
    GROUP BY BL.M_Consumerid, MC.ConsumerName, MC.MobileNo, MC.State, MC.City, BL.UpdateDate;

    ----------------------------------------------------
    -- RESULT SET 1
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            Row_id,
            UniqueCode,
            Enq_Date,
            Dial_Mode,
            ConsumerName,
            MobileNo,
            State,
            City,
            Pro_Name,
            Points,
            Result,
			Latitude,
			Longitude,
            AssignPoint,
            WornPoint,
            ReferralPoints
		FROM #FinalReport
        WHERE (
            @CodeStatusFilter IS NULL OR
            Result = @CodeStatusFilter OR
            (@CodeStatusFilter = 'Already Verified' AND Result = 'Already Scanned')
        )
        AND (
			 @Search IS NULL
			 OR LTRIM(RTRIM(@Search)) = ''
			 OR MobileNo LIKE '%' + @Search + '%'
			 OR UniqueCode LIKE '%' + @Search + '%'
        )
        ORDER BY Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT 
            Row_id,
            UniqueCode,
            Enq_Date,
            Dial_Mode,
            ConsumerName,
            MobileNo,
            State,
            City,
            Pro_Name,
            Points,
            Result,
			Latitude,
			Longitude,
            AssignPoint,
            WornPoint,
            ReferralPoints
        FROM #FinalReport
        WHERE (
            @CodeStatusFilter IS NULL OR
            Result = @CodeStatusFilter OR
            (@CodeStatusFilter = 'Already Verified' AND Result = 'Already Scanned')
        )
        AND (
			 @Search IS NULL
			 OR LTRIM(RTRIM(@Search)) = ''
			 OR MobileNo LIKE '%' + @Search + '%'
			 OR UniqueCode LIKE '%' + @Search + '%'
        )
        ORDER BY Enq_Date DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        ----------------------------------------------------
        -- META
        ----------------------------------------------------
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalReport
        WHERE (
            @CodeStatusFilter IS NULL OR
            Result = @CodeStatusFilter OR
            (@CodeStatusFilter = 'Already Verified' AND Result = 'Already Scanned')
        )
        AND (
			 @Search IS NULL
			 OR LTRIM(RTRIM(@Search)) = ''
			 OR MobileNo LIKE '%' + @Search + '%'
			 OR UniqueCode LIKE '%' + @Search + '%'
        );
    END
END
GO

PRINT '====================================================='
PRINT '2. Deploying SP_BL_GetPaymentClaimReport'
PRINT '====================================================='
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetPaymentClaimReport]
(
    @Comp_Id        VARCHAR(20),
    @datePreset     NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate       DATETIME     = NULL,
    @ToDate         DATETIME     = NULL,
    @ClaimStatus    NVARCHAR(20) = NULL,   -- Pending / Approved / Rejected
    @PaymentStatus  NVARCHAR(20) = NULL,   -- Success / Failed / Pending

    @Page           INT = NULL,
    @Limit          INT = NULL,
    @IsExport       BIT = NULL,
    @search         NVARCHAR(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- POINT CONVERSION RATE (dynamic per company)
    ---------------------------------------------------------
    DECLARE @ConvPointValue  DECIMAL(18,4) = 1;
    DECLARE @ConvCashValue   DECIMAL(18,4) = 1;

    SELECT TOP 1
        @ConvPointValue = ISNULL(NULLIF(PointValue, 0), 1),
        @ConvCashValue  = ISNULL(CashValue, 1)
    FROM PointConversionRate
    WHERE Comp_ID = @Comp_Id
      AND IsActive = 1;

    ---------------------------------------------------------
    -- SAFETY DEFAULTS
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- DATE RANGE
    ---------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME = '2015-01-01';

    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize datePreset
    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    -- Explicit date range overrides datePreset
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1; -- Monday start

        IF (@datePreset = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@datePreset = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@datePreset = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@datePreset = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                                DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@datePreset = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END

        ELSE IF (@datePreset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                                DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@datePreset = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                                DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @EndDate), 0));
        END

        ELSE IF (@datePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), 1, 1);
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END

        ELSE IF (@datePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(@EndDate) - 1, 12, 31);
        END

        ELSE -- ALL / NULL
        BEGIN
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    ---------------------------------------------------------
    -- BASE WHERE (REUSED)
    ---------------------------------------------------------

    DECLARE @BaseWhere NVARCHAR(MAX) = N'
    WHERE CD.Comp_id = @Comp_Id
      AND (@StartDate IS NULL OR CD.Claim_Date >= @StartDate)
      AND (@EndDate   IS NULL OR CD.Claim_Date <  DATEADD(DAY, 1, @EndDate))
      AND CD.Row_id NOT IN (SELECT Row_id FROM ClaimDetails WHERE IsReqClaimReport = 0)
';

    IF @ClaimStatus IS NOT NULL
        SET @BaseWhere += N'
        AND (
            (@ClaimStatus = ''Pending''  AND (CD.Isapproved = 0 OR CD.Isapproved IS NULL)) OR
            (@ClaimStatus = ''Approved'' AND CD.Isapproved = 1) OR
            (@ClaimStatus = ''Rejected'' AND CD.Isapproved = 2)
        )';

    IF @PaymentStatus IS NOT NULL
        SET @BaseWhere += N'
        AND (CD.PaymentStatus = @PaymentStatus OR (@PaymentStatus = ''Pending'' AND CD.PaymentStatus IS NULL))';

    -- Mobile or Claim ID Search
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
        SET @BaseWhere += N'
        AND (
            REPLACE(CD.Mobileno,'' '','''') LIKE ''%'' + REPLACE(@Search,'' '','''') + ''%''
            OR CAST(CD.Row_id AS VARCHAR(20)) LIKE ''%'' + LTRIM(RTRIM(@Search)) + ''%''
        )';

    ---------------------------------------------------------
    -- DATA QUERY
    ---------------------------------------------------------
    DECLARE @SQLData NVARCHAR(MAX) = N'
    SELECT
        CD.Comp_id AS Comp_ID,
        CR.Comp_Name,
        CD.Row_id AS Claim_id,
        CD.Claim_date,
        CD.Mobileno,
        CD.Amount AS Points,
        CAST(ISNULL(CD.RequestAmmount, 0) - ISNULL(CD.tdsAmount, 0) AS DECIMAL(18, 2)) AS PointsValue,
        ISNULL(CD.tdsAmount, 0) AS tdsAmount,
        ISNULL(CD.tdsper, 0) AS tdsper,
        MC.ConsumerName,
        MC.City,
        MC.PinCode AS Pincode,
        MC.state AS State,
        MB.Account_No,
        MB.Account_HolderNm,
        MB.Bank_Name AS [Bank Name],
        MB.IFSC_Code,
        ISNULL(CD.PaymentStatus, ''Pending'') AS PaymentStatus,
        CD.BankRefID,
        CD.TransactionDate,
        CD.PaymentRemarks,
        CASE 
            WHEN CD.Isapproved = 1 THEN ''Approved''
            WHEN CD.Isapproved = 2 THEN ''Rejected''
            ELSE ''Pending''
        END AS Claim_Status,
        CD.vendor_comment,
        CD.action_date,
        ISNULL(CD.Gifts_Redeemed, CG.Gift_name) AS GiftName
    FROM ClaimDetails CD
    LEFT JOIN Comp_Reg CR
        ON CR.Comp_ID = CD.Comp_id
    LEFT JOIN M_Consumer MC 
        ON MC.MobileNo = CD.Mobileno
    LEFT JOIN Claim_gift CG
        ON CG.gift_id = CD.Gift_id
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM M_BankAccount B
        WHERE B.M_Consumerid = MC.M_Consumerid
        ORDER BY B.Entry_Date DESC
    ) MB
    ' + @BaseWhere + N'
    ORDER BY CD.Claim_date DESC';

    IF @IsExport = 0
        SET @SQLData += N'
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY';

    ---------------------------------------------------------
    -- COUNT QUERY
    ---------------------------------------------------------
    DECLARE @SQLCount NVARCHAR(MAX) = N'
    SELECT
        COUNT(DISTINCT CD.Row_id) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(DISTINCT CD.Row_id) * 1.0 / @Limit) AS TotalPages
    FROM ClaimDetails CD
    LEFT JOIN M_Consumer MC 
        ON MC.MobileNo = CD.Mobileno
    ' + @BaseWhere;

    ---------------------------------------------------------
    -- FINAL EXECUTION
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        EXEC sp_executesql
            @SQLData,
            N'
                @Comp_Id VARCHAR(20),
                @StartDate DATETIME,
                @EndDate DATETIME,
                @ClaimStatus NVARCHAR(20),
                @PaymentStatus NVARCHAR(20),
                @Search NVARCHAR(30),
                @ConvPointValue DECIMAL(18,4),
                @ConvCashValue  DECIMAL(18,4)
            ',
            @Comp_Id,
            @StartDate,
            @EndDate,
            @ClaimStatus,
            @PaymentStatus,
            @Search,
            @ConvPointValue,
            @ConvCashValue;
    END
    ELSE
    BEGIN
        DECLARE @FinalSQL NVARCHAR(MAX) = @SQLData + N'; ' + @SQLCount;

        EXEC sp_executesql
            @FinalSQL,
            N'
                @Comp_Id VARCHAR(20),
                @StartDate DATETIME,
                @EndDate DATETIME,
                @ClaimStatus NVARCHAR(20),
                @PaymentStatus NVARCHAR(20),
                @Search NVARCHAR(30),
                @Offset INT,
                @Limit INT,
                @Page INT,
                @ConvPointValue DECIMAL(18,4),
                @ConvCashValue  DECIMAL(18,4)
            ',
            @Comp_Id,
            @StartDate,
            @EndDate,
            @ClaimStatus,
            @PaymentStatus,
            @Search,
            @Offset,
            @Limit,
            @Page,
            @ConvPointValue,
            @ConvCashValue;
    END
END
GO

PRINT '====================================================='
PRINT '3. Deploying GetUPIpayoutRportBL_AI_FillData'
PRINT '====================================================='
GO

CREATE OR ALTER PROCEDURE [dbo].[GetUPIpayoutRportBL_AI_FillData]
(
      @Compid        NVARCHAR(50),
      @FromDate      DATETIME = NULL,
      @ToDate        DATETIME = NULL,
      @datePreset    NVARCHAR(20) = NULL,
      @StatusFilter  NVARCHAR(30) = NULL,   -- Success / Pending / Failed
      @MobileNo      NVARCHAR(20) = NULL,
      @Page          INT = NULL,
      @Limit         INT = NULL,
      @IsExport      BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #FinalData;

    -------------------------------------------------
    -- Company start date
    -------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;

    SELECT @CompanyStartDate = Reg_Date
    FROM Comp_Reg
    WHERE Comp_ID = @Compid AND Status = 1;

    -------------------------------------------------
    -- Pagination defaults (only used when IsExport = 0)
    -------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -------------------------------------------------
    -- Date window logic
    -------------------------------------------------
    DECLARE @StartDate DATETIME, @EndDate DATETIME;
    DECLARE @Today DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@datePreset,''));

    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = DATEADD(DAY,1,@ToDate);
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE IF @Win = 'LASTDAY'
        BEGIN
            SET @StartDate = DATEADD(DAY,-1,@Today);
            SET @EndDate   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY,1-DATEPART(WEEKDAY,@Today),@Today);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE IF @Win = 'LASTWEEK'
        BEGIN
            SET DATEFIRST 1;
            DECLARE @ThisWeekStart DATETIME =
                DATEADD(DAY,1-DATEPART(WEEKDAY,@Today),@Today);

            SET @StartDate = DATEADD(DAY,-7,@ThisWeekStart);
            SET @EndDate   = @ThisWeekStart;
        END
        ELSE IF @Win = 'MONTH'
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1) AS DATETIME);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE IF @Win = 'LASTMONTH'
        BEGIN
            DECLARE @ThisMonthStart DATETIME =
                CAST(DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1) AS DATETIME);

            SET @StartDate = DATEADD(MONTH,-1,@ThisMonthStart);
            SET @EndDate   = @ThisMonthStart;
        END
        ELSE IF @Win = 'QUARTER'
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Today), 0);
        END
        ELSE IF @Win = 'YEAR'
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(@Today), 1, 1) AS DATETIME);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE IF @Win = 'LASTYEAR'
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(@Today) - 1, 1, 1) AS DATETIME);
            SET @EndDate   = CAST(DATEFROMPARTS(YEAR(@Today), 1, 1) AS DATETIME);
        END
        ELSE
        BEGIN
            SET @StartDate = CAST(@CompanyStartDate AS DATETIME);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
    END

    -------------------------------------------------
    -- Final dataset
    -------------------------------------------------
    SELECT
        p.Id AS tblUPITransactionDetailsID,
        p.Comp_Id AS Comp_ID,
        c.Comp_Name,
        m.ConsumerName,
        m.MobileNo,
        p.Code1,
        p.Code2,
        CASE 
            WHEN p.UPI_Id IS NULL
                THEN p.account_no
            ELSE p.UPI_Id
        END AS UPI_Id,

        ISNULL(w.OldBal,0) AS OldBal,

        p.Amount + ISNULL(p.tdsAmount,0) AS Amount,
        p.Amount AS FinalPayment,

        p.tdsAmount,
        p.tdsper,
        p.TCharge_Amount AS ChargedAmount,
        p.GstAmount,

        ISNULL(w.NewBal,0) AS NewBal,

        p.OrderId,
        p.Status AS BankStatus,

        CASE  
            WHEN p.Remarks IN (
                'Insufficient Wallet Balance',
                'Insufficient wallet balance for debit'
            )
            THEN 'Error: IP001, please try after some time or connect with your account manager.'
            ELSE p.Remarks  
        END AS BankRemark,

        p.ReqDate,
        p.Remarks AS FinalStatus,

        CASE   
            WHEN ISNULL(p.Code1,'') = '' 
             AND ISNULL(p.Code2,'') = '' 
             AND p.Status = 'Success'
                THEN 'Claimed'
            ELSE p.FinalRemarks  
        END AS FinalRemark
    INTO #FinalData
    FROM tblUPITransactionDetails p
    INNER JOIN M_Consumer m 
        ON m.M_Consumerid = p.M_Consumerid
    LEFT JOIN Comp_Reg c
        ON c.Comp_ID = p.Comp_Id
    LEFT JOIN (
        SELECT PayrefId,
               MAX(OldBal) AS OldBal,
               MAX(NewBal) AS NewBal
        FROM tblCashWalletBalance
        WHERE Service_ID IN ('SRV1029','SRV1001')
        GROUP BY PayrefId
    ) w ON w.PayrefId = p.Id
    WHERE p.Comp_Id = @Compid
      AND p.ReqDate >= @StartDate
      AND p.ReqDate <  @EndDate
      AND (@MobileNo IS NULL OR p.MobileNo LIKE '%' + @MobileNo + '%')
      AND p.Code1 NOT IN ('76106','28480','63762')
      AND p.Code2 NOT IN ('53123003','81708028','45063737');

    -------------------------------------------------
    -- Output
    -------------------------------------------------
    IF @IsExport = 1
    BEGIN
        -- Export mode: all rows, no pagination
        SELECT *
        FROM #FinalData
        WHERE (@StatusFilter IS NULL OR BankStatus = @StatusFilter)
        ORDER BY ReqDate DESC;
    END
    ELSE
    BEGIN
        -- API mode: paginated result
        SELECT *
        FROM #FinalData
        WHERE (@StatusFilter IS NULL OR BankStatus = @StatusFilter)
        ORDER BY ReqDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Pagination info
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData
        WHERE (@StatusFilter IS NULL OR BankStatus = @StatusFilter);
    END
END
GO

PRINT '====================================================='
PRINT '4. Deploying USP_FillThreeCombinedActivityReports_AllCompanies_AI'
PRINT '====================================================='
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_FillThreeCombinedActivityReports_AllCompanies_AI]
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 1. Fetch All Active Companies
    ---------------------------------------------------------
    DECLARE @Companies TABLE
    (
        ID INT IDENTITY(1,1),
        Comp_ID VARCHAR(50),
        Comp_Name NVARCHAR(250)
    );

    INSERT INTO @Companies (Comp_ID, Comp_Name)
    SELECT DISTINCT Comp_ID, Comp_Name
    FROM Comp_Reg WITH (NOLOCK)
    WHERE ISNULL(IsDelete, 0) = 0
      AND Status = 1;

    DECLARE
        @i INT = 1,
        @MaxID INT,
        @Comp_ID VARCHAR(50),
        @Comp_Name NVARCHAR(250);

    SET @MaxID = (SELECT MAX(ID) FROM @Companies);

    ---------------------------------------------------------
    -- 2. Loop Through Companies One by One
    ---------------------------------------------------------
    WHILE @i <= @MaxID
    BEGIN
        SELECT 
            @Comp_ID = Comp_ID,
            @Comp_Name = Comp_Name
        FROM @Companies
        WHERE ID = @i;

        IF @Comp_ID IS NOT NULL
        BEGIN
            BEGIN TRY
                PRINT 'Processing Company [' + CAST(@i AS VARCHAR) + '/' + CAST(@MaxID AS VARCHAR) + ']: ' + ISNULL(@Comp_Name, '') + ' (' + @Comp_ID + ')';

                ---------------------------------------------------------
                -- A. Process Codes Activity Report (Point Earned)
                ---------------------------------------------------------
                IF OBJECT_ID('tempdb..#TempCodesActivity') IS NOT NULL DROP TABLE #TempCodesActivity;

                CREATE TABLE #TempCodesActivity (
                    Row_id          BIGINT,
                    UniqueCode      VARCHAR(100),
                    Enq_Date        DATETIME,
                    Dial_Mode       VARCHAR(50),
                    ConsumerName    NVARCHAR(150),
                    MobileNo        VARCHAR(50),
                    State           NVARCHAR(100),
                    City            NVARCHAR(100),
                    Pro_Name        NVARCHAR(200),
                    Points          DECIMAL(18,2),
                    Result          VARCHAR(50),
                    Latitude        VARCHAR(50),
                    Longitude       VARCHAR(50),
                    AssignPoint     DECIMAL(18,2),
                    WornPoint       DECIMAL(18,2),
                    ReferralPoints  DECIMAL(18,2)
                );

                INSERT INTO #TempCodesActivity
                EXEC dbo.SP_BL_GetCodesActivityReport_Combined_AI
                    @Comp_Id    = @Comp_ID,
                    @datePreset = 'ALL',
                    @IsExport   = 1;

                DELETE FROM dbo.tbl_BL_CodesActivityReport_AI WHERE Comp_ID = @Comp_ID;

                INSERT INTO dbo.tbl_BL_CodesActivityReport_AI
                (
                    Row_id, Comp_ID, UniqueCode, Enq_Date, Dial_Mode, ConsumerName, MobileNo,
                    State, City, Pro_Name, Points, Result, Latitude, Longitude,
                    AssignPoint, WornPoint, ReferralPoints
                )
                SELECT 
                    Row_id, @Comp_ID, UniqueCode, Enq_Date, Dial_Mode, ConsumerName, MobileNo,
                    State, City, Pro_Name, Points, Result, Latitude, Longitude,
                    AssignPoint, WornPoint, ReferralPoints
                FROM #TempCodesActivity;

                DECLARE @ActivityCount INT = @@ROWCOUNT;

                ---------------------------------------------------------
                -- B. Process Payment Claim Report (Point Claimed)
                ---------------------------------------------------------
                IF OBJECT_ID('tempdb..#TempPaymentClaim') IS NOT NULL DROP TABLE #TempPaymentClaim;

                CREATE TABLE #TempPaymentClaim (
                    Comp_ID          VARCHAR(50),
                    Comp_Name        NVARCHAR(250),
                    Claim_id         BIGINT,
                    Claim_date       DATETIME,
                    Mobileno         VARCHAR(50),
                    Points           DECIMAL(18,2),
                    PointsValue      DECIMAL(18,2),
                    tdsAmount        DECIMAL(18,2),
                    tdsper           DECIMAL(18,2),
                    ConsumerName     NVARCHAR(250),
                    City             NVARCHAR(100),
                    Pincode          NVARCHAR(50),
                    State            NVARCHAR(100),
                    Account_No       NVARCHAR(100),
                    Account_HolderNm NVARCHAR(250),
                    BankName         NVARCHAR(250),
                    IFSC_Code        NVARCHAR(50),
                    PaymentStatus    NVARCHAR(50),
                    BankRefID        NVARCHAR(100),
                    TransactionDate  NVARCHAR(100),
                    PaymentRemarks   NVARCHAR(MAX),
                    Claim_Status     NVARCHAR(50),
                    vendor_comment   NVARCHAR(MAX),
                    action_date      DATETIME,
                    GiftName         NVARCHAR(250)
                );

                INSERT INTO #TempPaymentClaim
                EXEC dbo.SP_BL_GetPaymentClaimReport
                    @Comp_Id    = @Comp_ID,
                    @datePreset = 'ALL',
                    @IsExport   = 1;

                DELETE FROM dbo.tbl_BL_PaymentClaimReport_AI WHERE Comp_ID = @Comp_ID;

                INSERT INTO dbo.tbl_BL_PaymentClaimReport_AI
                (
                    Row_id, Comp_ID, Comp_Name, Claim_date, Mobileno, Points, PointsValue,
                    tdsAmount, tdsper, ConsumerName, City, Pincode, State, Account_No,
                    Account_HolderNm, BankName, IFSC_Code, PaymentStatus, BankRefID,
                    TransactionDate, PaymentRemarks, Claim_Status, vendor_comment, action_date, GiftName
                )
                SELECT 
                    Claim_id, Comp_ID, Comp_Name, Claim_date, Mobileno, Points, PointsValue,
                    tdsAmount, tdsper, ConsumerName, City, Pincode, State, Account_No,
                    Account_HolderNm, BankName, IFSC_Code, PaymentStatus, BankRefID,
                    TransactionDate, PaymentRemarks, Claim_Status, vendor_comment, action_date, GiftName
                FROM #TempPaymentClaim;

                DECLARE @ClaimCount INT = @@ROWCOUNT;

                ---------------------------------------------------------
                -- C. Process UPI Payout Report (Point Paid)
                ---------------------------------------------------------
                IF OBJECT_ID('tempdb..#TempUPIPayout') IS NOT NULL DROP TABLE #TempUPIPayout;

                CREATE TABLE #TempUPIPayout (
                    tblUPITransactionDetailsID BIGINT,
                    Comp_ID       VARCHAR(50),
                    Comp_Name     NVARCHAR(250),
                    ConsumerName  NVARCHAR(250),
                    MobileNo      VARCHAR(50),
                    Code1         VARCHAR(50),
                    Code2         VARCHAR(50),
                    UPI_Id        NVARCHAR(100),
                    OldBal        DECIMAL(18,2),
                    Amount        DECIMAL(18,2),
                    FinalPayment  DECIMAL(18,2),
                    tdsAmount     DECIMAL(18,2),
                    tdsper        DECIMAL(18,2),
                    ChargedAmount DECIMAL(18,2),
                    GstAmount     DECIMAL(18,2),
                    NewBal        DECIMAL(18,2),
                    OrderId       NVARCHAR(100),
                    BankStatus    NVARCHAR(50),
                    BankRemark    NVARCHAR(MAX),
                    ReqDate       DATETIME,
                    FinalStatus   NVARCHAR(500),
                    FinalRemark   NVARCHAR(MAX)
                );

                INSERT INTO #TempUPIPayout
                EXEC dbo.GetUPIpayoutRportBL_AI_FillData
                    @Compid     = @Comp_ID,
                    @datePreset = 'ALL',
                    @IsExport   = 1;

                DELETE FROM dbo.tbl_BL_UPIPayoutReport_AI WHERE Comp_ID = @Comp_ID;

                INSERT INTO dbo.tbl_BL_UPIPayoutReport_AI
                (
                    tblUPITransactionDetailsID, Comp_ID, ConsumerName, MobileNo, Code1, Code2,
                    UPI_Id, OldBal, Amount, FinalPayment, tdsAmount, tdsper, ChargedAmount,
                    GstAmount, NewBal, OrderId, BankStatus, BankRemark, ReqDate, FinalStatus, FinalRemark
                )
                SELECT 
                    tblUPITransactionDetailsID, Comp_ID, ConsumerName, MobileNo, Code1, Code2,
                    UPI_Id, OldBal, Amount, FinalPayment, tdsAmount, tdsper, ChargedAmount,
                    GstAmount, NewBal, OrderId, BankStatus, BankRemark, ReqDate, FinalStatus, FinalRemark
                FROM #TempUPIPayout;

                DECLARE @PayoutCount INT = @@ROWCOUNT;

                ---------------------------------------------------------
                -- D. Log Execution Status into TempDataSyncLog
                ---------------------------------------------------------
                IF EXISTS (
                    SELECT 1 
                    FROM dbo.TempDataSyncLog 
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE)
                )
                BEGIN
                    UPDATE dbo.TempDataSyncLog
                    SET 
                        CodeActivityCount = @ActivityCount,
                        PayoutReportCount = @PayoutCount,
                        Status = 'Success',
                        ErrorMessage = NULL,
                        SyncDateTime = GETDATE()
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE);
                END
                ELSE
                BEGIN
                    INSERT INTO dbo.TempDataSyncLog
                    (
                        Comp_ID,
                        Comp_Name,
                        CodeActivityCount,
                        PayoutReportCount,
                        Status,
                        SyncDateTime
                    )
                    VALUES
                    (
                        @Comp_ID,
                        @Comp_Name,
                        @ActivityCount,
                        @PayoutCount,
                        'Success',
                        GETDATE()
                    );
                END
            END TRY
            BEGIN CATCH
                DECLARE @ErrorMsg NVARCHAR(1000) = ERROR_MESSAGE();
                PRINT 'Error Processing Company ' + ISNULL(@Comp_Name, '') + ' (' + @Comp_ID + '): ' + @ErrorMsg;

                IF EXISTS (
                    SELECT 1 
                    FROM dbo.TempDataSyncLog 
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE)
                )
                BEGIN
                    UPDATE dbo.TempDataSyncLog
                    SET 
                        Status = 'Failed',
                        ErrorMessage = LEFT(@ErrorMsg, 1000),
                        SyncDateTime = GETDATE()
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE);
                END
                ELSE
                BEGIN
                    INSERT INTO dbo.TempDataSyncLog
                    (
                        Comp_ID,
                        Comp_Name,
                        Status,
                        ErrorMessage,
                        SyncDateTime
                    )
                    VALUES
                    (
                        @Comp_ID,
                        @Comp_Name,
                        'Failed',
                        LEFT(@ErrorMsg, 1000),
                        GETDATE()
                    );
                END
            END CATCH
        END

        SET @i = @i + 1;
    END
END
GO

PRINT 'All procedures updated successfully!'
GO
