USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_GetChildUsers_AI]
    @dealerid INT,
    @comp_id VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        mc.M_Consumerid, 
        mc.ConsumerName, 
        mc.Email, 
        mc.MobileNo,
        -- Total Points
        CASE 
            WHEN @comp_id IN ('comp-1152', 'Comp-1152') THEN 
                ISNULL((SELECT SUM(TRY_CAST(points AS DECIMAL(18,2))) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = mc.MobileNo), 0)
            ELSE
                -- Scan Points + Referral Points
                ISNULL((
                    SELECT SUM(ISNULL(CP.ConfigPoints, ISNULL(EP.Points, 0)))
                    FROM (
                        SELECT 
                            M.Row_ID as M_Codeid,
                            M.Pro_ID,
                            M.Series_Order,
                            M.Series_Serial,
                            ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2 ORDER BY PE.Enq_Date) as rn
                        FROM Pro_Enq PE WITH (NOLOCK)
                        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
                        INNER JOIN Pro_Reg pr ON pr.Pro_ID = M.Pro_ID
                        WHERE PE.MobileNo = mc.MobileNo 
                          AND PE.Is_Success = '1'
                          AND (pr.Comp_ID = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND pr.Comp_ID IN ('Comp-1650', 'Comp-1567')))
                    ) US
                    LEFT JOIN (
                        SELECT
                            MC.M_Codeid,
                            MAX(CAST(
                                CASE 
                                    WHEN @comp_id = 'Comp-1274' THEN ISNULL(BL.Cash, 0) * 1.10
                                    ELSE ISNULL(BL.Points, 0)
                                END 
                            AS DECIMAL(18,2))) AS Points
                        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
                        INNER JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
                        INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
                        WHERE BL.M_Consumerid = mc.M_Consumerid
                          AND (BL.compid = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND BL.compid IN ('Comp-1650', 'Comp-1567')))
                        GROUP BY MC.M_Codeid
                    ) EP ON EP.M_Codeid = US.M_Codeid
                    LEFT JOIN (
                        SELECT 
                            M.Row_ID as M_Codeid,
                            MAX(CAST(
                                CASE 
                                    WHEN @comp_id = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                                    ELSE CASE WHEN SST.Points IS NULL OR SST.Points = 0 THEN ISNULL(SST.IsCash, 0) ELSE SST.Points END
                                END 
                            AS DECIMAL(18,2))) AS ConfigPoints
                        FROM Pro_Enq PE WITH (NOLOCK)
                        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
                        INNER JOIN Pro_Reg pr ON pr.Pro_ID = M.Pro_ID
                        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
                        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
                        WHERE PE.MobileNo = mc.MobileNo
                          AND PE.Is_Success = '1'
                          AND SS.IsActive = 1 AND SS.IsDelete = 0
                          AND SST.IsActive = 1 AND SST.IsDelete = 0
                          AND (SS.Comp_ID = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND SS.Comp_ID IN ('Comp-1650', 'Comp-1567')))
                          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
                          AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
                          AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))
                        GROUP BY M.Row_ID
                    ) CP ON CP.M_Codeid = US.M_Codeid
                    WHERE US.rn = 1
                ), 0)
                +
                ISNULL((
                    SELECT SUM(CAST(Points AS DECIMAL(18,2)))
                    FROM BLoyaltyPointsEarned WITH (NOLOCK)
                    WHERE M_Consumerid = mc.M_Consumerid 
                      AND (compid = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND compid IN ('Comp-1650', 'Comp-1567')))
                      AND ServiceName IN ('Referral', 'KYCRewards', 'Supervisor', 'InvoiceBenifit', 'InvoiceRewards')
                ), 0)
        END AS totalPoints,
        -- Redeem Points
        ISNULL((
            SELECT ISNULL(SUM(TRY_CAST(RedeemPoints AS INT)), 0) 
            FROM BPointsTransaction WHERE RedeemBy = mc.M_Consumerid AND bpstatus <> 'FAILURE'
        ), 0)
        + 
        ISNULL((
            SELECT ISNULL(SUM(Amount), 0) 
            FROM ClaimDetails cl 
            WHERE RIGHT(cl.Mobileno, 10) = RIGHT(mc.MobileNo, 10) AND cl.Isapproved <> 2
              AND (cl.Comp_id = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND cl.Comp_ID IN ('Comp-1650', 'Comp-1567')))
        ), 0)
        +
        ISNULL((
            SELECT ISNULL(SUM(ISNULL(Points_Val, Amount)), 0) 
            FROM tblUPITransactionDetails 
            WHERE RIGHT(Mobileno, 10) = RIGHT(mc.MobileNo, 10) AND Status IN ('Pending','Success') AND Comp_id = @comp_id AND Code2 > 0
        ), 0)
        +
        ISNULL((
            SELECT ISNULL(SUM(Amount), 0)
            FROM Transactions WITH (NOLOCK)
            WHERE IsSuccess = 1
              AND M_CounserID = mc.M_Consumerid
              AND 'Comp-' + CAST(CompId AS VARCHAR) = @comp_id
              AND TransactionDate >= '2022-11-25 00:00:00.000'
              AND TransactionDate < GETDATE()
        ), 0) AS claimPoint,
        -- Pending Points
        (
            CASE 
                WHEN @comp_id IN ('comp-1152', 'Comp-1152') THEN 
                    ISNULL((SELECT SUM(TRY_CAST(points AS DECIMAL(18,2))) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = mc.MobileNo), 0)
                ELSE
                    -- Scan Points + Referral Points
                    ISNULL((
                        SELECT SUM(ISNULL(CP.ConfigPoints, ISNULL(EP.Points, 0)))
                        FROM (
                            SELECT 
                                M.Row_ID as M_Codeid,
                                M.Pro_ID,
                                M.Series_Order,
                                M.Series_Serial,
                                ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2 ORDER BY PE.Enq_Date) as rn
                            FROM Pro_Enq PE WITH (NOLOCK)
                            INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
                            INNER JOIN Pro_Reg pr ON pr.Pro_ID = M.Pro_ID
                            WHERE PE.MobileNo = mc.MobileNo 
                              AND PE.Is_Success = '1'
                              AND (pr.Comp_ID = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND pr.Comp_ID IN ('Comp-1650', 'Comp-1567')))
                        ) US
                        LEFT JOIN (
                            SELECT
                                MC.M_Codeid,
                                MAX(CAST(
                                    CASE 
                                        WHEN @comp_id = 'Comp-1274' THEN ISNULL(BL.Cash, 0) * 1.10
                                        ELSE ISNULL(BL.Points, 0)
                                    END 
                                AS DECIMAL(18,2))) AS Points
                            FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
                            INNER JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
                            INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
                            WHERE BL.M_Consumerid = mc.M_Consumerid
                              AND (BL.compid = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND BL.compid IN ('Comp-1650', 'Comp-1567')))
                            GROUP BY MC.M_Codeid
                        ) EP ON EP.M_Codeid = US.M_Codeid
                        LEFT JOIN (
                            SELECT 
                                M.Row_ID as M_Codeid,
                                MAX(CAST(
                                    CASE 
                                        WHEN @comp_id = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                                        ELSE CASE WHEN SST.Points IS NULL OR SST.Points = 0 THEN ISNULL(SST.IsCash, 0) ELSE SST.Points END
                                    END 
                                AS DECIMAL(18,2))) AS ConfigPoints
                            FROM Pro_Enq PE WITH (NOLOCK)
                            INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
                            INNER JOIN Pro_Reg pr ON pr.Pro_ID = M.Pro_ID
                            INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
                            INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
                            WHERE PE.MobileNo = mc.MobileNo
                              AND PE.Is_Success = '1'
                              AND SS.IsActive = 1 AND SS.IsDelete = 0
                              AND SST.IsActive = 1 AND SST.IsDelete = 0
                              AND (SS.Comp_ID = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND SS.Comp_ID IN ('Comp-1650', 'Comp-1567')))
                              AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
                              AND (M.Series_Order > SS.start_order OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series))
                              AND (M.Series_Order < SS.end_order OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series))
                            GROUP BY M.Row_ID
                        ) CP ON CP.M_Codeid = US.M_Codeid
                        WHERE US.rn = 1
                    ), 0)
                    +
                    ISNULL((
                        SELECT SUM(CAST(Points AS DECIMAL(18,2)))
                        FROM BLoyaltyPointsEarned WITH (NOLOCK)
                        WHERE M_Consumerid = mc.M_Consumerid 
                          AND (compid = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND compid IN ('Comp-1650', 'Comp-1567')))
                          AND ServiceName IN ('Referral', 'KYCRewards', 'Supervisor', 'InvoiceBenifit', 'InvoiceRewards')
                    ), 0)
            END
        )
        -
        (
            ISNULL((
                SELECT ISNULL(SUM(TRY_CAST(RedeemPoints AS INT)), 0) 
                FROM BPointsTransaction WHERE RedeemBy = mc.M_Consumerid AND bpstatus <> 'FAILURE'
            ), 0)
            + 
            ISNULL((
                SELECT ISNULL(SUM(Amount), 0) 
                FROM ClaimDetails cl 
                WHERE RIGHT(cl.Mobileno, 10) = RIGHT(mc.MobileNo, 10) AND cl.Isapproved <> 2
                  AND (cl.Comp_id = @comp_id OR (@comp_id IN ('Comp-1650', 'Comp-1567') AND cl.Comp_ID IN ('Comp-1650', 'Comp-1567')))
            ), 0)
            +
            ISNULL((
                SELECT ISNULL(SUM(ISNULL(Points_Val, Amount)), 0) 
                FROM tblUPITransactionDetails 
                WHERE RIGHT(Mobileno, 10) = RIGHT(mc.MobileNo, 10) AND Status IN ('Pending','Success') AND Comp_id = @comp_id AND Code2 > 0
            ), 0)
            +
            ISNULL((
                SELECT ISNULL(SUM(Amount), 0)
                FROM Transactions WITH (NOLOCK)
                WHERE IsSuccess = 1
                  AND M_CounserID = mc.M_Consumerid
                  AND 'Comp-' + CAST(CompId AS VARCHAR) = @comp_id
                  AND TransactionDate >= '2022-11-25 00:00:00.000'
                  AND TransactionDate < GETDATE()
            ), 0)
        ) AS availablePoints
    FROM M_Consumer mc 
    INNER JOIN tbl_Vendorvisekycstatus vc ON mc.M_Consumerid = vc.M_consumerId 
    WHERE vc.Comp_id = @comp_id 
      AND vc.Dealer_M_consumerid = @dealerid
END
GO
