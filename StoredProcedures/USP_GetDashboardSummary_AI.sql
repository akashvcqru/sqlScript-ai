USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetDashboardSummary_AI]    Script Date: 10/07/2026 1:00:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_GetDashboardSummary_AI]
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
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation 
    WHERE comp_id = @CompID AND isactive = 1 AND isdelete = 0;

    ---------------------------------------------------------
    -- 1. ENQUIRIES (ALL SCANS FOR THIS USER & COMPANY)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

    SELECT 
        PE.Received_Code1,
        PE.Received_Code2,
        PE.Enq_Date,
        PE.Dial_Mode,
        PE.Is_Success,
        PE.MobileNo,
        M.Row_ID AS M_Codeid,
        M.Series_Order,
        M.Series_Serial,
        M.Pro_ID
    INTO #Enq
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN M_code M WITH (NOLOCK) 
        ON PE.Received_Code1 = CAST(M.code1 AS VARCHAR(50))
       AND PE.Received_Code2 = CAST(M.Code2 AS VARCHAR(50))
    INNER JOIN Pro_Reg PR WITH (NOLOCK)
       ON PR.Pro_ID = M.Pro_ID
    WHERE PR.Comp_ID = @CompID
      AND RIGHT(PE.MobileNo, 10) = RIGHT(@MobileNo, 10);

    -- Rank scans identically to SP_BL_GetCodesActivityReport_AI
    IF OBJECT_ID('tempdb..#RankedScans') IS NOT NULL DROP TABLE #RankedScans;

    SELECT E_sub.*,
           CASE 
               WHEN E_sub.Is_Success = 1 
               THEN ROW_NUMBER() OVER (
                   PARTITION BY E_sub.Received_Code1, E_sub.Received_Code2, E_sub.Is_Success 
                   ORDER BY 
                       CASE WHEN MC_sub.IsActive = 0 THEN 2 ELSE 1 END,
                       E_sub.Enq_Date ASC
               )
               ELSE 1
           END AS rn,
           CASE 
               WHEN E_sub.Is_Success = 1 
               THEN ROW_NUMBER() OVER (
                   PARTITION BY E_sub.Received_Code1, E_sub.Received_Code2, 
                                CASE WHEN LEN(E_sub.MobileNo) >= 10 THEN RIGHT(E_sub.MobileNo, 10) ELSE E_sub.MobileNo END, 
                                E_sub.Is_Success 
                   ORDER BY E_sub.Enq_Date ASC
               )
               ELSE 1
           END AS rn_user
    INTO #RankedScans
    FROM #Enq E_sub
    LEFT JOIN M_Consumer MC_sub WITH (NOLOCK) 
        ON (MC_sub.MobileNo = E_sub.MobileNo OR (LEN(E_sub.MobileNo) >= 10 AND RIGHT(MC_sub.MobileNo, 10) = RIGHT(E_sub.MobileNo, 10))) 
       AND MC_sub.IsDelete = 0;

    ---------------------------------------------------------
    -- 2. POINTS FROM BLOYALTYPOINTSEARNED (FOR SCANS)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT
        M_Codeid,
        MobileNo,
        CASE 
            WHEN @CompID = 'Comp-1669' THEN SUM(Points)
            ELSE MAX(Points)
        END AS Points,
        CASE 
            WHEN @CompID = 'Comp-1669' THEN SUM(WornPoint)
            ELSE MAX(WornPoint)
        END AS WornPoint,
        MAX(ServiceName) AS ServiceName,
        MAX(Service_ID) AS Service_ID
    INTO #Points
    FROM (
        SELECT
            MC.M_Codeid,
            Cons.MobileNo,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint,
            ISNULL(MS.ServiceName, BL.ServiceName) AS ServiceName,
            SS.Service_ID
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN (SELECT DISTINCT M_Codeid FROM #Enq) M
            ON MC.M_Codeid = M.M_Codeid
        LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK)
            ON SST.SST_Id = BL.SST_id
        LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK)
            ON SS.Subscribe_Id = SST.Subscribe_Id
        LEFT JOIN dbo.M_Service MS WITH (NOLOCK)
            ON MS.Service_ID = SS.Service_ID
        LEFT JOIN M_Consumer Cons WITH (NOLOCK)
            ON BL.M_Consumerid = Cons.M_Consumerid
        WHERE BL.compid = @CompID

        UNION ALL

        SELECT
            MC.M_Codeid,
            Cons.MobileNo,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS Points,
            CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN @CompID = 'Comp-1669' THEN
                        CASE
                            WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                                END
                            WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                                CASE 
                                    WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                        THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                    ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                                END
                            ELSE 0.00
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2)) AS WornPoint,
            ISNULL(MS.ServiceName, BL.ServiceName) AS ServiceName,
            SS.Service_ID
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
            ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
            ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN (SELECT DISTINCT M_Codeid, Pro_ID FROM #Enq) M 
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
          AND PR.Comp_ID = @CompID
    ) x
    GROUP BY M_Codeid, MobileNo;

    ---------------------------------------------------------
    -- 3. CONFIG POINTS (SUBSCRIPTIONS)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;
    CREATE TABLE #CodeConfigPoints (
        M_Codeid BIGINT,
        Frequency INT,
        ConfigPoints DECIMAL(18,2),
        AssignPoint DECIMAL(18,2),
        TotalFrequency INT,
        ServiceName NVARCHAR(200),
        Service_ID VARCHAR(50),
        ConfigCash DECIMAL(18,2)
    );

    IF @CompID = 'Comp-1669'
    BEGIN
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
                SS.Service_ID,
                CAST(0.00 AS DECIMAL(18,2)) AS ConfigCash,
                ROW_NUMBER() OVER (
                    PARTITION BY MC.M_Codeid 
                    ORDER BY CASE WHEN SS.Service_ID = 'SRV1001' THEN 1 WHEN SS.Service_ID = 'SRV1005' THEN 2 ELSE 3 END,
                             SST.SST_Id DESC
                ) AS rn
            FROM (SELECT DISTINCT M_Codeid, Pro_ID, Series_Order, Series_Serial FROM #Enq) MC
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
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency, ServiceName, Service_ID, ConfigCash)
        SELECT 
            M_Codeid, Frequency, ConfigPoints, AssignPoint, 1 AS TotalFrequency, ServiceName, Service_ID, ConfigCash
        FROM ConfigRanked
        WHERE rn = 1;
    END
    ELSE
    BEGIN
        INSERT INTO #CodeConfigPoints (M_Codeid, Frequency, ConfigPoints, AssignPoint, TotalFrequency, ServiceName, Service_ID, ConfigCash)
        SELECT 
            MC.M_Codeid,
            MAX(ISNULL(SST.Frequency, 1)) AS Frequency,
            MAX(CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                    ELSE ISNULL(SST.IsCash, 0) * @Multiplier
                END 
            AS DECIMAL(18,2))) AS ConfigPoints,
            MAX(CAST(
                CASE 
                    WHEN @CompID = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                    ELSE ISNULL(SST.IsCash, 0)
                END 
            AS DECIMAL(18,2))) AS AssignPoint,
            SUM(ISNULL(SST.Frequency, 1)) AS TotalFrequency,
            MAX(S.ServiceName) AS ServiceName,
            MAX(SS.Service_ID) AS Service_ID,
            MAX(CAST(ISNULL(SST.IsCash, 0) AS DECIMAL(18,2))) AS ConfigCash
        FROM (SELECT DISTINCT M_Codeid, Pro_ID, Series_Order, Series_Serial FROM #Enq) MC
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        LEFT JOIN dbo.M_Service S WITH (NOLOCK) ON S.Service_ID = SS.Service_ID
        WHERE SS.Comp_ID = @CompID 
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1028', 'SRV1029', 'SRV1023', 'SRV1024', 'SRV1027')
          AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
          AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        GROUP BY MC.M_Codeid;
    END

    ---------------------------------------------------------
    -- 4. AGGREGATE SCAN & NON-SCAN EARNED ITEMS (SERVICE-WISE)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#AllEarnedItems') IS NOT NULL DROP TABLE #AllEarnedItems;

    CREATE TABLE #AllEarnedItems (
        Service_ID VARCHAR(50),
        Points DECIMAL(18,2),
        Cash DECIMAL(18,2),
        IsVerified BIT
    );

    -- 4a. Scan Items
    INSERT INTO #AllEarnedItems (Service_ID, Points, Cash, IsVerified)
    SELECT 
        COALESCE(P.Service_ID, CP.Service_ID, 'SRV1001') AS Service_ID,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn_user = 1 AND (ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) THEN 
                ISNULL(P.WornPoint, 0)
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 
                CASE 
                    WHEN @CompID = 'Comp-1669' THEN ISNULL(P.WornPoint, 0)
                    WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint 
                    ELSE ISNULL(CP.ConfigPoints, 0) 
                END
            ELSE 0 
        END AS Points,
        CASE 
            WHEN @CompID = 'Comp-1669' THEN 0.00
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN ISNULL(CP.ConfigCash, 0)
            ELSE 0.00
        END AS Cash,
        CASE 
            WHEN E.Is_Success = 1 AND (E.rn_user = 1 AND (ISNULL(P.Points, 0) > 0 OR ISNULL(P.WornPoint, 0) > 0)) THEN 1
            WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.TotalFrequency, 1) THEN 1
            ELSE 0
        END AS IsVerified
    FROM #RankedScans E
    LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid AND (P.MobileNo = E.MobileNo OR '91' + P.MobileNo = E.MobileNo OR P.MobileNo = '91' + E.MobileNo OR (LEN(P.MobileNo) >= 10 AND LEN(E.MobileNo) >= 10 AND RIGHT(P.MobileNo, 10) = RIGHT(E.MobileNo, 10)) OR P.MobileNo IS NULL)
    LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid;

    -- 4b. Extra/Non-Scan Earned Items (Bonus, KYC, Repair, Invoice, etc. matching Section 3 of CodesActivityReport)
    INSERT INTO #AllEarnedItems (Service_ID, Points, Cash, IsVerified)
    SELECT 
        ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
        CAST(
            CASE 
                WHEN @CompID = 'Comp-1669' THEN
                    CASE
                        WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN
                            CASE 
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                    THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                                ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                            END
                        WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                            CASE 
                                WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                    THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                                ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                            END
                        ELSE 0.00
                    END
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2)) AS Points,
        CAST(
            CASE 
                WHEN @CompID = 'Comp-1669' THEN 0.00
                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                ELSE 0.00
            END 
        AS DECIMAL(18,2)) AS Cash,
        1 AS IsVerified
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
    LEFT JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    LEFT JOIN M_Consumer_M_Code MCMC ON BMC.M_Consumer_MCOdeid = MCMC.M_Consumer_MCodeid
    LEFT JOIN M_Code C ON MCMC.M_Codeid = C.Row_ID
    LEFT JOIN Pro_Reg PR ON C.Pro_ID = PR.Pro_ID
    LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.SST_Id = BL.SST_id
    LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) ON SS.Subscribe_Id = SST.Subscribe_Id
    WHERE (BL.compid = @CompID OR (@CompID = 'Comp-1669' AND BL.compid IS NULL AND PR.Pro_ID IS NOT NULL))
      AND RIGHT(MC.MobileNo, 10) = RIGHT(@MobileNo, 10)
      AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
      AND (
          BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          OR NOT EXISTS (
              SELECT 1 FROM #Enq E 
              WHERE E.M_Codeid = MCMC.M_Codeid 
                AND (E.MobileNo = MC.MobileNo OR '91' + E.MobileNo = MC.MobileNo OR E.MobileNo = '91' + MC.MobileNo)
          )
      );

    IF OBJECT_ID('tempdb..#ConfiguredPoints') IS NOT NULL DROP TABLE #ConfiguredPoints;

    SELECT 
        Service_ID,
        SUM(Points) AS ServiceTotalPoints,
        SUM(Cash) AS ServiceTotalCash
    INTO #ConfiguredPoints
    FROM #AllEarnedItems
    GROUP BY Service_ID;

    DECLARE @TotalConfigPoints DECIMAL(18,2) = 0;
    DECLARE @TotalConfigCash DECIMAL(18,2) = 0;

    SELECT 
        @TotalConfigPoints = ISNULL(SUM(ServiceTotalPoints), 0),
        @TotalConfigCash = ISNULL(SUM(ServiceTotalCash), 0)
    FROM #ConfiguredPoints;

    ---------------------------------------------------------
    -- 5. REFERRAL STATS
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#ReferralStats') IS NOT NULL DROP TABLE #ReferralStats;

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
    INNER JOIN @CompanyList CL ON (BL.compid = CL.Comp_Id OR (ISNULL(BL.compid, '') = '' AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL))
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
      );

    ---------------------------------------------------------
    -- 6. REDEMPTIONS & CODE COUNTS
    ---------------------------------------------------------
    DECLARE @BPointsAmount DECIMAL(18,2) = 0;
    SELECT @BPointsAmount = ISNULL(SUM(ISNULL(RedeemPoints, 0)), 0)
    FROM BPointsTransaction WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON companyid = CL.Comp_Id
    WHERE bpstatus IN ('Accepted', 'SUCCESS')
      AND RedeemBy = @M_Consumerid
      AND (@CompID <> 'Comp-1669' OR Redeemdate >= '2026-09-08 17:27:20.650');

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
      AND (@CompID <> 'Comp-1669' OR TransactionDate >= '2026-09-08 17:27:20.650');

    DECLARE @UPIAmount DECIMAL(18,2) = 0;
    SELECT @UPIAmount = ISNULL(SUM(ISNULL(Amount, 0)), 0)
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @CompID
      AND Status = 'Success'
      AND LEN(Code1) > 3
      AND M_Consumerid = CAST(@M_Consumerid AS VARCHAR(50))
      AND (@CompID <> 'Comp-1669' OR ReqDate >= '2026-09-08 17:27:20.650');

    DECLARE @ClaimsAmount DECIMAL(18,2) = 0;
    SELECT @ClaimsAmount = ISNULL(SUM(CASE WHEN ISNULL(Amount, 0) > 0 THEN Amount ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue), 0) END), 0)
    FROM ClaimDetails CD WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON CD.Comp_id = CL.Comp_Id
    WHERE Isapproved <> 2
      AND RIGHT(CD.Mobileno, 10) = RIGHT(@MobileNo, 10)
      and @CompID = cl.comp_id AND ( @CompID <> 'Comp-1669' or  (@CompID = 'Comp-1669' and CD.Claim_date >= '2026-09-08 17:27:20.650'));

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
    IF LOWER(@CompID) = 'comp-1669'
    BEGIN
        DECLARE @Comp1669Paytm DECIMAL(18,2) = 0;
        SELECT @Comp1669Paytm = ISNULL(SUM(TRY_CAST(ISNULL(pt.Amount, 0) AS DECIMAL(18,2))), 0)
        FROM paytmtransaction pt WITH (NOLOCK)
        WHERE LOWER(pt.compId) = 'comp-1669'
          AND pt.pStatus IN ('Success', 'Accepted', 'ACCEPTED', 'SUCCESS')
          AND (
              pt.M_consumerid = CAST(@M_Consumerid AS VARCHAR(50)) 
              OR pt.M_consumerid IN (
                  SELECT CAST(M_Consumerid AS VARCHAR(50))
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
              )
              OR RIGHT(pt.mobileno, 10) = RIGHT(@MobileNo, 10)
          );

        DECLARE @Comp1669UPI DECIMAL(18,2) = 0;
        SELECT @Comp1669UPI = ISNULL(SUM(TRY_CAST(ISNULL(t.Amount, t.Points_Val) AS DECIMAL(18,2))), 0)
        FROM tblUPITransactionDetails t WITH (NOLOCK)
        WHERE LOWER(t.Comp_Id) = 'comp-1669'
          AND t.Status = 'Success'
          AND (
              t.M_Consumerid = CAST(@M_Consumerid AS VARCHAR(50)) 
              OR t.M_Consumerid IN (
                  SELECT CAST(M_Consumerid AS VARCHAR(50))
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0
              )
          );

        SET @RedeemAmount = @Comp1669Paytm + @Comp1669UPI;
    END
    ELSE
    BEGIN
        SET @RedeemAmount = @BPointsAmount + @TransactionsAmount + @UPIAmount + @ClaimsAmount;
    END

    -- Calculate precise counts
    DECLARE @SuccessCodeCount INT = 0;
    SELECT @SuccessCodeCount = COUNT(*)
    FROM #AllEarnedItems
    WHERE IsVerified = 1;

    DECLARE @UnsuccessCodeCount INT = 0;
    SELECT @UnsuccessCodeCount = COUNT(pe.Received_Code1)
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_code M WITH (NOLOCK) ON pe.Received_Code1 = M.Code1 AND pe.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    WHERE RIGHT(pe.MobileNo, 10) = RIGHT(@MobileNo, 10)
      AND PR.Comp_ID = @CompID
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
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383' THEN TRY_CAST(BL.Points AS DECIMAL(18,2)) * 1.10
                            ELSE TRY_CAST(BL.Points AS DECIMAL(18,2))
                        END
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN
                        CASE 
                            WHEN BL.UpdateDate <= '2026-09-10 19:41:55.383'
                                THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * 1.10
                            ELSE TRY_CAST(BL.Cash AS DECIMAL(18,2))
                        END
                    ELSE 0.00
                END
            AS DECIMAL(18,2))), 0.00)
        FROM (
            SELECT BL.M_Consumerid, BL.Points, BL.Cash, BL.UpdateDate, BL.ServiceName
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
            WHERE LOWER(BL.compid) = 'comp-1669'
              AND (BL.M_Consumerid = @M_Consumerid OR BL.M_Consumerid IN (
                  SELECT M_Consumerid 
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
              ))

            UNION ALL

            SELECT BL.M_Consumerid, BL.Points, BL.Cash, BL.UpdateDate, BL.ServiceName
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
            INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
                ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
            INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
                ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
            INNER JOIN M_Code M WITH (NOLOCK) 
                ON MC.M_Codeid = M.Row_ID
            INNER JOIN Pro_Reg PR WITH (NOLOCK) 
                ON M.Pro_ID = PR.Pro_ID
            WHERE BL.compid IS NULL
              AND PR.Comp_ID = 'Comp-1669'
              AND (BL.M_Consumerid = @M_Consumerid OR BL.M_Consumerid IN (
                  SELECT M_Consumerid 
                  FROM M_Consumer WITH (NOLOCK) 
                  WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
              ))
        ) BL
        WHERE LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral');

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
        DROP TABLE IF EXISTS #Enq;
        DROP TABLE IF EXISTS #RankedScans;
        DROP TABLE IF EXISTS #Points;
        DROP TABLE IF EXISTS #CodeConfigPoints;
        DROP TABLE IF EXISTS #AllEarnedItems;
        DROP TABLE IF EXISTS #ConfiguredPoints;
        DROP TABLE IF EXISTS #ReferralStats;
        RETURN;
    END

    -- Result Set 2: Service-Wise Stats
    DECLARE @ServiceWiseList NVARCHAR(MAX);
    SELECT TOP 1 @ServiceWiseList = ServiceWiseList FROM Comp_Reg WITH (NOLOCK) WHERE Comp_ID = @CompID;

    SELECT 
        ms.Service_ID,
        ms_name.ServiceName,
        ISNULL(cp.ServiceTotalPoints, 0) as ServiceTotalPoints,
        ISNULL(cp.ServiceTotalCash, 0) as ServiceTotalCash
    FROM (SELECT DISTINCT Service_ID, Comp_ID FROM M_ServiceSubscription WHERE IsActive = 1) ms
    LEFT JOIN M_Service ms_name ON ms_name.Service_ID = ms.Service_ID
    LEFT JOIN #ConfiguredPoints cp ON cp.Service_ID = ms.Service_ID
    WHERE ms.Comp_ID = @CompID 
      AND (
          @ServiceWiseList IS NULL 
          OR LTRIM(RTRIM(@ServiceWiseList)) = ''
          OR cp.Service_ID IN (
              SELECT LTRIM(RTRIM(value)) 
              FROM STRING_SPLIT(ISNULL(LTRIM(RTRIM(@ServiceWiseList)), ''), ',')
              WHERE LTRIM(RTRIM(value)) <> ''
          )
      )
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

    -- Cleanup
    DROP TABLE IF EXISTS #Enq;
    DROP TABLE IF EXISTS #RankedScans;
    DROP TABLE IF EXISTS #Points;
    DROP TABLE IF EXISTS #CodeConfigPoints;
    DROP TABLE IF EXISTS #AllEarnedItems;
    DROP TABLE IF EXISTS #ConfiguredPoints;
    DROP TABLE IF EXISTS #ReferralStats;
END
GO