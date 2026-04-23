SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec [dbo].[SP_BL_GetCodesActivityReport_AI] 'Comp-1869',NULL,'2026-01-02','2026-01-07',NULL,NULL,NULL,1,10,1
CREATE PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_AI]
    @Comp_Id VARCHAR(50),
    @TimeWindow NVARCHAR(20) = NULL,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
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
        SET @TimeWindow = UPPER(@TimeWindow);

        IF (@TimeWindow = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@TimeWindow = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@TimeWindow = 'WEEK')
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, GETDATE());
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@TimeWindow = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(DAY, -14, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@TimeWindow = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@TimeWindow = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@TimeWindow = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(DAY, -90, GETDATE());
            SET @EndDate   = GETDATE();
        END
        ELSE
        BEGIN
            -- Default fallback (last 7 days)
            SET @StartDate = DATEADD(DAY, -7, GETDATE());
            SET @EndDate   = GETDATE();
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
        Longitude
    INTO #Enq
    FROM Pro_Enq
    WHERE Comp_ID = @Comp_Id
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
        MCd.Pro_ID
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
    -- POINTS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT 
        Code1,
        Code2,
        --Points
		CASE WHEN Points>0 THEN Points ELSE Cash END Points
    INTO #Points
    FROM (
        SELECT 
            P.*,
            ROW_NUMBER() OVER (
                PARTITION BY P.Code1, P.Code2
                ORDER BY (SELECT NULL)
            ) rn
        FROM BLoyaltyPointsEarned P
        INNER JOIN #Codes C
            ON P.Code1 = C.Received_Code1
           AND P.Code2 = C.Received_Code2
    ) X
    WHERE rn = 1;

    CREATE INDEX IX_Points ON #Points(Code1, Code2);

    ----------------------------------------------------
    -- RESULT SET 1
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            (E.Received_Code1 + E.Received_Code2) AS UniqueCode,
            E.Enq_Date,
            E.Dial_Mode,
            MC.ConsumerName,
            --MC.MobileNo,
			--case when LEN(MC.MobileNo)<10 THEN E.MobileNo ELSE MC.MobileNo END MobileNo,
			CASE 
				WHEN LEN(ISNULL(MC.MobileNo,'')) < 10 
					 THEN ISNULL(E.MobileNo,'')
				ELSE MC.MobileNo
			END AS MobileNo,
            G.State,
            G.City,
            PR.Pro_Name,
            CASE WHEN E.Is_Success = 1 THEN ISNULL(P.Points,0) ELSE 0 END AS Points,
            CASE 
                WHEN E.Is_Success = 1 THEN 'Verified'
                WHEN E.Is_Success = 2 THEN 'Already Scanned'
                ELSE 'Invalid'
            END AS Result,
            E.Latitude,
            E.Longitude
        --FROM #Enq E
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
        LEFT JOIN #Points P ON P.Code1 = E.Received_Code1 AND P.Code2 = E.Received_Code2
        LEFT JOIN #MCode MCd ON MCd.Code1 = E.Received_Code1 AND MCd.Code2 = E.Received_Code2
        LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
        WHERE
		 E.rn = 1
          AND  (@StateFilter IS NULL OR G.State = @StateFilter)
            AND (
                @CodeStatusFilter IS NULL OR
                (@CodeStatusFilter = 'Verified' AND E.Is_Success = 1) OR
                (@CodeStatusFilter = 'Already Scanned' AND E.Is_Success = 2) OR
                (@CodeStatusFilter = 'Invalid' AND E.Is_Success NOT IN (1,2))
            )
            AND (
               -- @Search IS NULL OR MC.MobileNo LIKE '%' + @Search + '%'
			   	 @Search IS NULL
				 OR LTRIM(RTRIM(@Search)) = ''
               OR @Search IS NULL OR E.MobileNo LIKE '%' + @Search + '%'
              OR E.Received_Code1+E.Received_Code2 LIKE '%' + @Search + '%'
            )
        ORDER BY E.Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT 
            (E.Received_Code1 + E.Received_Code2) AS UniqueCode,
            E.Enq_Date,
            E.Dial_Mode,
            MC.ConsumerName,
           -- MC.MobileNo,
			--case when LEN(MC.MobileNo)<10 THEN E.MobileNo ELSE MC.MobileNo END MobileNo,
			CASE 
				WHEN LEN(ISNULL(MC.MobileNo,'')) < 10 
					 THEN ISNULL(E.MobileNo,'')
				ELSE MC.MobileNo
			END AS MobileNo,
            G.State,
            G.City,
            PR.Pro_Name,
            CASE WHEN E.Is_Success = 1 THEN ISNULL(P.Points,0) ELSE 0 END AS Points,
            CASE 
                WHEN E.Is_Success = 1 THEN 'Verified'
                WHEN E.Is_Success = 2 THEN 'Already Scanned'
                ELSE 'Invalid'
            END AS Result,
            E.Latitude,
            E.Longitude
        FROM #Enq E
        LEFT JOIN M_Consumer MC ON MC.MobileNo = E.MobileNo AND MC.IsDelete = '0'
        LEFT JOIN #Geo G ON G.Code1 = E.Received_Code1 AND G.Code2 = E.Received_Code2 AND G.MobileNo = E.MobileNo
        LEFT JOIN #Points P ON P.Code1 = E.Received_Code1 AND P.Code2 = E.Received_Code2
        LEFT JOIN #MCode MCd ON MCd.Code1 = E.Received_Code1 AND MCd.Code2 = E.Received_Code2
        LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
        WHERE
            (@StateFilter IS NULL OR G.State = @StateFilter)
            AND (
                @CodeStatusFilter IS NULL OR
                (@CodeStatusFilter = 'Verified' AND E.Is_Success = 1) OR
                (@CodeStatusFilter = 'Already Scanned' AND E.Is_Success = 2) OR
                (@CodeStatusFilter = 'Invalid' AND E.Is_Success NOT IN (1,2))
            )
            AND (
               -- @Search IS NULL OR MC.MobileNo LIKE '%' + @Search + '%'
				 @Search IS NULL
				 OR LTRIM(RTRIM(@Search)) = ''
               OR @Search IS NULL OR E.MobileNo LIKE '%' + @Search + '%'
              OR E.Received_Code1+E.Received_Code2 LIKE '%' + @Search + '%'
            )
        ORDER BY E.Enq_Date DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        ----------------------------------------------------
        -- META
        ----------------------------------------------------
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #Enq E
        LEFT JOIN #Geo G
            ON G.Code1 = E.Received_Code1
           AND G.Code2 = E.Received_Code2
           AND G.MobileNo = E.MobileNo
        WHERE
            (@StateFilter IS NULL OR G.State = @StateFilter)
            AND (
                @CodeStatusFilter IS NULL OR
                (@CodeStatusFilter = 'Verified' AND E.Is_Success = 1) OR
                (@CodeStatusFilter = 'Already Scanned' AND E.Is_Success = 2) OR
                (@CodeStatusFilter = 'Invalid' AND E.Is_Success NOT IN (1,2))
            )
            AND (
				 @Search IS NULL
				 OR LTRIM(RTRIM(@Search)) = ''
               OR @Search IS NULL OR E.MobileNo LIKE '%' + @Search + '%'
              OR E.Received_Code1+E.Received_Code2 LIKE '%' + @Search + '%'
            );
    END
END
GO
