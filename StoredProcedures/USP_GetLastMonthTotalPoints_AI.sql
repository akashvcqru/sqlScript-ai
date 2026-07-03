USE [Vcqru]
GO

/****** Object:  StoredProcedure [dbo].[USP_GetLastMonthTotalPoints_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetLastMonthTotalPoints_AI]
(
    @M_Consumerid INT,
    @CompID VARCHAR(50),
    @StartOfLastMonth DATETIME,
    @StartOfThisMonth DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MobileNo VARCHAR(20)
    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_Consumerid AND IsDelete = 0;

    IF @MobileNo IS NULL
    BEGIN
        SELECT 0 AS LastMonthPoints;
        RETURN;
    END

    -- Check if company has specific logic like Comp-1152
    IF @CompID IN ('comp-1152', 'Comp-1152')
    BEGIN
        SELECT ISNULL(SUM(TRY_CAST(points AS DECIMAL(18,2))), 0) AS LastMonthPoints
        FROM [dbo].[ConsumerPointsCashDetails]
        WHERE MobileNo = @MobileNo 
          AND Enq_Date >= @StartOfLastMonth 
          AND Enq_Date < @StartOfThisMonth 
          AND Is_Success = 1;
        RETURN;
    END

    -- For other companies, calculate Configured Scan Points + Referral Points for last month
    DECLARE @CompanyList TABLE (Comp_Id VARCHAR(50) PRIMARY KEY);
    INSERT INTO @CompanyList VALUES (@CompID);

    -- 1. Get User Scans for last month
    IF OBJECT_ID('tempdb..#UserScansLastMonth') IS NOT NULL DROP TABLE #UserScansLastMonth;
    IF OBJECT_ID('tempdb..#EarnedPointsLastMonth') IS NOT NULL DROP TABLE #EarnedPointsLastMonth;
    IF OBJECT_ID('tempdb..#ConfigPointsLastMonth') IS NOT NULL DROP TABLE #ConfigPointsLastMonth;

    SELECT 
        M.Row_ID as M_Codeid,
        M.Pro_ID,
        M.Series_Order,
        M.Series_Serial,
        ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2 ORDER BY PE.Enq_Date) as rn
    INTO #UserScansLastMonth
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    INNER JOIN @CompanyList CL ON PR.Comp_Id = CL.Comp_Id
    WHERE PE.MobileNo = @MobileNo 
      AND PE.Is_Success = '1'
      AND PE.Enq_Date >= @StartOfLastMonth
      AND PE.Enq_Date < @StartOfThisMonth;

    -- 2. Get Earned Points for last month scans/updates
    SELECT
        MC.M_Codeid,
        ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
        MAX(CAST(
            CASE 
                WHEN @CompID = 'Comp-1274' THEN ISNULL(BL.Cash, 0) * 1.10
                ELSE ISNULL(BL.Points, 0)
            END 
        AS DECIMAL(18,2))) AS Points
    INTO #EarnedPointsLastMonth
    FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
    INNER JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
    INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
    LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON BL.SST_id = SST.SST_Id
    LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
    WHERE BL.M_Consumerid = @M_Consumerid
      AND BL.UpdateDate >= @StartOfLastMonth
      AND BL.UpdateDate < @StartOfThisMonth
    GROUP BY MC.M_Codeid, ISNULL(SS.Service_ID, 'SRV1001');

    -- 3. Get Config Points for last month scans
    SELECT 
        US.M_Codeid,
        SS.Service_ID,
        MAX(CAST(
            CASE 
                WHEN @CompID = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                ELSE CASE WHEN SST.Points IS NULL OR SST.Points = 0 THEN ISNULL(SST.IsCash, 0) ELSE SST.Points END
            END 
        AS DECIMAL(18,2))) AS ConfigPoints
    INTO #ConfigPointsLastMonth
    FROM #UserScansLastMonth US
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

    -- 4. Calculate Scan Points
    DECLARE @ScanPoints DECIMAL(18,2) = 0;
    SELECT 
        @ScanPoints = ISNULL(SUM(ISNULL(CP.ConfigPoints, ISNULL(EP.Points, 0))), 0)
    FROM #UserScansLastMonth US
    LEFT JOIN (
        SELECT M_Codeid, MAX(ConfigPoints) AS ConfigPoints
        FROM #ConfigPointsLastMonth
        GROUP BY M_Codeid
    ) CP ON CP.M_Codeid = US.M_Codeid
    LEFT JOIN (
        SELECT M_Codeid, MAX(Points) AS Points
        FROM #EarnedPointsLastMonth
        GROUP BY M_Codeid
    ) EP ON EP.M_Codeid = US.M_Codeid
    WHERE US.rn = 1;

    -- 5. Calculate Referral and other points for last month
    DECLARE @RefPoints DECIMAL(18,2) = 0;
    SELECT 
        @RefPoints = ISNULL(SUM(CAST(Points AS DECIMAL(18,2))), 0)
    FROM BLoyaltyPointsEarned BL
    INNER JOIN @CompanyList CL ON BL.compid = CL.Comp_Id
    WHERE BL.M_Consumerid = @M_Consumerid 
      AND BL.ServiceName IN ('Referral', 'KYCRewards', 'Supervisor', 'InvoiceBenifit', 'InvoiceRewards')
      AND BL.UpdateDate >= @StartOfLastMonth
      AND BL.UpdateDate < @StartOfThisMonth;

    -- Total last month points
    SELECT ISNULL(@ScanPoints, 0) + ISNULL(@RefPoints, 0) AS LastMonthPoints;
END
GO
