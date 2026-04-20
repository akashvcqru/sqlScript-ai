USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_Consumerpoint_AI]
@CompId varchar(50),
@M_Consumerid varchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF (@CompId = 'Comp-1152')
    BEGIN
        SELECT COALESCE(SUM(CAST(cash AS INT)), 0) as TotalPoints
        FROM ConsumerPointsCashDetails
        WHERE M_Consumerid = @M_Consumerid;
        RETURN;
    END

    SELECT COALESCE(SUM(CAST(bp.Points AS INT)), 0) 
         + COALESCE(CAST(SUM(CASE WHEN @CompId = 'Comp-1841' THEN bp.extraAmount ELSE 0 END) AS INT), 0)  
         + COALESCE(
               (SELECT COALESCE(SUM(CAST(bp2.Points AS INT)), 0)
                FROM BLoyaltyPointsEarned bp2
                WHERE bp2.M_Consumerid = @M_Consumerid AND bp2.compid = @CompId AND bp2.ServiceName in ('Referral','KYCRewards')
               ), 0
           ) AS TotalPoints
    FROM BLoyaltyPointsEarned bp
    INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id
    INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
    WHERE bp.M_Consumerid = @M_Consumerid AND (ms.Comp_ID = @CompId or (@compid IN ('Comp-1650', 'Comp-1567') and ms.Comp_ID IN ('Comp-1650', 'Comp-1567') ));
END
