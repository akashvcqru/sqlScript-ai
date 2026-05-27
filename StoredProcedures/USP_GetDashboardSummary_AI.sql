USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetDashboardSummary_AI]    Script Date: 5/13/2026 11:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






ALTER   PROCEDURE [dbo].[USP_GetDashboardSummary_AI]
(
    @M_Consumerid INT,
    @CompID VARCHAR(50)
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

    --------------------------------------------------------------------------------
    -- Use Temp Tables instead of CTEs to support multiple result sets
    --------------------------------------------------------------------------------
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
	inner join Pro_Reg pr on pr.Pro_ID = M.Pro_ID
    WHERE PE.MobileNo = @MobileNo 
      AND PE.Is_Success = '1'
      AND (pr.Comp_ID = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND pr.Comp_ID IN ('Comp-1650', 'Comp-1567')));

    -- Get Earned Points
    SELECT
        MC.M_Codeid,
        ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
        MAX(CAST(
            CASE 
                WHEN @CompID = 'Comp-1274' THEN ISNULL(BL.Cash, 0) * 1.10
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS Points
    INTO #EarnedPoints
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON BL.SST_id = SST.SST_Id
    LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    WHERE BL.M_Consumerid = @M_Consumerid
      AND (BL.compid = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND BL.compid IN ('Comp-1650', 'Comp-1567')))
    GROUP BY MC.M_Codeid, ISNULL(SS.Service_ID, 'SRV1001');

    CREATE CLUSTERED INDEX IX_EarnedPoints_MCodeid ON #EarnedPoints(M_Codeid);

    -- Get Config Points
    SELECT 
        US.M_Codeid,
        SS.Service_ID,
        MAX(CAST(
            CASE 
                WHEN @CompID = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                ELSE CASE WHEN SST.Points IS NULL OR SST.Points = 0 THEN ISNULL(SST.IsCash, 0) ELSE SST.Points END
            END 
        AS DECIMAL(18,2))) AS ConfigPoints,
        MAX(CAST(ISNULL(SST.IsCash, 0) AS DECIMAL(18,2))) AS ConfigCash
    INTO #ConfigPoints
    FROM #UserScans US
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    WHERE US.rn = 1
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND (SS.Comp_ID = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND SS.Comp_ID IN ('Comp-1650', 'Comp-1567')))
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
        SUM(ISNULL(CP.ConfigPoints, ISNULL(EP.Points, 0))) AS ServiceTotalPoints,
        SUM(ISNULL(CP.ConfigCash, 0)) AS ServiceTotalCash
    INTO #ConfiguredPoints
    FROM #UserScans US
    LEFT JOIN #ScanServices SS ON US.M_Codeid = SS.M_Codeid
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = SS.M_Codeid AND CP.Service_ID = SS.Service_ID
    LEFT JOIN #EarnedPoints EP ON EP.M_Codeid = SS.M_Codeid AND EP.Service_ID = SS.Service_ID
    WHERE US.rn = 1
    GROUP BY COALESCE(SS.Service_ID, 'SRV1001');

    SELECT 
        ISNULL(SUM(CAST(Points AS DECIMAL(18,2))), 0) as RefPoints,
        ISNULL(SUM(CAST(Cash AS DECIMAL(18,2))), 0) as RefCash
    INTO #ReferralStats
    FROM BLoyaltyPointsEarned
    WHERE M_Consumerid = @M_Consumerid 
      AND (compid = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND compid IN ('Comp-1650', 'Comp-1567')))
      AND ServiceName IN ('Referral', 'KYCRewards', 'Supervisor');

    -- Result Set 1: Overall Stats
    SELECT 
        (SELECT COUNT(pe.Received_Code1) 
         FROM Pro_Enq pe 
         WHERE pe.MobileNo = @MobileNo) as TotalCode,
        (SELECT 
            (SELECT ISNULL(SUM(TRY_CAST(RedeemPoints AS INT)), 0) 
             FROM BPointsTransaction WHERE RedeemBy = @M_Consumerid AND bpstatus <> 'FAILURE')
            + 
            (SELECT ISNULL(SUM(Amount), 0) 
              FROM ClaimDetails cl 
              WHERE RIGHT(cl.Mobileno, 10) = RIGHT(@MobileNo, 10) AND cl.Isapproved <> 2
                AND (cl.Comp_id = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND cl.Comp_ID IN ('Comp-1650', 'Comp-1567'))))
            +
            (SELECT ISNULL(SUM(ISNULL(Points_Val, Amount)), 0) 
             FROM tblUPITransactionDetails 
             WHERE RIGHT(Mobileno, 10) = RIGHT(@MobileNo, 10) AND Status IN ('Pending','Success') AND Comp_id = @CompID AND Code2 > 0)
            +
            (SELECT ISNULL(SUM(Amount), 0)
             FROM Transactions WITH (NOLOCK)
             WHERE IsSuccess = 1
               AND M_CounserID = @M_Consumerid
               AND 'Comp-' + CAST(CompId AS VARCHAR) = @CompID
               AND TransactionDate >= '2022-11-25 00:00:00.000'
               AND TransactionDate < GETDATE())
        ) as ReedemPoints,
        (SELECT COUNT(pe.Received_Code1) 
         FROM Pro_Enq pe 
         WHERE pe.MobileNo = @MobileNo AND pe.Is_Success = 1) as SuccessCode,
        CASE 
            WHEN @CompID IN ('comp-1152', 'Comp-1152') THEN (SELECT ISNULL(SUM(TRY_CAST(cash AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = @MobileNo)
            ELSE (SELECT ISNULL(SUM(ServiceTotalCash), 0) FROM #ConfiguredPoints) + (SELECT RefCash FROM #ReferralStats)
        END as TotalCash,
        CASE 
            WHEN @CompID IN ('comp-1152', 'Comp-1152') THEN (SELECT ISNULL(SUM(TRY_CAST(points AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = @MobileNo)
            ELSE (SELECT ISNULL(SUM(ServiceTotalPoints), 0) FROM #ConfiguredPoints) + (SELECT RefPoints FROM #ReferralStats)
        END as TotalPoints,
        @HasServiceWiseGifts as HasServiceWiseGifts;

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
        WHERE RIGHT(cl.Mobileno, 10) = RIGHT(@MobileNo, 10) AND cl.Isapproved <> 2
          AND (cl.Comp_id = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND cl.Comp_ID IN ('Comp-1650', 'Comp-1567')))
        UNION ALL
        SELECT 
            'SRV1029' as Service_ID,
            ISNULL(Points_Val, Amount) as ClaimAmount
        FROM tblUPITransactionDetails 
        WHERE RIGHT(Mobileno, 10) = RIGHT(@MobileNo, 10) 
          AND Status IN ('Pending','Success') 
          AND Comp_id = @CompID 
          AND Code2 > 0
    ) t
    GROUP BY Service_ID;
END

