USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]
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
    @Search          NVARCHAR(30) = NULL,
    @BalanceLessThan DECIMAL(18,2) = NULL
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
    IF @Comp_Id IN ('Comp-1567','Comp-1650')
        INSERT INTO @CompanyList VALUES ('Comp-1567'),('Comp-1650');
    ELSE
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
    WHERE Comp_ID = @Comp_Id AND Status = 1;

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
    DROP TABLE IF EXISTS #Candidates, #Users, #UserMobiles, #State, #Benefit, #Claims, #TDS, #UPI, #BPoints, #FinalData, #UniqueScans, #EarnedPoints, #ConfigPoints, #Referrals, #OtherEarnedPoints;

    ---------------------------------------------------------
    -- CANDIDATE USERS FOR THIS COMPANY
    ---------------------------------------------------------
    SELECT DISTINCT M_ConsumerId
    INTO #Candidates
    FROM (
        SELECT M_ConsumerId FROM tbl_VendorViseKYCStatus WITH (NOLOCK) WHERE Comp_Id = @Comp_Id
        UNION
        SELECT MC.M_ConsumerId FROM ClaimDetails CD WITH (NOLOCK) INNER JOIN M_Consumer MC WITH (NOLOCK) ON CD.Mobileno = MC.MobileNo WHERE CD.Comp_id = @Comp_Id
        UNION
        SELECT M_Consumerid FROM BLoyaltyPointsEarned WITH (NOLOCK) WHERE compid = @Comp_Id
    ) x
    WHERE M_ConsumerId IS NOT NULL;

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
        SELECT M_ConsumerId, VRKbl_KYC_status, ROW_NUMBER() OVER (PARTITION BY M_ConsumerId ORDER BY Entry_date DESC) as rn
        FROM tbl_VendorViseKYCStatus WITH (NOLOCK)
        WHERE Comp_Id = @Comp_Id
    ) V ON V.M_ConsumerId = C.M_ConsumerId AND V.rn = 1
    WHERE MC.IsDelete = 0;

    CREATE CLUSTERED INDEX IX_Users_ConsumerId ON #Users(M_ConsumerId);
    CREATE INDEX IX_Users_MobileNo ON #Users(MobileNo);

    -- Searchable Mobile Number Index for SARGable index seeks
    CREATE TABLE #UserMobiles (MobileNo NVARCHAR(50) PRIMARY KEY, M_ConsumerId INT);
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
    -- PRECISE POINT CALCULATION (OPTIMIZED)
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

    -- 1. Get Enquiries (Source: Pro_Enq using SARGable Index Seek)
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
    INNER JOIN @CompanyList CL ON PR.Comp_Id = CL.Comp_Id
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
    WHERE PE.Is_Success = '1'
      AND SS.Service_ID IN ('SRV1001', 'SRV1029')
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
      AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))
      AND (@StartDate IS NULL OR PE.Enq_Date >= @StartDate)
      AND (@EndDate   IS NULL OR PE.Enq_Date < @EndDate);

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
        INNER JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
        INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
        WHERE MC.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)
          AND SS.Service_ID IN ('SRV1001', 'SRV1029')
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
          AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))

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
        INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
        INNER JOIN @CompanyList CL ON PR.Comp_ID = CL.Comp_Id
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
        WHERE BL.compid IS NULL
          AND MC.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)
          AND SS.Service_ID IN ('SRV1001', 'SRV1029')
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
          AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))
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
    INNER JOIN @CompanyList CL ON SS.Comp_Id = CL.Comp_Id
    WHERE US.rn = 1
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1029')
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
    LEFT JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
    WHERE BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND (BL.compid IS NULL OR CL.Comp_Id IS NOT NULL)
      AND BL.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)
      AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR BL.UpdateDate < @EndDate)
    GROUP BY BL.M_Consumerid;

    CREATE CLUSTERED INDEX IX_OtherEarnedPoints_ConsumerId ON #OtherEarnedPoints(M_Consumerid);

    ---------------------------------------------------------
    -- REFERRAL CALCULATION (OPTIMIZED)
    ---------------------------------------------------------
    SELECT 
        BL.M_Consumerid,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS ReferralAmount
    INTO #Referrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
    WHERE LOWER(BL.ServiceName) IN ('refral', 'referral')
      AND BL.M_Consumerid IN (SELECT M_ConsumerId FROM #Users)
      AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR BL.UpdateDate < @EndDate)
    GROUP BY BL.M_Consumerid;

    CREATE CLUSTERED INDEX IX_Referrals_ConsumerId ON #Referrals(M_Consumerid);

    ---------------------------------------------------------
    -- TDS AMOUNT FROM ALL APPROVED CLAIMS
    ---------------------------------------------------------
    SELECT 
        U.M_ConsumerId,
        SUM(ISNULL(CD.tdsAmount,0)) AS TDSAmount
    INTO #TDS
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON CD.Comp_id = CL.Comp_Id
    INNER JOIN #UserMobiles UM ON CD.Mobileno = UM.MobileNo
    INNER JOIN #Users U ON UM.M_ConsumerId = U.M_ConsumerId
    WHERE CD.Isapproved = 1
      AND CD.Service_ID IN ('SRV1001', 'SRV1029')
      AND (CD.action_date IS NULL OR ((@StartDate IS NULL OR CD.action_date >= @StartDate) AND (@EndDate IS NULL OR CD.action_date < @EndDate)))
    GROUP BY U.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_TDS_ConsumerId ON #TDS(M_ConsumerId);

    ---------------------------------------------------------
    -- CLAIMS (CALCULATED IN POINTS)
    ---------------------------------------------------------
    SELECT
        U.M_ConsumerId,
        SUM(CD.Amount) AS ClaimsPoints
    INTO #Claims
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON CD.Comp_id = CL.Comp_Id
    INNER JOIN #UserMobiles UM ON CD.Mobileno = UM.MobileNo
    INNER JOIN #Users U ON UM.M_ConsumerId = U.M_ConsumerId
    WHERE CD.Isapproved = 1
      AND CD.Service_ID IN ('SRV1001', 'SRV1029')
      AND (CD.action_date IS NULL OR ((@StartDate IS NULL OR CD.action_date >= @StartDate) AND (@EndDate IS NULL OR CD.action_date < @EndDate)))
    GROUP BY U.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_Claims_ConsumerId ON #Claims(M_ConsumerId);

    ---------------------------------------------------------
    -- UPI
    ---------------------------------------------------------
    SELECT
        U.M_ConsumerId,
        SUM(ISNULL(UT.Amount,0)) AS UPIAmount
    INTO #UPI
    FROM tblUPITransactionDetails UT WITH (NOLOCK)
    INNER JOIN #UserMobiles UM ON UT.MobileNo = UM.MobileNo
    INNER JOIN #Users U ON UM.M_ConsumerId = U.M_ConsumerId
    INNER JOIN M_Code M WITH (NOLOCK) ON UT.Code1 = M.Code1 AND UT.Code2 = M.Code2
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
    WHERE UT.Comp_Id = @Comp_Id
      AND UT.Status = 'Success'
      AND SS.Service_ID IN ('SRV1001', 'SRV1029')
      AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
      AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))
      AND (@StartDate IS NULL OR UT.ReqDate >= @StartDate)
      AND (@EndDate   IS NULL OR UT.ReqDate <  @EndDate)
    GROUP BY U.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_UPI_ConsumerId ON #UPI(M_ConsumerId);

    ---------------------------------------------------------
    -- BPOINTS TRANSACTION
    ---------------------------------------------------------
    SELECT
        BT.RedeemBy AS M_ConsumerId,
        SUM(ISNULL(BT.RedeemPoints, 0)) AS BPointsAmount
    INTO #BPoints
    FROM BPointsTransaction BT WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON BT.companyid = CL.Comp_Id
    LEFT JOIN ClaimDetails CD WITH (NOLOCK) ON BT.Transsctionid = CD.Row_id
    WHERE BT.bpstatus IN ('Accepted', 'SUCCESS')
      AND (CD.Service_ID IS NULL OR CD.Service_ID IN ('SRV1001', 'SRV1029'))
      AND BT.RedeemBy IN (SELECT M_ConsumerId FROM #Users)
      AND (@StartDate IS NULL OR BT.Redeemdate >= @StartDate)
      AND (@EndDate   IS NULL OR BT.Redeemdate <  @EndDate)
    GROUP BY BT.RedeemBy;

    CREATE CLUSTERED INDEX IX_BPoints_ConsumerId ON #BPoints(M_ConsumerId);

    ---------------------------------------------------------
    -- FINAL DATA
    ---------------------------------------------------------
    IF LTRIM(RTRIM(ISNULL(@KYCStatusFilter, ''))) = '' OR @KYCStatusFilter = 'null' SET @KYCStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'null' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;

    SELECT
        U.ConsumerName,
        U.MobileNo,
        ISNULL(S.State, U.State) AS State,
        ISNULL(S.City,  U.City)  AS City,
        U.PinCode,
        U.KYCStatus,
        ISNULL(B.Benefit,0) + ISNULL(O.OtherPoints, 0) AS PointsEarned,
        ISNULL(R.ReferralAmount,0) AS RefralAmount,
        ISNULL(BP.BPointsAmount, 0) + ISNULL(C.ClaimsPoints, 0) + ISNULL(UU.UPIAmount, 0) AS RedeemAmount,
        ISNULL(B.Benefit, 0) + ISNULL(O.OtherPoints, 0) + ISNULL(R.ReferralAmount, 0) - (
            ISNULL(BP.BPointsAmount, 0) + ISNULL(C.ClaimsPoints, 0) + ISNULL(UU.UPIAmount, 0)
        ) AS BalanceAmount,
        ISNULL(TDS.TDSAmount, 0) AS TDSAmount,
        B.LastScan,
        ROW_NUMBER() OVER (ORDER BY ISNULL(B.Benefit,0) + ISNULL(O.OtherPoints, 0) DESC, U.M_ConsumerId) AS RN
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State   S  ON S.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Benefit B  ON B.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #OtherEarnedPoints O ON O.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Referrals R ON R.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Claims  C  ON C.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #TDS     TDS ON TDS.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #UPI     UU ON UU.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #BPoints BP ON BP.M_ConsumerId = U.M_ConsumerId
    WHERE
        (
            -- Admin view: show positive activity OR non-zero balance
            (ISNULL(B.Benefit, 0) > 0 OR ISNULL(R.ReferralAmount, 0) > 0 OR ISNULL(O.OtherPoints, 0) > 0)
            OR
            (ISNULL(B.Benefit, 0) + ISNULL(O.OtherPoints, 0) + ISNULL(R.ReferralAmount, 0) - (ISNULL(BP.BPointsAmount, 0) + ISNULL(C.ClaimsPoints, 0) + ISNULL(UU.UPIAmount, 0)) <> 0)
        )
        AND
        (
            @BalanceLessThan IS NULL OR 
            (ISNULL(B.Benefit, 0) + ISNULL(O.OtherPoints, 0) + ISNULL(R.ReferralAmount, 0) - (ISNULL(BP.BPointsAmount, 0) + ISNULL(C.ClaimsPoints, 0) + ISNULL(UU.UPIAmount, 0)) < @BalanceLessThan)
        )
        AND (@StateFilter IS NULL OR ISNULL(S.State, U.State) = @StateFilter)
        AND (
            @KYCStatusFilter IS NULL OR
            (@KYCStatusFilter = 'Approved' AND U.VRKbl_KYC_status = 1) OR
            (@KYCStatusFilter = 'Rejected' AND U.VRKbl_KYC_status = 2) OR
            (@KYCStatusFilter = 'Pending'  AND ISNULL(U.VRKbl_KYC_status,0) NOT IN (1,2))
        )
        AND (
            @Search IS NULL OR
            U.ConsumerName LIKE '%' + @Search + '%' OR
            U.MobileNo     LIKE '%' + @Search + '%' OR
            U.City         LIKE '%' + @Search + '%' OR
            U.State        LIKE '%' + @Search + '%'
        );

    ---------------------------------------------------------
    -- PAGED RESULT
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT
            ConsumerName, MobileNo, State, City, PinCode, KYCStatus,
            PointsEarned, RefralAmount, RedeemAmount, BalanceAmount, TDSAmount, LastScan
        FROM #FinalData
        ORDER BY RN;
    END
    ELSE
    BEGIN
        SELECT
            ConsumerName, MobileNo, State, City, PinCode, KYCStatus,
            PointsEarned, RefralAmount, RedeemAmount, BalanceAmount, TDSAmount, LastScan
        FROM #FinalData
        WHERE RN BETWEEN @Offset + 1 AND (@Offset + @Limit)
        ORDER BY RN;

        SELECT
            COUNT(*)                         AS TotalRecords,
            @Page                            AS CurrentPage,
            @Limit                           AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
