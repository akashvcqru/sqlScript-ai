USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetDashboardSummary_AI]    Script Date: 7/16/2026 11:17:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[USP_GetDashboardSummary_AI]
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

    --IF @CompID IN ('Comp-1567','Comp-1650')
    --    INSERT INTO @CompanyList VALUES ('Comp-1567'),('Comp-1650');
    --ELSE
    --    INSERT INTO @CompanyList VALUES (@CompID);

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
    WHERE PE.MobileNo = @MobileNo 
      AND PE.Is_Success = '1';

    -- Get Earned Points
    SELECT
        M_Codeid,
        ISNULL(Service_ID, 'SRV1001') AS Service_ID,
        SUM(Points) AS Points
    INTO #EarnedPoints
    FROM (
        SELECT
            MC.M_Codeid,
            ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN (
            SELECT BMC2.Pkid, BMC2.M_Consumer_MCOdeid, ROW_NUMBER() OVER (PARTITION BY BMC2.M_Consumer_MCOdeid ORDER BY BMC2.Createdate ASC) as rn
            FROM BuiltLoyaltyMCodeCheck BMC2 WITH (NOLOCK)
            INNER JOIN M_Consumer_M_Code MC2 WITH (NOLOCK) ON BMC2.M_Consumer_MCOdeid = MC2.M_Consumer_MCodeid
            WHERE MC2.M_Codeid IN (SELECT M_Codeid FROM #UserScans)
        ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
        INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON BL.SST_id = SST.SST_Id
        LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        INNER JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
        WHERE MC.M_Codeid IN (SELECT M_Codeid FROM #UserScans)

        UNION ALL

        SELECT
            MC.M_Codeid,
            ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
            CAST(
                CASE 
                    WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                    ELSE ISNULL(BL.Points, 0)
                END 
            AS DECIMAL(18,2)) AS Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN (
            SELECT BMC2.Pkid, BMC2.M_Consumer_MCOdeid, ROW_NUMBER() OVER (PARTITION BY BMC2.M_Consumer_MCOdeid ORDER BY BMC2.Createdate ASC) as rn
            FROM BuiltLoyaltyMCodeCheck BMC2 WITH (NOLOCK)
            INNER JOIN M_Consumer_M_Code MC2 WITH (NOLOCK) ON BMC2.M_Consumer_MCOdeid = MC2.M_Consumer_MCodeid
            WHERE MC2.M_Codeid IN (SELECT M_Codeid FROM #UserScans)
        ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
        INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
        INNER JOIN @CompanyList CL ON PR.Comp_ID = CL.Comp_Id
        LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON BL.SST_id = SST.SST_Id
        LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        WHERE BL.compid IS NULL
          AND MC.M_Codeid IN (SELECT M_Codeid FROM #UserScans)
    ) x
    GROUP BY M_Codeid, ISNULL(Service_ID, 'SRV1001');

    CREATE CLUSTERED INDEX IX_EarnedPoints_MCodeid ON #EarnedPoints(M_Codeid);

    -- Get Config Points
    SELECT 
        US.M_Codeid,
        SS.Service_ID,
        MAX(CAST(
            CASE 
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
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
      AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
      AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
    GROUP BY US.M_Codeid, SS.Service_ID;

    CREATE CLUSTERED INDEX IX_ConfigPoints_MCodeid ON #ConfigPoints(M_Codeid);

    -- Get distinct M_Codeid and Service_ID mapping from both tables to avoid Cartesian product duplication
    SELECT M_Codeid, Service_ID INTO #ScanServices FROM #ConfigPoints
    UNION
    SELECT M_Codeid, Service_ID FROM #EarnedPoints;

    -- Aggregate into #ConfiguredPoints
    SELECT
        COALESCE(SS.Service_ID, 'SRV1001') AS Service_ID,
        SUM(ISNULL(EP.Points, ISNULL(CP.ConfigPoints, 0))) AS ServiceTotalPoints,
        SUM(ISNULL(CP.ConfigCash, 0)) AS ServiceTotalCash
    INTO #ConfiguredPoints
    FROM #UserScans US
    LEFT JOIN #ScanServices SS ON US.M_Codeid = SS.M_Codeid
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = SS.M_Codeid AND CP.Service_ID = SS.Service_ID
    LEFT JOIN #EarnedPoints EP ON EP.M_Codeid = SS.M_Codeid AND EP.Service_ID = SS.Service_ID
    WHERE US.rn = 1
    GROUP BY COALESCE(SS.Service_ID, 'SRV1001');

    ---------------------------------------------------------
    -- PRECISE POINT/CASH SUM FOR TOTAL (DUPLICATION FREE)
    ---------------------------------------------------------
    DECLARE @TotalConfigPoints DECIMAL(18,2) = 0;
    DECLARE @TotalConfigCash DECIMAL(18,2) = 0;

    SELECT 
        @TotalConfigPoints = ISNULL(SUM(ISNULL(EP.Points, ISNULL(CP.ConfigPoints, 0))), 0),
        @TotalConfigCash = ISNULL(SUM(ISNULL(CP.ConfigCash, 0)), 0)
    FROM #UserScans US
    LEFT JOIN (
        SELECT M_Codeid, MAX(ConfigPoints) AS ConfigPoints, MAX(ConfigCash) AS ConfigCash
        FROM #ConfigPoints
        GROUP BY M_Codeid
    ) CP ON CP.M_Codeid = US.M_Codeid
    LEFT JOIN (
        SELECT M_Codeid, MAX(Points) AS Points
        FROM #EarnedPoints
        GROUP BY M_Codeid
    ) EP ON EP.M_Codeid = US.M_Codeid
    WHERE US.rn = 1;

    SELECT 
        ISNULL(SUM(CAST(Points AS DECIMAL(18,2))), 0) as RefPoints,
        ISNULL(SUM(CAST(Cash AS DECIMAL(18,2))), 0) as RefCash
    INTO #ReferralStats
    FROM BLoyaltyPointsEarned BL
    INNER JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
    WHERE BL.M_Consumerid = @M_Consumerid 
      AND BL.ServiceName IN ('Referral', 'KYCRewards', 'Supervisor', 'InvoiceBenifit', 'InvoiceRewards','Transfer From User');

    ---------------------------------------------------------
    -- Calculate specific totals for this consumer
    DECLARE @BPointsAmount DECIMAL(18,2) = 0;
    SELECT @BPointsAmount = ISNULL(SUM(ISNULL(RedeemPoints, 0)), 0)
    FROM BPointsTransaction WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON companyid = CL.Comp_Id
    WHERE bpstatus IN ('Accepted', 'SUCCESS')
      AND RedeemBy = @M_Consumerid;

    DECLARE @TransactionsAmount DECIMAL(18,2) = 0;
    SELECT @TransactionsAmount = ISNULL(SUM(ISNULL(CAST(Amount AS DECIMAL(18,2)), 0)), 0)
    FROM Transactions WITH (NOLOCK)
    WHERE CompId = REPLACE(@CompID, 'Comp-', '')
      AND IsSuccess = 1
      AND M_CounserID = CAST(@M_Consumerid AS VARCHAR(50)) AND 
	  (
        @CompID <> 'Comp-1152'
        OR TransactionDate > '2022-11-25'
      );

    DECLARE @UPIAmount DECIMAL(18,2) = 0;
    SELECT @UPIAmount = ISNULL(SUM(ISNULL(Amount, 0)), 0)
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @CompID
      AND Status = 'Success'
      AND LEN(Code1) > 3
      AND M_Consumerid = CAST(@M_Consumerid AS VARCHAR(50));

    DECLARE @ClaimsAmount DECIMAL(18,2) = 0;
    SELECT @ClaimsAmount = ISNULL(SUM(CASE WHEN ISNULL(Amount, 0) > 0 THEN Amount ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue), 0) END), 0)
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON CD.Comp_id = CL.Comp_Id
    WHERE Isapproved <> 2
      AND CD.Mobileno = @MobileNo;

    DECLARE @RedeemAmount DECIMAL(18,2) = 0;
    SET @RedeemAmount = @BPointsAmount + @TransactionsAmount + @UPIAmount + @ClaimsAmount;

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
    WHERE pe.MobileNo = @MobileNo
      AND PR.Comp_ID = @CompID
      -- Count ONLY 'Already Scanned' (Is_Success = '2')
      AND pe.Is_Success = '2';

    DECLARE @InvalidCodeCount INT = 0;
    SELECT @InvalidCodeCount = COUNT(pe.Received_Code1)
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_code M WITH (NOLOCK) ON pe.Received_Code1 = M.Code1 AND pe.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    WHERE pe.MobileNo = @MobileNo
      AND PR.Comp_ID = @CompID
      AND pe.Is_Success NOT IN ('1', '2');

    -- Result Set 1: Overall Stats
    SELECT 
        (@SuccessCodeCount + @UnsuccessCodeCount + @InvalidCodeCount) as TotalCode,
        @RedeemAmount as ReedemPoints,
        @SuccessCodeCount as SuccessCode,
        @UnsuccessCodeCount as UnsuccessCode,
        CASE 
            WHEN @CompID = 'Comp-1274' THEN @TotalConfigPoints + (SELECT RefPoints FROM #ReferralStats)
            WHEN @CompID IN ('comp-1152', 'Comp-1152') THEN (SELECT ISNULL(SUM(TRY_CAST(cash AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = @MobileNo and Enq_Date >='2022-08-04 00:00:00.000' and Is_Success=1 )
            ELSE @TotalConfigCash + (SELECT RefCash FROM #ReferralStats)
        END as TotalCash,
        CASE 
            WHEN @CompID IN ('comp-1152', 'Comp-1152') THEN (SELECT ISNULL(SUM(TRY_CAST(points AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = @MobileNo and Enq_Date >='2022-08-04 00:00:00.000' and Is_Success=1 )
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
