USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_Admin_GetCodesActivityReport_AI]    Script Date: 9/7/2026 5:45:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Migration: 20260907_Create_SP_Admin_GetCodesActivityReport_AI.sql
-- Purpose: Creates stored procedure SP_Admin_GetCodesActivityReport_AI
--          for /api/AdminVendorReport/GetCodesActivityReportAdmin
-- ====================================================================
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
        DECLARE @NormPreset NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, 'TODAY'))));
        IF (@NormPreset = '' OR @NormPreset = 'NULL') SET @NormPreset = 'TODAY';

        IF (@NormPreset = 'TODAY' OR @NormPreset = '1 TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = 'LASTDAY' OR @NormPreset = 'YESTERDAY' OR @NormPreset = '1 YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@NormPreset = 'WEEK' OR @NormPreset = '1 WEEK' OR @NormPreset = 'CURRENTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = '7DAYS' OR @NormPreset = '7 DAYS' OR @NormPreset = 'LAST7DAYS' OR @NormPreset = 'LAST 7 DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = 'LASTWEEK' OR @NormPreset = 'PREVIOUSWEEK' OR @NormPreset = 'PREVWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@NormPreset = 'MONTH' OR @NormPreset = '1 MONTH' OR @NormPreset = 'CURRENTMONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = '30DAYS' OR @NormPreset = '30 DAYS' OR @NormPreset = 'LAST30DAYS' OR @NormPreset = 'LAST 30 DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = 'LASTMONTH' OR @NormPreset = 'PREVIOUSMONTH' OR @NormPreset = 'PREVMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@NormPreset = 'QUARTER' OR @NormPreset = 'LASTQUARTER' OR @NormPreset = 'PREVQUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@NormPreset = 'YEAR' OR @NormPreset = '1 YEAR' OR @NormPreset = 'CURRENTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = 'LASTYEAR' OR @NormPreset = 'PREVIOUSYEAR' OR @NormPreset = 'PREVYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF (@NormPreset = 'ALL' OR @NormPreset = 'ALLTIME' OR @NormPreset = 'ALL TIME')
        BEGIN
            IF @Comp_Id IS NOT NULL
                SELECT @StartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @Comp_Id AND Status = 1;
            ELSE
                SET @StartDate = '2015-01-01';

            SET @EndDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            -- Default fallback: TODAY
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
        )) AS Points,
        MAX(ISNULL(MS.ServiceName, BL.ServiceName)) AS ServiceName
    INTO #Points
    FROM dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN dbo.BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
        ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN dbo.M_Consumer_M_Code MC WITH (NOLOCK) 
        ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    INNER JOIN #Enq E
        ON MC.M_Codeid = E.M_Codeid
    LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK)
        ON SST.SST_Id = BL.SST_id
    LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK)
        ON SS.Subscribe_Id = SST.Subscribe_Id
    LEFT JOIN dbo.M_Service MS WITH (NOLOCK)
        ON MS.Service_ID = SS.Service_ID
    WHERE (@Comp_Id IS NULL OR BL.compid = @Comp_Id OR BL.compid IS NULL)
    GROUP BY MC.M_Codeid, E.MobileNo;

    CREATE INDEX IX_Points_MCode ON #Points(M_Codeid, MobileNo);

    ----------------------------------------------------
    -- 4. CODE CONFIG POINTS (FALLBACK FROM SERVICE SUBSCRIPTION)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;

    SELECT 
        E.M_Codeid,
        MAX(ISNULL(SST.Frequency, 1)) AS TotalFrequency,
        MAX(CAST(
            CASE 
                WHEN SST.Points IS NOT NULL AND TRY_CAST(SST.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(SST.Points AS DECIMAL(18,2))
                ELSE ISNULL(TRY_CAST(SST.IsCash AS DECIMAL(18,2)), 0.00)
            END AS DECIMAL(18,2)
        )) AS ConfigPoints,
        MAX(S.ServiceName) AS ServiceName
    INTO #CodeConfigPoints
    FROM (SELECT DISTINCT M_Codeid, Pro_ID, Comp_ID, Series_Order, Series_Serial FROM #Enq) E
    INNER JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) 
        ON SS.Pro_ID = E.Pro_ID AND SS.Comp_ID = E.Comp_ID
    INNER JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) 
        ON SST.Subscribe_Id = SS.Subscribe_Id
    LEFT JOIN dbo.M_Service S WITH (NOLOCK)
        ON S.Service_ID = SS.Service_ID
    WHERE SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
      AND (E.Series_Order > SS.start_order OR (E.Series_Order = SS.start_order AND E.Series_Serial >= SS.start_series))
      AND (E.Series_Order < SS.end_order OR (E.Series_Order = SS.end_order AND E.Series_Serial <= SS.end_series))
    GROUP BY E.M_Codeid;

    CREATE INDEX IX_CodeConfigPoints_MCodeid ON #CodeConfigPoints(M_Codeid);

    ----------------------------------------------------
    -- 5. BUILD FINAL REPORT
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalReport') IS NOT NULL DROP TABLE #FinalReport;

    CREATE TABLE #FinalReport (
        CompanyId   VARCHAR(50),
        CompanyName NVARCHAR(200),
        MobileNo    VARCHAR(50),
        UniqueCode  VARCHAR(100),
        Pro_Name    NVARCHAR(200),
        ServiceName NVARCHAR(200),
        Enq_Date    DATETIME,
        Dial_Mode   VARCHAR(50),
        Points      VARCHAR(50),
        Result      VARCHAR(50),
        Latitude    VARCHAR(50),
        Longitude   VARCHAR(50)
    );

    -- 5a. Insert Scan Enquiries
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
        ISNULL(E.Pro_Name, 'Unknown Product') AS Pro_Name,
        ISNULL(NULLIF(P.ServiceName, ''), ISNULL(CP.ServiceName, '')) AS ServiceName,
        E.Enq_Date,
        ISNULL(E.Dial_Mode, '') AS Dial_Mode,
        CAST(
            CASE 
                WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
                    CASE 
                        WHEN ISNULL(P.Points, 0) > 0 THEN P.Points 
                        ELSE ISNULL(CP.ConfigPoints, 0.00) 
                    END
                ELSE 0.00 
            END AS VARCHAR(50)
        ) AS Points,
        CASE 
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 'Verified'
            WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1)) THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
        ISNULL(E.Latitude, '') AS Latitude,
        ISNULL(E.Longitude, '') AS Longitude
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
    LEFT JOIN dbo.Comp_Reg CR WITH (NOLOCK) 
        ON CR.Comp_ID = E.Comp_ID
    LEFT JOIN dbo.M_Consumer MC WITH (NOLOCK)
        ON (MC.MobileNo = E.MobileNo OR (LEN(E.MobileNo) >= 10 AND RIGHT(MC.MobileNo, 10) = RIGHT(E.MobileNo, 10))) AND MC.IsDelete = 0
    LEFT JOIN #Points P 
        ON P.M_Codeid = E.M_Codeid 
       AND (P.MobileNo = E.MobileNo OR '91' + P.MobileNo = E.MobileNo OR P.MobileNo = '91' + E.MobileNo OR (LEN(P.MobileNo) >= 10 AND LEN(E.MobileNo) >= 10 AND RIGHT(P.MobileNo, 10) = RIGHT(E.MobileNo, 10)) OR P.MobileNo IS NULL)
    LEFT JOIN #CodeConfigPoints CP 
        ON CP.M_Codeid = E.M_Codeid
    WHERE (E.Is_Success != 1 OR E.rn <= ISNULL(CP.TotalFrequency, 1));

    -- 5b. Insert Registration Referrals (virtual rows)
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
        ISNULL(BL.ServiceName, 'Referral') AS ServiceName,
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

    -- Cleanup
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;
    IF OBJECT_ID('tempdb..#FinalReport') IS NOT NULL DROP TABLE #FinalReport;
END;
GO
