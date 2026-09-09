/****** Migration: 20260909_Fix_Comp1669_Points_FnPointSp_In_Beneficiaries_And_CodesActivity_Reports.sql ******/
-- Date: 2026-09-09
-- Purpose:
--   1. Align Comp-1669 points calculation using dbo.fnPointSp(Points) across all Beneficiaries and Codes Activity report SPs.
--   2. Preserve exact points / cash calculations for all other companies (100% isolated).
--   3. Synchronizes:
--      - [dbo].[SP_BL_GetBeneficiariesReport]
--      - [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]
--      - [dbo].[SP_BL_GetCodesActivityReport_AI]
--      - [dbo].[SP_Admin_GetCodesActivityReport_AI]

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
    DROP TABLE IF EXISTS #SearchMatchingUsers, #Candidates, #Users, #UserMobiles, #ConsumerMapping, #State, #Benefit, #OtherEarnedPoints, #Referrals, #Claims, #UPI, #BPoints, #Transactions, #Paytm, #FinalData, #UniqueScans, #EarnedPoints, #ConfigPoints;

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
        UNION
        SELECT pt.M_Consumerid AS M_ConsumerId FROM paytmtransaction pt WITH (NOLOCK) WHERE @Comp_Id = 'Comp-1669' AND pt.compid = 'Comp-1669' AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
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
            CAST(
                ISNULL([dbo].[fnPointSp](SUM(ISNULL(BL.Points, 0))), 0.00) 
                + ISNULL(SUM(CAST(ISNULL(BL.Cash, 0) AS DECIMAL(18,2))), 0.00)
            AS DECIMAL(18,2)) AS PointsEarned,
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
    -- 9b. REDEEM AMOUNT (PAYTM - ISOLATED FOR COMP-1669 ONLY)
    ---------------------------------------------------------
    CREATE TABLE #Paytm
    (
        M_ConsumerId INT PRIMARY KEY,
        PaytmAmount DECIMAL(18,2)
    );

    IF @Comp_Id = 'Comp-1669'
    BEGIN
        INSERT INTO #Paytm (M_ConsumerId, PaytmAmount)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            SUM(TRY_CAST(ISNULL(pt.Amount, 0) AS DECIMAL(18,2))) AS PaytmAmount
        FROM paytmtransaction pt WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON pt.M_Consumerid = CM.M_ConsumerId
        WHERE pt.compid = 'Comp-1669'
          AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
          AND (@StartDate IS NULL OR pt.pdate >= @StartDate)
          AND (@EndDate   IS NULL OR pt.pdate <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END

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
        CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
            ELSE (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
        END AS RedeemAmount,
        ((ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00) + ISNULL(R.RefralAmount, 0.00)) - 
         CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
            ELSE (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
         END) AS BalanceAmount,
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
    LEFT JOIN #Paytm PT ON U.M_ConsumerId = PT.M_ConsumerId
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
        OR (CASE 
                WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
                ELSE (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
            END) > 0
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

GO

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]
-- Logic isolated for Comp-1669 without modifying any other company logic
-- Author: Antigravity
-- Date: 2026-09-04
-- ============================================================================
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
    DROP TABLE IF EXISTS #SearchMatchingUsers, #Candidates, #Users, #UserMobiles, #ConsumerMapping, #State, #Benefit, #OtherEarnedPoints, #Referrals, #Claims, #UPI, #BPoints, #Transactions, #Paytm, #FinalData, #UniqueScans, #EarnedPoints, #ConfigPoints;

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
        UNION
        SELECT pt.M_Consumerid AS M_ConsumerId FROM paytmtransaction pt WITH (NOLOCK) WHERE @Comp_Id = 'Comp-1669' AND pt.compid = 'Comp-1669' AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
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
            CAST(
                ISNULL([dbo].[fnPointSp](SUM(ISNULL(BL.Points, 0))), 0.00) 
                + ISNULL(SUM(CAST(ISNULL(BL.Cash, 0) AS DECIMAL(18,2))), 0.00)
            AS DECIMAL(18,2)) AS PointsEarned,
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
        CM.Active_ConsumerId AS M_Consumerid,
        SUM(CAST(
            CASE 
                WHEN @Comp_Id = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
            END 
        AS DECIMAL(18,2))) AS ReferralPoints
    INTO #Referrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN #ConsumerMapping CM ON BL.M_Consumerid = CM.M_ConsumerId
    WHERE BL.compid IN (SELECT Comp_Id FROM @CompanyList)
      AND LOWER(ISNULL(BL.ServiceName, '')) IN ('refral', 'referral')
      AND (@StartDate IS NULL OR BL.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR BL.UpdateDate <  @EndDate)
    GROUP BY CM.Active_ConsumerId;

    CREATE CLUSTERED INDEX IX_Referrals_ConsumerId ON #Referrals(M_Consumerid);

    ---------------------------------------------------------
    -- 7. REDEMPTIONS (CLAIMS, UPI, BPOINTS, TRANSACTIONS)
    ---------------------------------------------------------
    SELECT 
        U.M_ConsumerId,
        SUM(TRY_CAST(ISNULL(CD.Amount, 0) AS DECIMAL(18,2))) AS Transferred,
        SUM(TRY_CAST(ISNULL(CD.tdsAmount, 0) AS DECIMAL(18,2))) AS TDS
    INTO #Claims
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN #Users U ON CD.Mobileno = U.MobileNo
    WHERE CD.Comp_Id IN (SELECT Comp_Id FROM @CompanyList)
      AND CD.Isapproved = 1
      AND (@StartDate IS NULL OR CD.Claim_date >= @StartDate)
      AND (@EndDate   IS NULL OR CD.Claim_date <  @EndDate)
    GROUP BY U.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_Claims_ConsumerId ON #Claims(M_ConsumerId);

    SELECT 
        CM.Active_ConsumerId AS M_ConsumerId,
        SUM(TRY_CAST(ISNULL(t.Amount, t.Points_Val) AS DECIMAL(18,2))) AS UPIAmount
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
    -- 7e. REDEEM AMOUNT (PAYTM - ISOLATED FOR COMP-1669 ONLY)
    ---------------------------------------------------------
    CREATE TABLE #Paytm
    (
        M_ConsumerId INT PRIMARY KEY,
        PaytmAmount DECIMAL(18,2)
    );

    IF @Comp_Id = 'Comp-1669'
    BEGIN
        INSERT INTO #Paytm (M_ConsumerId, PaytmAmount)
        SELECT 
            CM.Active_ConsumerId AS M_ConsumerId,
            SUM(TRY_CAST(ISNULL(pt.Amount, 0) AS DECIMAL(18,2))) AS PaytmAmount
        FROM paytmtransaction pt WITH (NOLOCK)
        INNER JOIN #ConsumerMapping CM ON pt.M_Consumerid = CM.M_ConsumerId
        WHERE pt.compid = 'Comp-1669'
          AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
          AND (@StartDate IS NULL OR pt.pdate >= @StartDate)
          AND (@EndDate   IS NULL OR pt.pdate <  @EndDate)
        GROUP BY CM.Active_ConsumerId;
    END

    ---------------------------------------------------------
    -- 8. FINAL DATASET PREPARATION
    ---------------------------------------------------------
    SELECT 
        U.ConsumerName,
        U.MobileNo,
        COALESCE(S.State, U.State) AS State,
        COALESCE(S.City, U.City) AS City,
        U.PinCode,
        U.KYCStatus,
        (ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) AS PointsEarned,
        ISNULL(R.ReferralPoints, 0.00) AS RefralAmount,
        CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
            ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
        END AS RedeemAmount,
        (((ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) + ISNULL(R.ReferralPoints, 0.00)) - 
         CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
            ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
         END) AS BalanceAmount,
        ISNULL(C.TDS, 0.00) AS TDSAmount,
        B.LastScan,
        ROW_NUMBER() OVER (ORDER BY (ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) DESC, U.M_ConsumerId) AS RN
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State S ON S.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Benefit B ON B.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #OtherEarnedPoints O ON O.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Referrals R ON R.M_Consumerid = U.M_ConsumerId
    LEFT JOIN #Claims C ON C.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #UPI UPI ON UPI.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #BPoints BP ON BP.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Transactions T ON T.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Paytm PT ON PT.M_ConsumerId = U.M_ConsumerId
    WHERE (
            (ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) > 0 
            OR ISNULL(R.ReferralPoints, 0.00) > 0 
            OR (CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
                    ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
                END) > 0
          )
      AND (@KYCStatusFilter IS NULL OR U.KYCStatus = @KYCStatusFilter)
      AND (@StateFilter IS NULL OR S.State = @StateFilter OR (S.State IS NULL AND U.State = @StateFilter))
      AND (@BalanceLessThan IS NULL OR ((((ISNULL(B.PointsEarned, 0.00) + ISNULL(O.OtherPoints, 0.00)) + ISNULL(R.ReferralPoints, 0.00)) - 
           CASE 
                WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
                ELSE (ISNULL(C.Transferred, 0.00) + ISNULL(UPI.UPIAmount, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
           END) < @BalanceLessThan))
      AND (
          @Search IS NULL 
          OR LTRIM(RTRIM(@Search)) = ''
          OR U.ConsumerName LIKE '%' + @Search + '%'
          OR U.MobileNo LIKE '%' + @Search + '%'
          OR S.State LIKE '%' + @Search + '%'
          OR S.City LIKE '%' + @Search + '%'
      );

    ---------------------------------------------------------
    -- 9. OUTPUT
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

GO

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
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
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
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
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
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
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
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
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
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 
                CASE 
                    WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(P.Points, 0)
                    WHEN ISNULL(P.Points, 0) > 0 THEN P.Points 
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS Points,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 'Verified'
            WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1)) THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
			E.Latitude,
			E.Longitude,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 
                CASE 
                    WHEN ISNULL(CP.AssignPoint, 0) > 0 THEN CP.AssignPoint
                    WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint
                    ELSE ISNULL(CP.ConfigPoints, 0)
                END
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0) THEN 
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
		  (E.Is_Success != 1 OR E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)
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
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
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
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
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

USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_Admin_GetCodesActivityReport_AI]    Script Date: 9/7/2026 5:45:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Stored Procedure: SP_Admin_GetCodesActivityReport_AI
-- Purpose: Retrieves Codes Activity Report for Admin (system-wide or company-wise)
-- Used By: AdminVendorReportController (/api/AdminVendorReport/GetCodesActivityReportAdmin)
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
                WHEN BL.compid = 'Comp-1669' AND BL.Points IS NOT NULL AND BL.Points > 0 THEN [dbo].[fnPointSp](BL.Points)
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
                WHEN BL.compid = 'Comp-1669' AND BL.Points IS NOT NULL AND BL.Points > 0 THEN [dbo].[fnPointSp](BL.Points)
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

GO
