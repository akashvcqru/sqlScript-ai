/****** Migration: 20260910_Update_Comp1669_Points_Calculation_After_Deduct_DateTime.sql ******/
-- Date: 2026-09-10
-- Purpose:
--   1. For Comp-1669:
--      - For BLoyaltyPointsEarned records with UpdateDate <= '2026-09-10 19:41:55.383', apply dbo.fnPointSp(Points) (10% formula / divide by 10).
--      - For BLoyaltyPointsEarned records with UpdateDate > '2026-09-10 19:41:55.383', points are already saved after deduction, so use Points directly without 10% function.
--   2. Preserve all calculations for other companies (100% isolated).
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
-- 1. [dbo].[SP_BL_GetBeneficiariesReport]
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
            SUM(CAST(
                CASE 
                    WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                            ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                    ELSE 0.00
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
        ORDER BY PointsEarned DESC, LastScan DESC;
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
        ORDER BY PointsEarned DESC, LastScan DESC
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

-- ============================================================================
-- 2. [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]
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
            SUM(CAST(
                CASE 
                    WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                            ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                    ELSE 0.00
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
        ORDER BY PointsEarned DESC, LastScan DESC;
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
        ORDER BY PointsEarned DESC, LastScan DESC
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

-- ============================================================================
-- 2. [dbo].[SP_BL_GetBeneficiariesReport_Admin_AI]
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
            SUM(CAST(
                CASE 
                    WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                            ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                    ELSE 0.00
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
    )
    AND (
        @BalanceLessThan IS NULL OR
        ((ISNULL(B.PointsEarned, 0.00) + ISNULL(OEP.OtherPoints, 0.00) + ISNULL(R.RefralAmount, 0.00)) - 
         CASE 
            WHEN @Comp_Id = 'Comp-1669' THEN ISNULL(PT.PaytmAmount, 0.00)
            ELSE (ISNULL(CD.ClaimRedeem, 0.00) + ISNULL(UPI.UPIRedeem, 0.00) + ISNULL(BP.BPointsDebited, 0.00) + ISNULL(T.TransactionsAmount, 0.00))
         END) < @BalanceLessThan
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
            BalanceAmount,
            LastScan
        FROM #FinalData
        ORDER BY PointsEarned DESC, LastScan DESC;
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
            LastScan
        FROM #FinalData
        ORDER BY PointsEarned DESC, LastScan DESC
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

-- ============================================================================
-- 3. [dbo].[SP_BL_GetCodesActivityReport_AI]
-- ============================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_AI]
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate DATE  = NULL,
    @ToDate DATE  = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,     -- Verified, Already Scanned, Invalid
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
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
        IF (@Win = '' OR @Win = 'NULL') SET @Win = 'ALL';

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, @StartDate);
        END
        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
            SET @EndDate   = DATEADD(DAY, 1, @StartDate);
        END
        ELSE IF (@Win = 'WEEK' OR @Win = 'THIS WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()) - 7, CAST(GETDATE() AS DATE)) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 7, @StartDate);
        END
        ELSE IF (@Win = 'MONTH' OR @Win = 'THIS MONTH')
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME));
            SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
        END
        ELSE IF (@Win = 'QUARTER' OR @Win = 'THIS QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            SET @EndDate   = DATEADD(QUARTER, 1, @StartDate);
        END
        ELSE IF (@Win = 'LASTQUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, 1, @StartDate);
        END
        ELSE IF (@Win = 'YEAR' OR @Win = 'THIS YEAR')
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEADD(YEAR, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME));
            SET @EndDate   = DATEADD(YEAR, 1, @StartDate);
        END
        ELSE -- ALL
        BEGIN
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    ----------------------------------------------------
    -- Fetch Multiplier for Company
    ----------------------------------------------------
    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation WITH (NOLOCK)
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;

    ----------------------------------------------------
    -- Drop Temp Tables Safely
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Pro') IS NOT NULL DROP TABLE #Pro;
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;
    IF OBJECT_ID('tempdb..#MCode') IS NOT NULL DROP TABLE #MCode;
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;
    IF OBJECT_ID('tempdb..#Geo') IS NOT NULL DROP TABLE #Geo;
    IF OBJECT_ID('tempdb..#FinalData') IS NOT NULL DROP TABLE #FinalData;

    -- Product Master Cache
    SELECT Pro_ID, Pro_Name 
    INTO #Pro
    FROM Pro_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id;

    CREATE CLUSTERED INDEX IX_Pro_ProID ON #Pro(Pro_ID);

    ----------------------------------------------------
    -- 1. BASE ENQUIRIES (Filtered by Date Range & Search)
    ----------------------------------------------------
    SELECT 
        PE.Received_Code1,
        PE.Received_Code2,
        CASE 
            WHEN LEN(LTRIM(RTRIM(ISNULL(PE.MobileNo, '')))) >= 10 
            THEN RIGHT(LTRIM(RTRIM(PE.MobileNo)), 10) 
            ELSE LTRIM(RTRIM(ISNULL(PE.MobileNo, ''))) 
        END AS MobileNo,
        PE.Enq_Date,
        PE.Is_Success,
        PE.Dial_Mode,
        ISNULL(NULLIF(LTRIM(RTRIM(PE.Latitude)), ''), '0.00') AS Latitude,
        ISNULL(NULLIF(LTRIM(RTRIM(PE.Longitude)), ''), '0.00') AS Longitude,
        M.Row_ID AS M_Codeid,
        ROW_NUMBER() OVER (
            PARTITION BY PE.Received_Code1, PE.Received_Code2, PE.Is_Success 
            ORDER BY PE.Enq_Date ASC
        ) AS rn
    INTO #Enq
    FROM Pro_Enq PE WITH (NOLOCK)
    LEFT JOIN M_Code M WITH (NOLOCK) 
        ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
    LEFT JOIN #Pro PR 
        ON M.Pro_ID = PR.Pro_ID
    WHERE (PR.Pro_ID IS NOT NULL OR PE.Comp_ID = @Comp_Id)
      AND PE.Enq_Date >= @StartDate
      AND PE.Enq_Date <  @EndDate
      AND (
          @Search IS NULL OR
          PE.MobileNo LIKE '%' + @Search + '%' OR
          PE.Received_Code1 LIKE '%' + @Search + '%' OR
          PE.Received_Code2 LIKE '%' + @Search + '%'
      );

    CREATE CLUSTERED INDEX IX_Enq_MCodeid ON #Enq(M_Codeid);
    CREATE INDEX IX_Enq_Codes ON #Enq(Received_Code1, Received_Code2);
    CREATE INDEX IX_Enq_MobileNo ON #Enq(MobileNo);

    ----------------------------------------------------
    -- 2. MCODE DETAILS CACHE
    ----------------------------------------------------
    SELECT 
        M.Row_ID AS M_Codeid,
        M.Code1,
        M.Code2,
        M.Pro_ID,
        M.Series_Order,
        M.Series_Serial,
        M.LabelRequestId
    INTO #MCode
    FROM M_Code M WITH (NOLOCK)
    INNER JOIN (SELECT DISTINCT M_Codeid FROM #Enq WHERE M_Codeid IS NOT NULL) E 
        ON M.Row_ID = E.M_Codeid;

    CREATE CLUSTERED INDEX IX_MCode_MCodeid ON #MCode(M_Codeid);

    ----------------------------------------------------
    -- 3. POINTS & CASH CALCULATION (ISOLATED FOR COMP-1669)
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;
 
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
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
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
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
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
          AND (@Comp_Id <> 'Comp-1669' OR LOWER(ISNULL(BL.ServiceName, '')) IN ('buildloyalty', 'srv1001', 'srv1028', 'instant payout'))

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
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
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
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
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

    CREATE CLUSTERED INDEX IX_Points_MCodeid ON #Points(M_Codeid);
    CREATE INDEX IX_Points_Mobile ON #Points(MobileNo);

    ----------------------------------------------------
    -- 4. SCAN REFERRAL POINTS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#ScanReferrals') IS NOT NULL DROP TABLE #ScanReferrals;
    SELECT 
        CAST(C.Code1 AS VARCHAR(50)) AS Code1,
        CAST(C.Code2 AS VARCHAR(50)) AS Code2,
        SUM(ISNULL(BL.Points, 0) + ISNULL(BL.Cash, 0)) AS ReferralPoints
    INTO #ScanReferrals
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN M_Consumer_M_Code MCMC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MCMC.M_Consumer_MCodeid
    INNER JOIN M_Code C WITH (NOLOCK) ON MCMC.M_Codeid = C.Row_ID
    WHERE BL.compid = @Comp_Id
      AND (
          LOWER(ISNULL(BL.ServiceName, '')) LIKE '%refral%' 
          OR LOWER(ISNULL(BL.ServiceName, '')) LIKE '%referral%'
          OR LOWER(ISNULL(BL.Remarks, '')) LIKE '%refer%'
      )
    GROUP BY CAST(C.Code1 AS VARCHAR(50)), CAST(C.Code2 AS VARCHAR(50));

    CREATE INDEX IX_ScanReferrals ON #ScanReferrals(Code1, Code2);

    ----------------------------------------------------
    -- 5. CODE CONFIG POINTS (ISOLATED FOR COMP-1669)
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
    -- 6. GEOLOCATION (Matched via MobileNo)
    ----------------------------------------------------
    SELECT 
        G.MobileNo,
        G.State,
        G.City
    INTO #Geo
    FROM (
        SELECT 
            GE.MobileNo,
            GE.State,
            GE.City,
            ROW_NUMBER() OVER (PARTITION BY GE.MobileNo ORDER BY GE.Enq_Date DESC) AS rn
        FROM GeoLocationData GE WITH (NOLOCK)
        INNER JOIN (SELECT DISTINCT MobileNo FROM #Enq) E ON GE.MobileNo = E.MobileNo
        WHERE GE.Comp_Id = @Comp_Id
    ) G
    WHERE G.rn = 1;

    CREATE CLUSTERED INDEX IX_Geo_MobileNo ON #Geo(MobileNo);

    ----------------------------------------------------
    -- 7. COMBINE FINAL DATA
    ----------------------------------------------------
    SELECT
        E.Received_Code1 AS Code1,
        E.Received_Code2 AS Code2,
        E.Enq_Date,
        E.Dial_Mode,
        MC.ConsumerName,
        CASE 
            WHEN LEN(LTRIM(RTRIM(ISNULL(MC.MobileNo, '')))) >= 10 
            THEN RIGHT(LTRIM(RTRIM(MC.MobileNo)), 10) 
            ELSE ISNULL(MC.MobileNo, ISNULL(E.MobileNo,''))
        END AS MobileNo,
        G.State,cc.Vrkabel_User_Type,
        G.City,
        PR.Pro_Name,
        ISNULL(NULLIF(P.ServiceName, ''), ISNULL(CP.ServiceName, '')) AS ServiceName,
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
        ISNULL(SR.ReferralPoints, 0) AS ReferralPoints,
        ISNULL(MCd.LabelRequestId, '') AS LabelRequestId
    INTO #FinalData
    FROM #Enq E
    LEFT JOIN #MCode MCd ON E.M_Codeid = MCd.M_Codeid
    LEFT JOIN #Pro PR ON MCd.Pro_ID = PR.Pro_ID
    LEFT JOIN #Points P ON E.M_Codeid = P.M_Codeid AND (E.MobileNo = P.MobileNo OR P.MobileNo IS NULL)
    LEFT JOIN #ScanReferrals SR ON E.Received_Code1 = SR.Code1 AND E.Received_Code2 = SR.Code2
    LEFT JOIN #CodeConfigPoints CP ON E.M_Codeid = CP.M_Codeid
    LEFT JOIN #Geo G ON E.MobileNo = G.MobileNo
    LEFT JOIN M_Consumer MC WITH (NOLOCK) ON E.MobileNo = MC.MobileNo AND MC.IsDelete = 0
    LEFT JOIN tbl_Vendorvisekycstatus cc ON mc.M_Consumerid = cc.M_consumerId AND cc.comp_id = @comp_id
    WHERE (@StateFilter IS NULL OR G.State = @StateFilter)
      AND (@DialModeFilter IS NULL OR E.Dial_Mode = @DialModeFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          (@CodeStatusFilter = 'Verified' AND E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) OR
          (@CodeStatusFilter = 'Already Scanned' AND (E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1) AND ISNULL(P.Points, 0) = 0 AND ISNULL(P.WornPoint, 0) = 0))) OR
          (@CodeStatusFilter = 'Invalid' AND E.Is_Success NOT IN (1, 2))
      )
    UNION ALL
    SELECT
        CAST(ISNULL(C.Code1, '') AS VARCHAR(50)) AS Code1,
        CAST(ISNULL(C.Code2, '') AS VARCHAR(50)) AS Code2,
        BL.UpdateDate AS Enq_Date,
        '' AS Dial_Mode,
        MC.ConsumerName,
        CASE 
            WHEN LEN(LTRIM(RTRIM(ISNULL(MC.MobileNo, '')))) >= 10 
            THEN RIGHT(LTRIM(RTRIM(MC.MobileNo)), 10) 
            ELSE ISNULL(MC.MobileNo, '') 
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
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
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
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
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
    WHERE BL.compid = @Comp_Id
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate <  @EndDate
      AND (
          BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          OR LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('buildloyalty', 'srv1001', 'srv1028', 'instant payout')
      )
      AND (
          @Search IS NULL OR
          MC.MobileNo LIKE '%' + @Search + '%' OR
          ISNULL(MC.ConsumerName, '') LIKE '%' + @Search + '%' OR
          CAST(ISNULL(C.Code1, '') AS VARCHAR(50)) LIKE '%' + @Search + '%' OR
          CAST(ISNULL(C.Code2, '') AS VARCHAR(50)) LIKE '%' + @Search + '%'
      )
      AND (@StateFilter IS NULL OR MC.State = @StateFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          @CodeStatusFilter = 'Verified'
      )
    GROUP BY
        CAST(ISNULL(C.Code1, '') AS VARCHAR(50)),
        CAST(ISNULL(C.Code2, '') AS VARCHAR(50)),
        BL.UpdateDate,
        MC.ConsumerName,
        MC.MobileNo,
        MC.State,
        cc.Vrkabel_User_Type,
        MC.City,
        PR.Pro_Name,
        BL.ServiceName,
        MS.ServiceName,
        MCd.LabelRequestId;

    ----------------------------------------------------
    -- 8. RETURN RESULTS
    ----------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT
            Code1,
            Code2,
            Enq_Date,
            Dial_Mode,
            ConsumerName,
            MobileNo,
            State,
            City,
            Pro_Name,
            ServiceName,
            Points,
            Result,
            Latitude,
            Longitude,
            AssignPoint,
            WornPoint,
            ReferralPoints,
            LabelRequestId
        FROM #FinalData
        ORDER BY Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT
            Code1,
            Code2,
            Enq_Date,
            Dial_Mode,
            ConsumerName,
            MobileNo,
            State,
            City,
            Pro_Name,
            ServiceName,
            Points,
            Result,
            Latitude,
            Longitude,
            AssignPoint,
            WornPoint,
            ReferralPoints,
            LabelRequestId
        FROM #FinalData
        ORDER BY Enq_Date DESC
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

-- ============================================================================
-- 4. [dbo].[SP_Admin_GetCodesActivityReport_AI]
-- ============================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_Admin_GetCodesActivityReport_AI]
    @Comp_Id          VARCHAR(50) = NULL,
    @datePreset       NVARCHAR(20) = NULL,
    @FromDate         DATE = NULL,
    @ToDate           DATE = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,
    @StateFilter      NVARCHAR(100) = NULL,
    @DialModeFilter   NVARCHAR(50) = NULL,
    @Page             INT = NULL,
    @Limit            INT = NULL,
    @IsExport         BIT = NULL,
    @Search           NVARCHAR(30) = NULL
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
    -- Normalize Filters
    ----------------------------------------------------
    IF LTRIM(RTRIM(ISNULL(@Comp_Id, ''))) = '' OR @Comp_Id = 'null' SET @Comp_Id = NULL;
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'null' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' OR @DialModeFilter = 'null' SET @DialModeFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' OR @CodeStatusFilter = 'null' SET @CodeStatusFilter = NULL;

    ----------------------------------------------------
    -- Date Range Calculation
    ----------------------------------------------------
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
        IF (@Win = '' OR @Win = 'NULL') SET @Win = 'ALL';

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, @StartDate);
        END
        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
            SET @EndDate   = DATEADD(DAY, 1, @StartDate);
        END
        ELSE IF (@Win = 'WEEK' OR @Win = 'THIS WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()) - 7, CAST(GETDATE() AS DATE)) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 7, @StartDate);
        END
        ELSE IF (@Win = 'MONTH' OR @Win = 'THIS MONTH')
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME));
            SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
        END
        ELSE IF (@Win = 'QUARTER' OR @Win = 'THIS QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            SET @EndDate   = DATEADD(QUARTER, 1, @StartDate);
        END
        ELSE IF (@Win = 'LASTQUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, 1, @StartDate);
        END
        ELSE IF (@Win = 'YEAR' OR @Win = 'THIS YEAR')
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME);
            SET @EndDate   = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEADD(YEAR, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME));
            SET @EndDate   = DATEADD(YEAR, 1, @StartDate);
        END
        ELSE -- ALL
        BEGIN
            SET @StartDate = '2015-01-01';
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    ----------------------------------------------------
    -- Drop Temp Tables
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;
    IF OBJECT_ID('tempdb..#MCode') IS NOT NULL DROP TABLE #MCode;
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;
    IF OBJECT_ID('tempdb..#Config') IS NOT NULL DROP TABLE #Config;
    IF OBJECT_ID('tempdb..#Geo') IS NOT NULL DROP TABLE #Geo;
    IF OBJECT_ID('tempdb..#Final') IS NOT NULL DROP TABLE #Final;

    ----------------------------------------------------
    -- 1. BASE SCAN DATA FROM Pro_Enq
    ----------------------------------------------------
    SELECT 
        PE.Received_Code1,
        PE.Received_Code2,
        CASE 
            WHEN LEN(LTRIM(RTRIM(ISNULL(PE.MobileNo, '')))) >= 10 
            THEN RIGHT(LTRIM(RTRIM(PE.MobileNo)), 10) 
            ELSE LTRIM(RTRIM(ISNULL(PE.MobileNo, ''))) 
        END AS MobileNo,
        PE.Enq_Date,
        PE.Is_Success,
        PE.Dial_Mode,
        ISNULL(NULLIF(LTRIM(RTRIM(PE.Latitude)), ''), '') AS Latitude,
        ISNULL(NULLIF(LTRIM(RTRIM(PE.Longitude)), ''), '') AS Longitude,
        M.Row_ID AS M_Codeid,
        PR.Comp_ID AS Pro_CompId,
        CR.Comp_Name,
        PR.Pro_ID,
        PR.Pro_Name,
        M.Series_Order,
        M.Series_Serial,
        ROW_NUMBER() OVER (
            PARTITION BY PE.Received_Code1, PE.Received_Code2, PE.Is_Success 
            ORDER BY PE.Enq_Date ASC
        ) AS rn
    INTO #Enq
    FROM dbo.Pro_Enq PE WITH (NOLOCK)
    LEFT JOIN dbo.M_Code M WITH (NOLOCK) 
        ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
    LEFT JOIN dbo.Pro_Reg PR WITH (NOLOCK) 
        ON M.Pro_ID = PR.Pro_ID
    LEFT JOIN dbo.Comp_Reg CR WITH (NOLOCK) 
        ON PR.Comp_ID = CR.Comp_ID
    WHERE (@Comp_Id IS NULL OR PR.Comp_ID = @Comp_Id OR PE.Comp_ID = @Comp_Id)
      AND PE.Enq_Date >= @StartDate
      AND PE.Enq_Date <  @EndDate
      AND (
          @Search IS NULL OR
          PE.MobileNo LIKE '%' + @Search + '%' OR
          PE.Received_Code1 LIKE '%' + @Search + '%' OR
          PE.Received_Code2 LIKE '%' + @Search + '%'
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
                WHEN BL.compid = 'Comp-1669' AND BL.Points IS NOT NULL AND BL.Points > 0 THEN 
                    CASE 
                        WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](BL.Points)
                        ELSE CAST(BL.Points AS DECIMAL(18,2))
                    END
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
    WHERE (@Comp_Id IS NULL OR BL.compid = @Comp_Id)
    GROUP BY MC.M_Codeid, E.MobileNo;

    CREATE INDEX IX_Points_MCode ON #Points(M_Codeid);

    ----------------------------------------------------
    -- 4. CONFIG POINTS
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Config') IS NOT NULL DROP TABLE #Config;

    SELECT 
        E.M_Codeid,
        MAX(ISNULL(SST.Frequency, 1)) AS Frequency,
        MAX(CAST(
            CASE 
                WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                ELSE ISNULL(SST.IsCash, 0)
            END AS DECIMAL(18,2)
        )) AS ConfigPoints,
        SUM(ISNULL(SST.Frequency, 1)) AS TotalFrequency,
        MAX(S.ServiceName) AS ServiceName
    INTO #Config
    FROM (SELECT DISTINCT M_Codeid, Pro_ID, Series_Order, Series_Serial FROM #Enq WHERE M_Codeid IS NOT NULL) E
    INNER JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = E.Pro_ID
    INNER JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    LEFT JOIN dbo.M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
    WHERE SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
      AND (E.Series_Order > SS.start_order OR (E.Series_Order = SS.start_order AND E.Series_Serial >= SS.start_series))
      AND (E.Series_Order < SS.end_order OR (E.Series_Order = SS.end_order AND E.Series_Serial <= SS.end_series))
    GROUP BY E.M_Codeid;

    CREATE INDEX IX_Config_MCode ON #Config(M_Codeid);

    ----------------------------------------------------
    -- 5. GEOLOCATION
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Geo') IS NOT NULL DROP TABLE #Geo;

    SELECT 
        G.MobileNo,
        G.State,
        G.City
    INTO #Geo
    FROM (
        SELECT 
            GE.MobileNo,
            GE.State,
            GE.City,
            ROW_NUMBER() OVER (PARTITION BY GE.MobileNo ORDER BY GE.Enq_Date DESC) AS rn
        FROM dbo.GeoLocationData GE WITH (NOLOCK)
        INNER JOIN (SELECT DISTINCT MobileNo FROM #Enq) E ON GE.MobileNo = E.MobileNo
        WHERE (@Comp_Id IS NULL OR GE.Comp_Id = @Comp_Id)
    ) G
    WHERE G.rn = 1;

    CREATE INDEX IX_Geo_Mobile ON #Geo(MobileNo);

    ----------------------------------------------------
    -- 6. COMBINE ALL DATA INTO #Final
    ----------------------------------------------------
    SELECT
        E.Pro_CompId AS Comp_Id,
        ISNULL(E.Comp_Name, '') AS Comp_Name,
        E.Received_Code1 AS Code1,
        E.Received_Code2 AS Code2,
        E.MobileNo,
        ISNULL(MC.ConsumerName, '') AS ConsumerName,
        ISNULL(G.State, ISNULL(MC.State, '')) AS State,
        ISNULL(G.City, ISNULL(MC.City, '')) AS City,
        ISNULL(E.Pro_Name, '') AS Pro_Name,
        ISNULL(NULLIF(P.ServiceName, ''), ISNULL(CP.ServiceName, '')) AS ServiceName,
        E.Enq_Date,
        E.Dial_Mode,
        CAST(
            CASE 
                WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0) THEN 
                    CASE WHEN ISNULL(P.Points, 0) > 0 THEN P.Points ELSE ISNULL(CP.ConfigPoints, 0) END
                ELSE 0 
            END AS VARCHAR(50)
        ) AS Points,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0) THEN 'Verified'
            WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1)) THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
        E.Latitude,
        E.Longitude
    INTO #Final
    FROM #Enq E
    LEFT JOIN #Points P ON E.M_Codeid = P.M_Codeid AND (E.MobileNo = P.MobileNo OR P.MobileNo IS NULL)
    LEFT JOIN #Config CP ON E.M_Codeid = CP.M_Codeid
    LEFT JOIN #Geo G ON E.MobileNo = G.MobileNo
    LEFT JOIN dbo.M_Consumer MC WITH (NOLOCK) ON E.MobileNo = MC.MobileNo AND MC.IsDelete = 0
    WHERE (@StateFilter IS NULL OR G.State = @StateFilter OR MC.State = @StateFilter)
      AND (@DialModeFilter IS NULL OR E.Dial_Mode = @DialModeFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          (@CodeStatusFilter = 'Verified' AND E.Is_Success = 1 AND (E.rn <= ISNULL(CP.TotalFrequency, 1) OR ISNULL(P.Points, 0) > 0)) OR
          (@CodeStatusFilter = 'Already Scanned' AND (E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.TotalFrequency, 1) AND ISNULL(P.Points, 0) = 0))) OR
          (@CodeStatusFilter = 'Invalid' AND E.Is_Success NOT IN (1, 2))
      )
    UNION ALL
    SELECT
        BL.compid AS Comp_Id,
        ISNULL(CR.Comp_Name, '') AS Comp_Name,
        CAST(ISNULL(C.Code1, '') AS VARCHAR(50)) AS Code1,
        CAST(ISNULL(C.Code2, '') AS VARCHAR(50)) AS Code2,
        CASE 
            WHEN LEN(LTRIM(RTRIM(ISNULL(MC.MobileNo, '')))) >= 10 
            THEN RIGHT(LTRIM(RTRIM(MC.MobileNo)), 10) 
            ELSE ISNULL(MC.MobileNo, '') 
        END AS MobileNo,
        ISNULL(MC.ConsumerName, '') AS ConsumerName,
        ISNULL(MC.State, '') AS State,
        ISNULL(MC.City, '') AS City,
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
                WHEN BL.compid = 'Comp-1669' AND BL.Points IS NOT NULL AND BL.Points > 0 THEN 
                    CASE 
                        WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](BL.Points)
                        ELSE CAST(BL.Points AS DECIMAL(18,2))
                    END
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
      AND BL.UpdateDate >= @StartDate
      AND BL.UpdateDate <  @EndDate
      AND (
          BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          OR LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('buildloyalty', 'srv1001', 'srv1028', 'instant payout')
      )
      AND (
          @Search IS NULL OR
          MC.MobileNo LIKE '%' + @Search + '%' OR
          ISNULL(MC.ConsumerName, '') LIKE '%' + @Search + '%' OR
          CAST(ISNULL(C.Code1, '') AS VARCHAR(50)) LIKE '%' + @Search + '%' OR
          CAST(ISNULL(C.Code2, '') AS VARCHAR(50)) LIKE '%' + @Search + '%'
      )
      AND (@StateFilter IS NULL OR MC.State = @StateFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          @CodeStatusFilter = 'Verified'
      )
    GROUP BY
        BL.compid,
        CR.Comp_Name,
        CAST(ISNULL(C.Code1, '') AS VARCHAR(50)),
        CAST(ISNULL(C.Code2, '') AS VARCHAR(50)),
        MC.MobileNo,
        MC.ConsumerName,
        MC.State,
        MC.City,
        PR.Pro_Name,
        BL.ServiceName,
        MS.ServiceName,
        BL.UpdateDate;

    ----------------------------------------------------
    -- 7. RETURN RESULTS
    ----------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT
            Comp_Id,
            Comp_Name,
            Code1,
            Code2,
            MobileNo,
            ConsumerName,
            State,
            City,
            Pro_Name,
            ServiceName,
            Enq_Date,
            Dial_Mode,
            Points,
            Result,
            Latitude,
            Longitude
        FROM #Final
        ORDER BY Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT
            Comp_Id,
            Comp_Name,
            Code1,
            Code2,
            MobileNo,
            ConsumerName,
            State,
            City,
            Pro_Name,
            ServiceName,
            Enq_Date,
            Dial_Mode,
            Points,
            Result,
            Latitude,
            Longitude
        FROM #Final
        ORDER BY Enq_Date DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #Final;
    END
END
GO
