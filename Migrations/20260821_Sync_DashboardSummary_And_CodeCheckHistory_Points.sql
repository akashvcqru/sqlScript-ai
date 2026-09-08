-- Migration: Align USP_GetDashboardSummary_AI and USP_CodeCheckHistory_BLAPP_AI points calculation with SP_BL_GetCodesActivityReport_AI
-- Date: 2026-08-21

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. USP_GetDashboardSummary_AI
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDashboardSummary_AI]
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
    WHERE PE.MobileNo = @MobileNo 
      AND PE.Is_Success = '1';

    -- Get Earned Points
    SELECT
        MC.M_Codeid,
        ROW_NUMBER() OVER (PARTITION BY MC.M_Codeid ORDER BY BMC.Createdate ASC, BL.BLoyalty_PointEarnedID ASC) AS rn,
        ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
        CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                WHEN BL.Points IS NOT NULL AND TRY_CAST(BL.Points AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Points AS DECIMAL(18,2))
                ELSE NULL
            END 
        AS DECIMAL(18,2)) AS Points
    INTO #EarnedPoints
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
        ON SST.Subscribe_Id = SS.Subscribe_Id;

    CREATE CLUSTERED INDEX IX_EarnedPoints_MCodeid ON #EarnedPoints(M_Codeid, rn);

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
    LEFT JOIN #EarnedPoints EP ON EP.M_Codeid = SS.M_Codeid AND EP.Service_ID = SS.Service_ID AND EP.rn = US.rn
    WHERE US.rn <= ISNULL(CP.Frequency, 1)
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
        SELECT M_Codeid, MAX(ConfigPoints) AS ConfigPoints, MAX(ConfigCash) AS ConfigCash, MAX(Frequency) AS Frequency
        FROM #ConfigPoints
        GROUP BY M_Codeid
    ) CP ON CP.M_Codeid = US.M_Codeid
    LEFT JOIN #EarnedPoints EP ON EP.M_Codeid = US.M_Codeid AND EP.rn = US.rn
    WHERE US.rn <= ISNULL(CP.Frequency, 1);

    SELECT 
        ISNULL(SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
            END
        AS DECIMAL(18,2))), 0) as RefPoints,
        ISNULL(SUM(CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                ELSE 0.00
            END
        AS DECIMAL(18,2))), 0) as RefCash
    INTO #ReferralStats
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN @CompanyList CL ON (BL.compid = CL.Comp_Id OR ISNULL(BL.compid, '') = '')
    WHERE BL.M_Consumerid = @M_Consumerid 
      AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL;

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
GO

-- 2. USP_CodeCheckHistory_BLAPP_AI
CREATE OR ALTER PROCEDURE [dbo].[USP_CodeCheckHistory_BLAPP_AI]  
    @MobileNo VARCHAR(15),  
    @Comp_ID VARCHAR(100),  
    @M_Consumer_id INT,
    @Year INT = NULL,
    @Month INT = NULL
AS  
BEGIN  
    SET NOCOUNT ON;

    IF @Comp_ID = 'comp-1152' OR @Comp_ID = 'Comp-1152'
    BEGIN
        SELECT   
            CASE   
                WHEN bl.Is_Success = 1 THEN 'Success'   
                WHEN bl.Is_Success = 0 THEN 'Invalid'   
                WHEN bl.Is_Success = 2 THEN 'Unsuccess'
                ELSE 'Unsuccess'   
            END AS Status,  
            bl.Service_ID,
            FORMAT(bl.Enq_Date, 'dd-MM-yyyy') AS Enq_Date,  
            'MAHINDRA AND MAHINDRA LTD' AS Comp_Name,  
            Pro_Name AS Pro_Name,  
            CONCAT(bl.Code1, bl.Code2) AS [Code],  
            bl.Code1,  
            bl.Code2,  
            bl.MobileNo,
            @M_Consumer_id AS M_Consumerid,
            CASE 
                WHEN bl.cash IS NOT NULL AND bl.cash <> '' AND bl.cash <> '0' THEN CONCAT('+', bl.cash)
                ELSE '0'
            END AS Points,  
            ms.ServiceName,  
            ms.ServiceName AS ServiceNameNew,
            CASE  
                WHEN bl.Is_Success = 1 THEN 'Green'  
                WHEN bl.Is_Success = 0 THEN 'Red'  
                ELSE 'Red'  
            END AS ColourCode,
            CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
        FROM [dbo].[ConsumerPointsCashDetails] bl
        LEFT JOIN M_Service ms ON ms.Service_ID = bl.Service_ID
        WHERE bl.MobileNo = @MobileNo
          AND (@Year IS NULL OR YEAR(bl.Enq_Date) = @Year)
          AND (@Month IS NULL OR MONTH(bl.Enq_Date) = @Month) and Enq_Date >='2022-08-04 00:00:00.000'
        ORDER BY bl.Enq_Date DESC;
        RETURN;
    END

    IF @Comp_ID = 'comp-1274' OR @Comp_ID = 'Comp-1274'
    BEGIN
        ;WITH ScansWithRn AS (
            SELECT 
                pe.Is_Success,
                pe.Enq_Date,
                pe.Received_Code1,
                pe.Received_Code2,
                pe.MobileNo,
                ROW_NUMBER() OVER (PARTITION BY pe.Received_Code1, pe.Received_Code2, pe.Is_Success ORDER BY pe.Enq_Date) as rn
            FROM Pro_Enq pe WITH (NOLOCK)
            WHERE pe.MobileNo = @MobileNo
              AND (@Year IS NULL OR YEAR(pe.Enq_Date) = @Year)
              AND (@Month IS NULL OR MONTH(pe.Enq_Date) = @Month)
        )
        SELECT   
            CASE   
                WHEN pe.Is_Success = 1 THEN 'Success'   
                WHEN pe.Is_Success = 0 THEN 'Invalid'   
                WHEN pe.Is_Success = 2 THEN 'Unsuccess'
                ELSE 'Unsuccess'   
            END AS Status,  
            ss.Service_ID,
            FORMAT(pe.Enq_Date, 'dd-MM-yyyy') AS Enq_Date,  
            ISNULL(cr.Comp_Name, 'N/A') AS Comp_Name,  
            ISNULL(pr.Pro_Name, 'N/A') AS Pro_Name,  
            CONCAT(pe.Received_Code1, pe.Received_Code2) AS [Code],  
            pe.Received_Code1 AS Code1,  
            pe.Received_Code2 AS Code2,  
            pe.MobileNo,
            @M_Consumer_id AS M_Consumerid,
            CASE 
                WHEN pe.Is_Success = 1 AND ISNULL(sst.IsCash, 0) <> 0 
                THEN CONCAT('+', CAST(CAST(sst.IsCash * 1.10 AS DECIMAL(18,2)) AS VARCHAR(50))) 
                ELSE '0' 
            END AS Points,  
            s.ServiceName,  
            s.ServiceName AS ServiceNameNew,
            CASE  
                WHEN pe.Is_Success = 1 THEN 'Green'  
                WHEN pe.Is_Success = 0 THEN 'Red'  
                ELSE 'Red'  
            END AS ColourCode,
            CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
        FROM ScansWithRn pe
        INNER JOIN M_Code m WITH (NOLOCK)
            ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1
            AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2
        INNER JOIN M_ServiceSubscription ss WITH (NOLOCK)
            ON m.Pro_id = ss.Pro_id 
            AND ss.IsActive = 1 AND ss.IsDelete = 0
            AND (
                m.Series_Order > ss.start_order 
                OR (m.Series_Order = ss.start_order AND m.Series_Serial >= ss.start_series)
            )
            AND (
                m.Series_Order < ss.end_order 
                OR (m.Series_Order = ss.end_order AND m.Series_Serial <= ss.end_series)
            )
        INNER JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK)
            ON sst.Subscribe_Id = ss.Subscribe_Id
            AND sst.IsActive = 1 AND sst.IsDelete = 0
        INNER JOIN M_Service s WITH (NOLOCK)
            ON ss.Service_ID = s.Service_ID
        LEFT JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = m.Pro_ID
        LEFT JOIN Comp_Reg cr WITH (NOLOCK)
            ON cr.Comp_ID = pr.Comp_ID
        WHERE pr.Comp_ID = @Comp_ID
          AND (pe.Is_Success != 1 OR pe.rn <= ISNULL(sst.Frequency, 1))
        ORDER BY pe.Enq_Date DESC;
        RETURN;
    END

    -- Get Config Points and Frequency for fallback
    IF OBJECT_ID('tempdb..#ConfigPoints') IS NOT NULL DROP TABLE #ConfigPoints;

    SELECT 
        m.Row_ID AS M_Codeid,
        SS.Service_ID,
        MAX(ISNULL(SST.Frequency, 1)) AS Frequency
    INTO #ConfigPoints
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_Code m WITH (NOLOCK) 
        ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1 
       AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2
    INNER JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = m.Pro_ID
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = m.Pro_ID
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    WHERE pe.MobileNo = @MobileNo 
      AND pr.Comp_ID = @Comp_ID
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
      AND (m.Series_Order > SS.start_order OR (m.Series_Order = SS.start_order AND m.Series_Serial >= SS.start_series))
      AND (m.Series_Order < SS.end_order OR (m.Series_Order = SS.end_order AND m.Series_Serial <= SS.end_series))
    GROUP BY m.Row_ID, SS.Service_ID;

    ;WITH EnquiryData AS (  
        SELECT   
            CASE   
                WHEN pe.Is_Success = 1 THEN 'Success'   
                WHEN pe.Is_Success = 2 THEN 'Unsuccess'   
                WHEN pe.Is_Success = 0 THEN 'Invalid'
                ELSE 'Invalid'   
            END AS Status,
            '' as Service_ID,
            FORMAT(pe.Enq_Date, 'dd-MM-yyyy') AS Enq_Date,  
            pe.Enq_Date AS Sort_Date,
            ISNULL(cr.Comp_Name, 'N/A') AS Comp_Name,  
            ISNULL(pr.Pro_Name, 'N/A') AS Pro_Name,  
            CONCAT(pe.Received_Code1, pe.Received_Code2) AS [Code],  
            TRY_CAST(pe.Received_Code1 AS INT) AS Code1,  
            TRY_CAST(pe.Received_Code2 AS INT) AS Code2,  
            pe.MobileNo,
            m.Row_ID AS M_Codeid,
            ROW_NUMBER() OVER (PARTITION BY pe.Received_Code1, pe.Received_Code2, pe.Is_Success ORDER BY pe.Enq_Date) as rn,
            pe.Is_Success
        FROM Pro_Enq pe WITH (NOLOCK)
        LEFT JOIN M_Code m WITH (NOLOCK)
            ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1   
            AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2  
        LEFT JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = m.Pro_ID  
        LEFT JOIN Comp_Reg cr WITH (NOLOCK)
            ON cr.Comp_ID = pr.Comp_ID  
        WHERE pe.MobileNo = @MobileNo   
          AND pr.Comp_ID = @Comp_ID  
          AND (@Year IS NULL OR YEAR(pe.Enq_Date) = @Year)
          AND (@Month IS NULL OR MONTH(pe.Enq_Date) = @Month)
    )
    SELECT   
        t.*,  
        mc.M_Consumerid   
    INTO #ConsumerData 
    FROM EnquiryData t  
    INNER JOIN M_Consumer mc WITH (NOLOCK) ON mc.MobileNo = t.MobileNo   
    LEFT JOIN (
        SELECT M_Codeid, MAX(Frequency) AS Frequency
        FROM #ConfigPoints
        GROUP BY M_Codeid
    ) CP ON CP.M_Codeid = t.M_Codeid
    WHERE mc.IsDelete = 0  
      AND (t.Is_Success != 1 OR t.rn <= ISNULL(CP.Frequency, 1));  
  
    -- Get Earned Points for Consumer
    IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;

    SELECT
        MC.M_Codeid,
        ROW_NUMBER() OVER (PARTITION BY MC.M_Codeid ORDER BY BMC.Createdate ASC, BL.BLoyalty_PointEarnedID ASC) AS rn,
        CAST(
            CASE 
                WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2))
                ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
            END 
        AS DECIMAL(18,2)) AS Points
    INTO #Points
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) 
        ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) 
        ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    WHERE BL.compid = @Comp_ID;

    CREATE INDEX IX_Points_MCodeid ON #Points(M_Codeid, rn);

    -- Get Soft Code Config Points for Consumer
    DECLARE @Vrkabel_User_Type INT = NULL;
    SELECT TOP 1 @Vrkabel_User_Type = Vrkabel_User_Type 
    FROM tbl_Vendorvisekycstatus WITH (NOLOCK) 
    WHERE M_consumerId = @M_Consumer_id AND Comp_id = @Comp_ID AND IsDelete = 0;

    IF OBJECT_ID('tempdb..#TempSoftCode') IS NOT NULL DROP TABLE #TempSoftCode;

    SELECT 
        SD.TrackingId,
        j.Point
    INTO #TempSoftCode 
    FROM tbl_SoftCodegenrate_Details SD WITH (NOLOCK)
    CROSS APPLY OPENJSON(SD.pointsdata)
    WITH (
        UserType NVARCHAR(100) '$.UserType',
        Point NVARCHAR(50) '$.Point'
    ) j
    LEFT JOIN User_Type UT WITH (NOLOCK)
        ON (UT.User_Type = j.UserType OR CAST(UT.Row_ID AS VARCHAR(50)) = j.UserType)
       AND (UT.Comp_ID = SD.Comp_id OR UT.Comp_ID = @Comp_ID)
       AND ISNULL(UT.IsDeleted, 0) = 0
    WHERE SD.pointsdata IS NOT NULL 
      AND ISJSON(SD.pointsdata) = 1
      AND (UT.Row_ID = @Vrkabel_User_Type OR @Vrkabel_User_Type IS NULL);

    CREATE INDEX IX_TempSoftCode ON #TempSoftCode(TrackingId);

    SELECT   
        t2.Status,  
        t2.Service_ID,  
        t2.Enq_Date,  
       -- t2.Comp_Name,  
        t2.Pro_Name as Comp_Name,  '' as Pro_Name,
        t2.Code,  
        t2.Code1,  
        t2.Code2,  
        t2.MobileNo,  
        t2.M_Consumerid,  
        t2.Sort_Date,
        CASE 
            WHEN ISNULL(P.Points, 0) > 0 THEN CONCAT('+', CAST(CAST(P.Points AS DECIMAL(18,2)) AS VARCHAR(50)))
            WHEN tsc.Point IS NOT NULL AND TRY_CAST(tsc.Point AS DECIMAL(18,2)) > 0 THEN CONCAT('+', CAST(CAST(tsc.Point AS DECIMAL(18,2)) AS VARCHAR(50)))
            WHEN sst.Points IS NOT NULL AND sst.Points <> 0 THEN CONCAT('+', CAST(sst.Points AS VARCHAR(50)))
            WHEN ISNULL(sst.IsCash, 0) <> 0 THEN CONCAT('+', CAST(CAST(sst.IsCash AS DECIMAL(18,2)) AS VARCHAR(50)))
            ELSE '0'
        END AS Points,
        c.ServiceName,  
        c.ServiceName AS ServiceNameNew,
        'Green' AS ColourCode,
        CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
    FROM #ConsumerData t2  
    INNER JOIN M_Code m 
        ON t2.Code1 = m.Code1
        AND t2.Code2 = m.Code2
    INNER JOIN M_ServiceSubscription ss 
        ON m.Pro_id = ss.Pro_id 
        AND ss.IsActive = 1 AND ss.IsDelete = 0
        AND (m.Series_Order > ss.start_order OR (m.Series_Order = ss.start_order AND m.Series_Serial >= ss.start_series))
        AND (m.Series_Order < ss.end_order OR (m.Series_Order = ss.end_order AND m.Series_Serial <= ss.end_series))
    INNER JOIN M_ServiceSubscriptionTrans sst 
        ON sst.Subscribe_Id = ss.Subscribe_Id
        AND sst.IsActive = 1 AND sst.IsDelete = 0
    INNER JOIN M_Service c 
        ON ss.Service_ID = c.Service_ID
    LEFT JOIN #Points P ON P.M_Codeid = t2.M_Codeid AND P.rn = t2.rn
    LEFT JOIN #TempSoftCode tsc ON m.LabelRequestId = tsc.TrackingId
    WHERE t2.Status = 'Success'  
  
    UNION

	SELECT   
    t2.Status,  
    t2.Service_ID,  
    t2.Enq_Date,  
  --  t2.Comp_Name,  
    t2.Pro_Name as Comp_Name,  '' as Pro_Name,
    t2.Code,  
    t2.Code1,  
    t2.Code2,  
    t2.MobileNo,  
    t2.M_Consumerid,  
    t2.Sort_Date,
    '0' AS Points,   
    s.ServiceName AS ServiceName,  
    s.ServiceName AS ServiceNameNew,
    CASE  
        WHEN t2.Status = 'Success' THEN 'Green'  
        WHEN t2.Status = 'Pending' THEN 'Yellow'  
        ELSE 'Red'  
    END AS ColourCode,
    CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
FROM #ConsumerData t2  
INNER JOIN M_Code m 
    ON t2.Code1 = m.Code1
    AND t2.Code2 = m.Code2
INNER JOIN M_ServiceSubscription ss 
    ON m.Pro_id = ss.Pro_id 
    AND ss.IsActive = 1 
    AND ss.IsDelete = 0
INNER JOIN M_Service s 
    ON ss.Service_ID = s.Service_ID
WHERE t2.Status IN ('Invalid', 'Unsuccess')  and s.Service_ID = 'SRV1018'
	 

    UNION  
  
    SELECT   
        t2.Status,  
        t2.Service_ID,  
        t2.Enq_Date,  
        -- t2.Comp_Name,  
        t2.Pro_Name as Comp_Name, '' AS Pro_Name,
        t2.Code,  
        t2.Code1,  
        t2.Code2,  
        t2.MobileNo,  
        t2.M_Consumerid,  
        t2.Sort_Date,
        '0' AS Points,   
        'buildloyalty' AS ServiceName,  
        'buildloyalty' AS ServiceNameNew,
        CASE  
            WHEN t2.Status = 'Success' THEN 'Green'  
            WHEN t2.Status = 'Pending' THEN 'Yellow'  
            ELSE 'Red'  
        END AS ColourCode,
        CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
    FROM #ConsumerData t2  
    WHERE t2.Status IN ('Invalid', 'Unsuccess')  
  
    UNION  
  
    SELECT   
        'Success' AS Status,
        '' as Service_ID,
        FORMAT(bll.UpdateDate, 'dd-MM-yyyy') AS Enq_Date,  
       -- cr.Comp_Name,  
        ''   as Comp_Name,  '' as Pro_Name,
        '' AS Code,  
        '' AS Code1,  
        '' AS Code2,  
        @MobileNo AS MobileNo,  
        @M_Consumer_id AS M_Consumerid,  
        bll.UpdateDate AS Sort_Date,
        CASE 
            WHEN bll.Points IS NOT NULL AND bll.Points <> '' AND bll.Points <> '0' THEN CONCAT('+', bll.Points)
            WHEN bll.cash IS NOT NULL AND bll.cash <> '' AND bll.cash <> '0' THEN CONCAT('+', bll.cash)
            ELSE '0'
        END AS Points,  
        bll.ServiceName,  
        CASE 
            WHEN bll.ServiceName = 'Referral' THEN 'Referral'
            WHEN bll.ServiceName = 'KYCRewards' THEN 'KYC Rewards'
            WHEN bll.ServiceName = 'Supervisor' THEN 'Supervisor'
            WHEN bll.ServiceName = 'InvoiceBenifit' THEN 'Invoice Benefit'
            WHEN bll.ServiceName = 'InvoiceRewards' THEN 'Invoice Rewards'
            WHEN bll.ServiceName = 'Transfer From User' THEN 
                CONCAT('Transfer From User, ', ISNULL(u.ConsumerName, ''), ', ', ISNULL(RIGHT(pth.fromMobileno, 10), ''), ', ', COALESCE(ut_u.User_Type, ut_u2.User_Type, u.Other_Role, ''))
            ELSE bll.ServiceName 
        END AS ServiceNameNew,
        'Green' AS ColourCode,
        CASE 
            WHEN bll.ServiceName = 'InvoiceBenifit' THEN 
                COALESCE(
                    (SELECT TOP 1 invoiceAmount FROM Namrata_RetailerInvoiceData_AI WHERE id = bll.TransacionID),
                    (SELECT TOP 1 invoiceAmount FROM Namrata_RetailerInvoiceData_AI WHERE M_Consumerid = bll.M_Consumerid AND comp_id = bll.compid AND points = bll.Points AND ABS(DATEDIFF(SECOND, createdate, bll.UpdateDate)) <= 5),
                    (SELECT TOP 1 invoiceAmount FROM Namrata_RetailerInvoiceData_AI WHERE M_Consumerid = bll.M_Consumerid AND comp_id = bll.compid AND points = bll.Points ORDER BY createdate DESC)
                )
            WHEN bll.ServiceName = 'InvoiceRewards' THEN 
                COALESCE(
                    (SELECT TOP 1 Amount FROM tblInvoiceData_AI WHERE Id = bll.TransacionID),
                    (SELECT TOP 1 Amount FROM tblInvoiceData_AI WHERE M_Consumerid = bll.M_Consumerid AND Comp_id = bll.compid AND Status = 1 ORDER BY Created_Date DESC)
                )
            ELSE NULL
        END AS InvoiceAmount  
    FROM BLoyaltyPointsEarned bll  
    INNER JOIN Comp_Reg cr ON cr.Comp_ID = bll.compid  
    LEFT JOIN PointsTransferHistory pth WITH (NOLOCK) ON bll.BLoyalty_PointEarnedID = pth.BLoyaltyPointsEarnedId
    LEFT JOIN M_Consumer u WITH (NOLOCK) ON RIGHT(pth.fromMobileno, 10) = RIGHT(u.MobileNo, 10) AND u.IsDelete = 0
    LEFT JOIN tbl_Vendorvisekycstatus vk_u WITH (NOLOCK) ON u.M_Consumerid = vk_u.M_consumerId AND vk_u.Comp_id = bll.compid AND vk_u.IsDelete = 0
    LEFT JOIN User_Type ut_u WITH (NOLOCK) ON CAST(vk_u.Vrkabel_User_Type AS VARCHAR) = CAST(ut_u.Row_ID AS VARCHAR) AND ut_u.Comp_ID = bll.compid
    LEFT JOIN User_Type ut_u2 WITH (NOLOCK) ON CAST(u.Vrkabel_User_Type AS VARCHAR) = CAST(ut_u2.Row_ID AS VARCHAR) AND ut_u2.Comp_ID = bll.compid
    WHERE bll.M_Consumerid = @M_Consumer_id   
      AND bll.ServiceName IN ('Referral', 'KYCRewards', 'Supervisor', 'InvoiceBenifit', 'InvoiceRewards', 'Transfer From User')   
      AND bll.compid = @Comp_ID  
      AND (@Year IS NULL OR YEAR(bll.UpdateDate) = @Year)
      AND (@Month IS NULL OR MONTH(bll.UpdateDate) = @Month)
  
    ORDER BY Sort_Date DESC;  
END
GO
