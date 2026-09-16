USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetDashboardSummary_AI_15092026]    Script Date: 9/15/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDashboardSummary_AI_15092026]
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
    SELECT TOP 1 @Multiplier = 1.00 + (calculation_value / 100.0) 
    FROM loyalty_calculation 
    WHERE comp_id = @CompID AND isactive = 1 AND isdelete = 0;

    ---------------------------------------------------------
    -- Use Temp Tables instead of CTEs to support multiple result sets
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#UserScans') IS NOT NULL DROP TABLE #UserScans;
    IF OBJECT_ID('tempdb..#EarnedPoints') IS NOT NULL DROP TABLE #EarnedPoints;
    IF OBJECT_ID('tempdb..#ConfigPoints') IS NOT NULL DROP TABLE #ConfigPoints;
    IF OBJECT_ID('tempdb..#ScanServices') IS NOT NULL DROP TABLE #ScanServices;
    IF OBJECT_ID('tempdb..#ConfiguredPoints') IS NOT NULL DROP TABLE #ConfiguredPoints;
    IF OBJECT_ID('tempdb..#ReferralStats') IS NOT NULL DROP TABLE #ReferralStats;

    SELECT 
        M.Row_ID as M_Codeid,
        M.Pro_ID,
        M.Series_Order,
        M.Series_Serial,
        ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2 ORDER BY PE.Enq_Date) as rn
    INTO #UserScans
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    INNER JOIN @CompanyList CL ON PR.Comp_Id = CL.Comp_Id
    WHERE RIGHT(PE.MobileNo, 10) = RIGHT(@MobileNo, 10)
      AND PE.Is_Success = '1';

    -- Get Earned Points (Scans)
    SELECT
        MC.M_Codeid, BL.UpdateDate,
        CASE WHEN @CompID = 'Comp-1669' THEN 'SRV1001' ELSE ISNULL(SS.Service_ID, 'SRV1001') END AS Service_ID,
        CAST(
            CASE 
                WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                WHEN @CompID = 'Comp-1669' THEN
                    CASE
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                        WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                        ELSE 0.00
                    END
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                ELSE NULL
            END 
        AS DECIMAL(18,2)) AS Points,
        BL.BLoyalty_PointEarnedID
    INTO #EarnedPointsRaw
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
        ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
        ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    INNER JOIN #UserScans US WITH (NOLOCK) 
        ON MC.M_Codeid = US.M_Codeid
    INNER JOIN Pro_Reg PR WITH (NOLOCK) 
        ON US.Pro_ID = PR.Pro_ID
    INNER JOIN @CompanyList CL 
        ON (BL.compid = CL.Comp_Id OR (ISNULL(BL.compid, '') = '' AND PR.Comp_ID = CL.Comp_Id))
    LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) 
        ON BL.SST_id = SST.SST_Id
    LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) 
        ON SST.Subscribe_Id = SS.Subscribe_Id
    WHERE (
          BL.M_Consumerid = @M_Consumerid 
          OR BL.M_Consumerid IN (
              SELECT M_Consumerid 
              FROM M_Consumer WITH (NOLOCK) 
              WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
          )
          OR EXISTS (
              SELECT 1 FROM M_Consumer WITH (NOLOCK) 
              WHERE M_Consumerid = MC.M_Consumerid AND RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
          )
      )
      AND (@CompID <> 'Comp-1669' OR LOWER(ISNULL(BL.ServiceName, '')) IN ('buildloyalty', 'srv1001'));

    -- Include orphan scan entries (code scan entries with BuildLoyaltyOrReferralMCodeCheckid for this consumer/company)
    INSERT INTO #EarnedPointsRaw (M_Codeid, UpdateDate, Service_ID, Points, BLoyalty_PointEarnedID)
    SELECT 
        MC.M_Codeid, BL.UpdateDate,
        ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
        CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                ELSE 0.00
            END AS DECIMAL(18,2)) AS Points,
        BL.BLoyalty_PointEarnedID
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON BL.SST_id = SST.SST_Id
    LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    WHERE BL.compid = @CompID
      AND BL.BLoyalty_PointEarnedID NOT IN (SELECT BLoyalty_PointEarnedID FROM #EarnedPointsRaw)
      AND (
          BL.M_Consumerid = @M_Consumerid 
          OR BL.M_Consumerid IN (SELECT M_Consumerid FROM M_Consumer WITH (NOLOCK) WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0)
      );

    IF OBJECT_ID('tempdb..#EarnedPoints') IS NOT NULL DROP TABLE #EarnedPoints;

    CREATE TABLE #EarnedPoints (
        M_Codeid BIGINT,
        rn BIGINT,
        Service_ID VARCHAR(50),
        Points DECIMAL(18,2),UpdateDate DATETIME
    );

    IF @CompID = 'Comp-1669'
    BEGIN
        INSERT INTO #EarnedPoints (M_Codeid, rn, Service_ID, Points,UpdateDate)
        SELECT
            M_Codeid,
            1 AS rn,
            Service_ID,
            SUM(Points) AS Points,UpdateDate
        FROM #EarnedPointsRaw
        GROUP BY M_Codeid, Service_ID,UpdateDate;
    END
    ELSE
    BEGIN
        INSERT INTO #EarnedPoints (M_Codeid, rn, Service_ID, Points,UpdateDate)
        SELECT
            M_Codeid,
            ROW_NUMBER() OVER (PARTITION BY M_Codeid ORDER BY BLoyalty_PointEarnedID ASC) AS rn,
            Service_ID,
            Points,UpdateDate
        FROM #EarnedPointsRaw;
    END

    DROP TABLE IF EXISTS #EarnedPointsRaw;

    CREATE CLUSTERED INDEX IX_EarnedPoints_MCodeid ON #EarnedPoints(M_Codeid, rn);

    -- Get Config Points
    SELECT 
        US.M_Codeid,
        SS.Service_ID,
        MAX(CAST(
            CASE 
                WHEN @CompID = 'Comp-1669' THEN
                    CASE 
                        WHEN SS.Service_ID = 'SRV1001' THEN ISNULL(SST.Points, 0)
                        WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                        ELSE 0.00
                    END
                WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                ELSE ISNULL(SST.IsCash, 0) * @Multiplier
            END 
        AS DECIMAL(18,2))) AS ConfigPoints,
        MAX(CAST(ISNULL(SST.IsCash, 0) AS DECIMAL(18,2))) AS ConfigCash,
        MAX(ISNULL(SST.Frequency, 1)) AS Frequency
    INTO #ConfigPoints
    FROM #UserScans US
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN @CompanyList CL ON SS.Comp_Id = CL.Comp_Id
    WHERE US.rn = 1
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
      AND (@CompID <> 'Comp-1669' OR SS.Service_ID = 'SRV1001')
      AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
      AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
    GROUP BY US.M_Codeid, SS.Service_ID;

    CREATE CLUSTERED INDEX IX_ConfigPoints_MCodeid ON #ConfigPoints(M_Codeid);

    SELECT M_Codeid, Service_ID INTO #ScanServices FROM #ConfigPoints
    UNION
    SELECT M_Codeid, Service_ID FROM #EarnedPoints;

	DECLARE @Vrkabel_User_Type INT = NULL;
    IF LOWER(@CompID) = 'comp-1669'
    BEGIN
        SELECT TOP 1 @Vrkabel_User_Type = TRY_CAST(Vrkabel_User_Type AS INT)
        FROM tbl_Vendorvisekycstatus WITH (NOLOCK)
        WHERE M_consumerId = @M_Consumerid 
          AND LOWER(Comp_id) = 'comp-1669'
          AND IsDelete = 0;
    END

    -- Aggregate into #ConfiguredPoints
    SELECT
        COALESCE(SS.Service_ID, 'SRV1001') AS Service_ID,
        SUM(
            CASE 
                WHEN LOWER(@CompID) = 'comp-1669' THEN ISNULL([dbo].[fnPointSp](EP.Points), 0)
                ELSE ISNULL(EP.Points, ISNULL(CP.ConfigPoints, 0))
            END
        ) AS ServiceTotalPoints,
        SUM(
            CASE 
                WHEN @CompID = 'Comp-1669' THEN 0.00
                ELSE ISNULL(CP.ConfigCash, 0)
            END
        ) AS ServiceTotalCash
    INTO #ConfiguredPoints
    FROM #UserScans US
    LEFT JOIN #ScanServices SS ON US.M_Codeid = SS.M_Codeid
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = SS.M_Codeid AND CP.Service_ID = SS.Service_ID
    LEFT JOIN #EarnedPoints EP ON EP.M_Codeid = SS.M_Codeid AND EP.Service_ID = SS.Service_ID AND (@CompID = 'Comp-1669' OR EP.rn = US.rn)
    WHERE US.rn <= ISNULL(CP.Frequency, 1)
    GROUP BY COALESCE(SS.Service_ID, 'SRV1001');

    -- Include orphan scan points that didn't join to #UserScans into #ConfiguredPoints
    INSERT INTO #ConfiguredPoints (Service_ID, ServiceTotalPoints, ServiceTotalCash)
    SELECT Service_ID, SUM(Points), 0
    FROM #EarnedPoints
    WHERE M_Codeid NOT IN (SELECT M_Codeid FROM #UserScans)
    GROUP BY Service_ID;

    ---------------------------------------------------------
    -- PRECISE POINT/CASH SUM FOR TOTAL (DUPLICATION FREE)
    ---------------------------------------------------------
    DECLARE @TotalConfigPoints DECIMAL(18,2) = 0;
    DECLARE @TotalConfigCash DECIMAL(18,2) = 0;

    SELECT 
        @TotalConfigPoints = ISNULL(SUM(ServiceTotalPoints), 0),
        @TotalConfigCash = ISNULL(SUM(ServiceTotalCash), 0)
    FROM #ConfiguredPoints;

    -- Referral Stats (TRUE referral points ONLY: BuildLoyaltyOrReferralMCodeCheckid IS NULL or ServiceName referral)
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
    INNER JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
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
          OR BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
      );

    ---------------------------------------------------------
    -- Calculate specific totals for this consumer
    DECLARE @BPointsAmount DECIMAL(18,2) = 0;
    SELECT @BPointsAmount = ISNULL(SUM(ISNULL(RedeemPoints, 0)), 0)
    FROM BPointsTransaction WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON companyid = CL.Comp_Id
    WHERE bpstatus IN ('Accepted', 'SUCCESS')
      AND RedeemBy = @M_Consumerid
      AND (@CompID <> 'Comp-1669' OR Redeemdate >= '2026-09-03 00:00:00.000');

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
      AND (@CompID <> 'Comp-1669' OR TransactionDate >= '2026-09-03 00:00:00.000');

    DECLARE @UPIAmount DECIMAL(18,2) = 0;
    SELECT @UPIAmount = ISNULL(SUM(ISNULL(Amount, 0)), 0)
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @CompID
      AND Status = 'Success'
      AND LEN(Code1) > 3
      AND M_Consumerid = CAST(@M_Consumerid AS VARCHAR(50))
      AND (@CompID <> 'Comp-1669' OR ReqDate >= '2026-09-03 00:00:00.000');

    DECLARE @ClaimsAmount DECIMAL(18,2) = 0;
    SELECT @ClaimsAmount = ISNULL(SUM(CASE WHEN ISNULL(Amount, 0) > 0 THEN Amount ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue), 0) END), 0)
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON CD.Comp_id = CL.Comp_Id
    WHERE Isapproved <> 2
      AND RIGHT(CD.Mobileno, 10) = RIGHT(@MobileNo, 10)
      and @CompID = cl.comp_id AND ( @CompID <> 'Comp-1669' or  (@CompID = 'Comp-1669' and CD.Claim_date >= '2026-09-03 00:00:00.000'));

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
    SET @RedeemAmount = @BPointsAmount + @TransactionsAmount + @UPIAmount + @ClaimsAmount + @PaytmAmount;

    -- Calculate precise counts using SP_BL_GetCodesActivityReport_AI logic
    DECLARE @SuccessCodeCount INT = 0;
    SELECT @SuccessCodeCount = COUNT(*)
    FROM #UserScans US
    LEFT JOIN (
        SELECT M_Codeid, MAX(Frequency) AS Frequency
        FROM #ConfigPoints
        GROUP BY M_Codeid
    ) CP ON CP.M_Codeid = US.M_Codeid
    WHERE US.rn <= ISNULL(CP.Frequency, 1);

    DECLARE @UnsuccessCodeCount INT = 0;
    SELECT @UnsuccessCodeCount = COUNT(pe.Received_Code1)
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_code M WITH (NOLOCK) ON pe.Received_Code1 = M.Code1 AND pe.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    WHERE RIGHT(pe.MobileNo, 10) = RIGHT(@MobileNo, 10)
      AND PR.Comp_ID = @CompID
      -- Count ONLY 'Already Scanned' (Is_Success = '2')
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
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN [dbo].[fnPointSp](TRY_CAST(BL.Points AS INT))
                            ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                    ELSE 0.00
                END
            AS DECIMAL(18,2))), 0.00)
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        WHERE LOWER(BL.compid) = 'comp-1669'
          AND (BL.M_Consumerid = @M_Consumerid OR BL.M_Consumerid IN (
              SELECT M_Consumerid 
              FROM M_Consumer WITH (NOLOCK) 
              WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
          ))
          AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral');

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
        DROP TABLE IF EXISTS #UserScans;
        DROP TABLE IF EXISTS #EarnedPoints;
        DROP TABLE IF EXISTS #ConfigPoints;
        DROP TABLE IF EXISTS #ScanServices;
        DROP TABLE IF EXISTS #ConfiguredPoints;
        DROP TABLE IF EXISTS #ReferralStats;
        RETURN;
    END

    -- Result Set 2: Service-Wise Stats
    SELECT 
        ms.Service_ID,
        ms_name.ServiceName,
        ISNULL(cp.ServiceTotalPoints, 0) as ServiceTotalPoints,
        ISNULL(cp.ServiceTotalCash, 0) as ServiceTotalCash
    FROM (SELECT DISTINCT Service_ID, Comp_ID FROM M_ServiceSubscription WHERE IsActive = 1) ms
    LEFT JOIN M_Service ms_name ON ms_name.Service_ID = ms.Service_ID
    LEFT JOIN #ConfiguredPoints cp ON cp.Service_ID = ms.Service_ID
    WHERE ms.Comp_ID = @CompID
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
END
GO
