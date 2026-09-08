USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- [dbo].[SP_BL_GetBeneficiariesReport]
-- Logic isolated for Comp-1669 without modifying any other company logic
-- Author: Antigravity
-- Date: 2026-09-04
-- ============================================================================
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
    IF @Comp_Id IN ('Comp-1567','Comp-1650')
        INSERT INTO @CompanyList VALUES ('Comp-1567'),('Comp-1650');
    ELSE
        INSERT INTO @CompanyList VALUES (@Comp_Id);

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
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
    DROP TABLE IF EXISTS #SearchMatchingUsers, #Candidates, #Users, #UserMobiles, #ConsumerMapping, #State, #Benefit, #OtherEarnedPoints, #Referrals, #Claims, #UPI, #BPoints, #Transactions, #FinalData, #UniqueScans, #EarnedPoints, #ConfigPoints;

    -- Normalize filters early
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@KYCStatusFilter, ''))) = '' OR @KYCStatusFilter = 'null' SET @KYCStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'null' SET @StateFilter = NULL;

    ---------------------------------------------------------
    -- 1. EARLY CANDIDATE SEARCH FILTER
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
        )
        AND IsDelete = 0;
    END

    ---------------------------------------------------------
    -- 2. CANDIDATE USERS FOR THIS COMPANY (ISDELETE = 0 ONLY)
    ---------------------------------------------------------
    SELECT DISTINCT x.M_ConsumerId
    INTO #Candidates
    FROM (
        SELECT M_consumerId AS M_ConsumerId FROM tbl_VendorViseKYCStatus WITH (NOLOCK) WHERE Comp_id IN (SELECT Comp_Id FROM @CompanyList)
        UNION
        SELECT MC.M_ConsumerId FROM ClaimDetails CD WITH (NOLOCK) INNER JOIN M_Consumer MC WITH (NOLOCK) ON CD.Mobileno = MC.MobileNo AND MC.IsDelete = 0 WHERE CD.Comp_Id IN (SELECT Comp_Id FROM @CompanyList)
        UNION
        SELECT M_Consumerid AS M_ConsumerId FROM BLoyaltyPointsEarned WITH (NOLOCK) WHERE compid IN (SELECT Comp_Id FROM @CompanyList)
        UNION
        SELECT M_Consumerid AS M_ConsumerId FROM M_Consumer_M_Code WITH (NOLOCK) WHERE Compid IN (SELECT Comp_Id FROM @CompanyList)
        UNION
        SELECT TRY_CAST(M_CounserID AS INT) AS M_ConsumerId FROM Transactions WITH (NOLOCK) WHERE (CompId IN (SELECT REPLACE(Comp_Id, 'Comp-', '') FROM @CompanyList) OR CompId IN (SELECT Comp_Id FROM @CompanyList)) AND Issuccess = 1
        UNION
        SELECT TRY_CAST(t.M_Consumerid AS INT) AS M_ConsumerId FROM tblUPITransactionDetails t WITH (NOLOCK) WHERE t.Comp_Id IN (SELECT Comp_Id FROM @CompanyList) AND t.Status = 'Success'
    ) x
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON x.M_ConsumerId = MC.M_ConsumerId AND MC.IsDelete = 0
    WHERE x.M_ConsumerId IS NOT NULL
      AND (@Search IS NULL OR x.M_ConsumerId IN (SELECT M_ConsumerId FROM #SearchMatchingUsers));

    CREATE CLUSTERED INDEX IX_Candidates_ConsumerId ON #Candidates(M_ConsumerId);

    ---------------------------------------------------------
    -- 3. USERS + KYC
    ---------------------------------------------------------
    SELECT DISTINCT
        C.M_ConsumerId,
        MC.ConsumerName,
        CASE 
            WHEN LEN(LTRIM(RTRIM(ISNULL(MC.MobileNo, '')))) >= 10 
            THEN RIGHT(LTRIM(RTRIM(MC.MobileNo)), 10) 
            ELSE LTRIM(RTRIM(ISNULL(MC.MobileNo, ''))) 
        END AS MobileNo,
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
        WHERE Comp_id IN (SELECT Comp_Id FROM @CompanyList)
    ) V ON V.M_ConsumerId = C.M_ConsumerId AND V.rn = 1
    WHERE MC.IsDelete = 0;

    CREATE CLUSTERED INDEX IX_Users_ConsumerId ON #Users(M_ConsumerId);
    CREATE INDEX IX_Users_MobileNo ON #Users(MobileNo);

    -- Searchable Mobile Number Index
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

    -- Map all M_ConsumerId records of the same MobileNo (including deleted/previous registrations) to the active M_ConsumerId
    CREATE TABLE #ConsumerMapping 
    (
        M_ConsumerId INT,
        Active_ConsumerId INT
    );

    INSERT INTO #ConsumerMapping (M_ConsumerId, Active_ConsumerId)
    SELECT DISTINCT 
        MC.M_ConsumerId, 
        UM.M_ConsumerId AS Active_ConsumerId
    FROM #UserMobiles UM
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = UM.MobileNo;

    CREATE CLUSTERED INDEX IX_ConsumerMapping_ConsumerId ON #ConsumerMapping(M_ConsumerId);
    CREATE INDEX IX_ConsumerMapping_Active ON #ConsumerMapping(Active_ConsumerId);

    ---------------------------------------------------------
    -- 4. LATEST STATE / CITY FROM GEOLOCATION
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
        WHERE GE.Comp_Id IN (SELECT Comp_Id FROM @CompanyList)
    ) x
    WHERE rn = 1;

    CREATE CLUSTERED INDEX IX_State_ConsumerId ON #State(M_ConsumerId);

    ---------------------------------------------------------
    -- 5. POINT CALCULATION (ISOLATED FOR COMP-1669)
    ---------------------------------------------------------
    CREATE TABLE #Benefit
    (
        M_Consumerid INT,
        PointsEarned DECIMAL(18,2),
        LastScan DATETIME
    );
    CREATE CLUSTERED INDEX IX_Benefit_ConsumerId ON #Benefit(M_Consumerid);

    CREATE TABLE #OtherEarnedPoints
    (
        M_ConsumerId INT,
        OtherPoints DECIMAL(18,2)
    );
    CREATE CLUSTERED INDEX IX_OtherEarnedPoints_ConsumerId ON #OtherEarnedPoints(M_ConsumerId);

    IF @Comp_Id = 'Comp-1669'
    BEGIN
        -- ISOLATED SPECIFICALLY FOR COMP-1669 (Multi-Service Head & Assistant Mechanics)
        INSERT INTO #Benefit (M_Consumerid, PointsEarned, LastScan)
        SELECT 
            CM.Active_ConsumerId AS M_Consumerid,
            SUM(CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2))) AS PointsEarned,
            MAX(BL.UpdateDate) AS LastScan
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId
        WHERE BL.compid = 'Comp-1669'
          AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
          AND (@EndDate   IS NULL OR BL.UpdateDate <  @EndDate)
          AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
        GROUP BY CM.Active_ConsumerId;
    END
    ELSE
    BEGIN
        -- STANDARD LOGIC FOR ALL OTHER COMPANIES (100% UNTOUCHED)
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
        WHERE PR.Comp_Id IN (SELECT Comp_Id FROM @CompanyList)
          AND PE.Is_Success = '1'
          AND (@StartDate IS NULL OR PE.Enq_Date >= @StartDate)
          AND (@EndDate IS NULL OR PE.Enq_Date < @EndDate);

        CREATE INDEX IX_UniqueScans_MCodeid ON #UniqueScans(M_Codeid) WHERE rn = 1;
        CREATE INDEX IX_UniqueScans_MobileNo ON #UniqueScans(MobileNo) WHERE rn = 1;

        SELECT
            M_Codeid,
            MAX(Points) AS Points
        INTO #EarnedPoints
        FROM (
            SELECT
                MC.M_Codeid,
                CAST(
                    CASE 
                        WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                        WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                        ELSE ISNULL(BL.Points, 0)
                    END 
                AS DECIMAL(18,2)) AS Points
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
            INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK)
                ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
            INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
                ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
            INNER JOIN #ConsumerMapping CM ON MC.M_Consumerid = CM.M_ConsumerId
            WHERE BL.compid IN (SELECT Comp_Id FROM @CompanyList)

            UNION ALL

            SELECT
                MC.M_Codeid,
                CAST(
                    CASE 
                        WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
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
            INNER JOIN #ConsumerMapping CM ON MC.M_Consumerid = CM.M_ConsumerId
            WHERE BL.compid IS NULL
              AND PR.Comp_ID IN (SELECT Comp_Id FROM @CompanyList)
        ) x
        GROUP BY M_Codeid;

        CREATE CLUSTERED INDEX IX_EarnedPoints_MCodeid ON #EarnedPoints(M_Codeid);

        SELECT 
            US.M_Codeid,
            MAX(CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                    ELSE ISNULL(SST.IsCash, 0) * @Multiplier
                END 
            AS DECIMAL(18,2))) AS ConfigPoints
        INTO #ConfigPoints
        FROM #UniqueScans US
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        WHERE US.rn = 1
          AND SS.Comp_Id IN (SELECT Comp_Id FROM @CompanyList)
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
          AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
          AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
        GROUP BY US.M_Codeid;

        CREATE CLUSTERED INDEX IX_ConfigPoints_MCodeid ON #ConfigPoints(M_Codeid);

        INSERT INTO #Benefit (M_Consumerid, PointsEarned, LastScan)
        SELECT
            MC.M_ConsumerId,
            SUM(CASE WHEN ISNULL(P.Points, 0) > 0 THEN P.Points ELSE ISNULL(CP.ConfigPoints, 0) END) AS PointsEarned,
            MAX(US.Enq_Date) AS LastScan
        FROM #UniqueScans US
        INNER JOIN #UserMobiles UM ON US.MobileNo = UM.MobileNo
        INNER JOIN #Users MC ON UM.M_ConsumerId = MC.M_ConsumerId
        LEFT JOIN #EarnedPoints P ON P.M_Codeid = US.M_Codeid
        LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = US.M_Codeid
        WHERE US.rn = 1
        GROUP BY MC.M_ConsumerId;

        INSERT INTO #OtherEarnedPoints (M_ConsumerId, OtherPoints)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            SUM(CAST(
                CASE 
                    WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2))) AS OtherPoints
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId
        WHERE BL.compid IN (SELECT Comp_Id FROM @CompanyList)
          AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
          AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
          AND (@EndDate   IS NULL OR BL.UpdateDate <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END

    ---------------------------------------------------------
    -- 6. REFERRAL POINTS
    ---------------------------------------------------------
    SELECT
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(ISNULL(BL.Points, 0) + ISNULL(BL.Cash, 0)) AS RefralAmount
    INTO #Referrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId
    WHERE BL.compid IN (SELECT Comp_Id FROM @CompanyList)
      AND (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
      AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR BL.UpdateDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    CREATE CLUSTERED INDEX IX_Referrals_ConsumerId ON #Referrals(M_ConsumerId);

    ---------------------------------------------------------
    -- 7. REDEEM AMOUNT (CLAIMS)
    ---------------------------------------------------------
    SELECT
        U.M_ConsumerId,
        SUM(CD.Amount) AS ClaimRedeem
    INTO #Claims
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN #UserMobiles UM ON CD.Mobileno = UM.MobileNo
    INNER JOIN #Users U ON UM.M_ConsumerId = U.M_ConsumerId
    WHERE CD.Comp_id IN (SELECT Comp_Id FROM @CompanyList)
      AND CD.PaymentStatus = 'Success'
      AND (@StartDate IS NULL OR CD.Claim_date >= @StartDate)
      AND (@EndDate   IS NULL OR CD.Claim_date <  @EndDate)
    GROUP BY U.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_Claims_ConsumerId ON #Claims(M_ConsumerId);

    ---------------------------------------------------------
    -- 8. REDEEM AMOUNT (UPI)
    ---------------------------------------------------------
    SELECT
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(TRY_CAST(ISNULL(t.Amount, t.Points_Val) AS DECIMAL(18,2))) AS UPIRedeem
    INTO #UPI
    FROM tblUPITransactionDetails t WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON TRY_CAST(t.M_Consumerid AS INT) = CM.M_ConsumerId
    WHERE t.Comp_Id IN (SELECT Comp_Id FROM @CompanyList)
      AND t.Status = 'Success'
      AND LEN(ISNULL(t.Code1, '')) > 3
      AND (@StartDate IS NULL OR t.ReqDate >= @StartDate)
      AND (@EndDate   IS NULL OR t.ReqDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    CREATE CLUSTERED INDEX IX_UPI_ConsumerId ON #UPI(M_ConsumerId);

    ---------------------------------------------------------
    -- 9. REDEEM AMOUNT (BPOINTSTRANSFER / TRANSACTIONS)
    ---------------------------------------------------------
    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(TRY_CAST(ISNULL(BT.RedeemPoints, 0) AS DECIMAL(18,2))) AS BPointsDebited
    INTO #BPoints
    FROM BPointsTransaction BT WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON BT.RedeemBy = CM.M_ConsumerId
    WHERE BT.companyid IN (SELECT Comp_Id FROM @CompanyList)
      AND BT.bpstatus IN ('Accepted', 'SUCCESS', 'Debit')
      AND (@StartDate IS NULL OR BT.Redeemdate >= @StartDate)
      AND (@EndDate   IS NULL OR BT.Redeemdate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    CREATE CLUSTERED INDEX IX_BPoints_ConsumerId ON #BPoints(M_ConsumerId);

    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(TRY_CAST(ISNULL(t.Amount, 0) AS DECIMAL(18,2))) AS TransactionsAmount
    INTO #Transactions
    FROM Transactions t WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON TRY_CAST(t.M_CounserID AS INT) = CM.M_ConsumerId
    WHERE (t.CompId IN (SELECT REPLACE(Comp_Id, 'Comp-', '') FROM @CompanyList) OR t.CompId IN (SELECT Comp_Id FROM @CompanyList))
      AND t.Issuccess = 1
      AND (@StartDate IS NULL OR t.TransactionDate >= @StartDate)
      AND (@EndDate   IS NULL OR t.TransactionDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    CREATE CLUSTERED INDEX IX_Transactions_ConsumerId ON #Transactions(M_ConsumerId);

    ---------------------------------------------------------
    -- 10. COMBINE FINAL DATA
    ---------------------------------------------------------
    SELECT
        U.ConsumerName,
        U.MobileNo,
        ISNULL(S.State, U.State) AS State,
        ISNULL(S.City, U.City) AS City,
        U.PinCode,
        U.KYCStatus,
        (ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00)) AS PointsEarned,
        ISNULL(R.RefralAmount, 0.00) AS RefralAmount,
        (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00)) AS RedeemAmount,
        ((ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00) + ISNULL(R.RefralAmount, 0.00)) - 
         (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))) AS BalanceAmount,
        B.LastScan
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State S ON U.M_ConsumerId = S.M_ConsumerId
    LEFT JOIN #Benefit B ON U.M_ConsumerId = B.M_ConsumerId
    LEFT JOIN #OtherEarnedPoints OEP ON U.M_ConsumerId = OEP.M_ConsumerId
    LEFT JOIN #Referrals R ON U.M_ConsumerId = R.M_ConsumerId
    LEFT JOIN #Claims CD ON U.M_ConsumerId = CD.M_ConsumerId
    LEFT JOIN #UPI UPI ON U.M_ConsumerId = UPI.M_ConsumerId
    LEFT JOIN #BPoints BP ON U.M_ConsumerId = BP.M_ConsumerId
    LEFT JOIN #Transactions T ON U.M_ConsumerId = T.M_ConsumerId
    WHERE (
        @KYCStatusFilter IS NULL OR
        (@KYCStatusFilter = 'Approved' AND U.KYCStatus = 'Approved') OR
        (@KYCStatusFilter = 'Rejected' AND U.KYCStatus = 'Rejected') OR
        (@KYCStatusFilter = 'Pending' AND (U.KYCStatus = 'Pending' OR U.KYCStatus IS NULL))
    )
    AND (
        @StateFilter IS NULL OR
        ISNULL(S.State, U.State) = @StateFilter
    )
    AND (
        (ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00)) > 0
        OR ISNULL(R.RefralAmount, 0.00) > 0
        OR (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00)) > 0
    );

    ---------------------------------------------------------
    -- 11. RESULT SETS
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
            BalanceAmount
        FROM #FinalData
        ORDER BY LastScan DESC, PointsEarned DESC;
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
            BalanceAmount
        FROM #FinalData
        ORDER BY LastScan DESC, PointsEarned DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
