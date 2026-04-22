SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Description: Consolidated dashboard summary for multi-user dashboard.
-- Optimized to return overall stats, service-wise stats, and claims in ONE call.
-- Incorporates check for service-wise gift existence.
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDashboardSummary_AI]
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

    -- Flag for service-wise gifts presence (User Requirement: gift_clim -> Claim_gift)
    DECLARE @HasServiceWiseGifts BIT = 0;
    IF EXISTS (SELECT 1 FROM Claim_gift WHERE CompID = @CompID AND Service_id IS NOT NULL AND Isdelete = 0)
    BEGIN
        SET @HasServiceWiseGifts = 1;
    END

    -- Result Set 1: Overall Stats + Logic Flag
    SELECT 
        (SELECT COUNT(pe.Received_Code1) 
         FROM Pro_Enq pe 
         WHERE pe.MobileNo = @MobileNo) as TotalCode,
        (SELECT 
            (SELECT ISNULL(SUM(TRY_CAST(RedeemPoints AS INT)), 0) 
             FROM BPointsTransaction WHERE RedeemBy = @M_Consumerid AND bpstatus <> 'FAILURE')
            +             (SELECT ISNULL(SUM(Amount), 0) 
              FROM ClaimDetails cl 
              WHERE RIGHT(cl.Mobileno, 10) = RIGHT(@MobileNo, 10) AND cl.Isapproved <> 2
                AND (cl.Comp_id = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND cl.Comp_ID IN ('Comp-1650', 'Comp-1567'))))
            +
            (SELECT ISNULL(SUM(Amount), 0) 
             FROM tblUPITransactionDetails 
             WHERE RIGHT(Mobileno, 10) = RIGHT(@MobileNo, 10) AND Status IN ('Pending','Success') AND Comp_id = @CompID AND Code2 > 0)
        ) as ReedemPoints,
        (SELECT COUNT(pe.Received_Code1) 
         FROM Pro_Enq pe 
         WHERE pe.MobileNo = @MobileNo AND pe.Is_Success = 1) as SuccessCode,
        (SELECT ISNULL(SUM(TRY_CAST(Cash AS DECIMAL(18,2))), 0) 
         FROM BLoyaltyPointsEarned WHERE M_Consumerid = @M_Consumerid AND CompID = @CompID) as TotalCash,
        (SELECT COALESCE(SUM(TRY_CAST(bp.Points AS DECIMAL(18,2))), 0) 
         FROM BLoyaltyPointsEarned bp
         WHERE bp.M_Consumerid = @M_Consumerid 
           AND (bp.CompID = @CompID OR (@CompID IN ('Comp-1650', 'Comp-1567') AND bp.CompID IN ('Comp-1650', 'Comp-1567')))) as TotalPoints,
        @HasServiceWiseGifts as HasServiceWiseGifts;

    -- Result Set 2: Service-Wise Stats
    SELECT 
        ms.Service_ID,
        ms_name.ServiceName,
        ISNULL(SUM(TRY_CAST(bp.Points AS DECIMAL(18,2))), 0) as ServiceTotalPoints,
        ISNULL(SUM(TRY_CAST(bp.Cash AS DECIMAL(18,2))), 0) as ServiceTotalCash
    FROM M_ServiceSubscription ms
    LEFT JOIN M_Service ms_name ON ms_name.Service_ID = ms.Service_ID
    LEFT JOIN M_ServiceSubscriptionTrans mss ON ms.Subscribe_Id = mss.Subscribe_Id
    LEFT JOIN BLoyaltyPointsEarned bp ON bp.M_Consumerid = @M_Consumerid AND bp.SST_Id = mss.SST_Id
    WHERE ms.Comp_ID = @CompID AND ms.IsActive = 1
    GROUP BY ms.Service_ID, ms_name.ServiceName;

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
            Amount as ClaimAmount
        FROM tblUPITransactionDetails 
        WHERE RIGHT(Mobileno, 10) = RIGHT(@MobileNo, 10) 
          AND Status IN ('Pending','Success') 
          AND Comp_id = @CompID 
          AND Code2 > 0
    ) t
    GROUP BY Service_ID;
END
GO
