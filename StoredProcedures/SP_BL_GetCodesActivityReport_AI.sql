USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetCodesActivityReport_AI]    Script Date: 5/5/2026 12:47:13 PM ******/
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

    ----------------------------------------------------
    -- ENQUIRIES
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
   ON PR.Pro_ID=M.Pro_ID
    WHERE PR.Comp_ID = @Comp_Id
      AND Enq_Date >= @StartDate
      AND Enq_Date <  @EndDate
      AND (@DialModeFilter IS NULL OR Dial_Mode = @DialModeFilter);

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

    SELECT
        MC.M_Codeid,
        MAX(CAST(
            CASE 
                WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(BL.Cash, 0) * 1.10
                WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0)
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS Points,
        MAX(CAST(
            CASE 
                WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0)
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS WornPoint
    INTO #Points
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON BL.SST_id = sst.SST_Id
    LEFT JOIN M_ServiceSubscription ss WITH (NOLOCK) ON sst.Subscribe_Id = ss.Subscribe_Id
    WHERE 
    (
        (@Comp_Id IN ('Comp-1567','Comp-1650') AND BL.compid IN ('Comp-1567','Comp-1650'))
        OR
        (@Comp_Id NOT IN ('Comp-1567','Comp-1650') AND BL.compid = @Comp_Id)
    )
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
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(CP.ConfigPoints, ISNULL(P.Points, 0)) 
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
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(P.WornPoint, 0)
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