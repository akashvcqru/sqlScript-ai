SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[USP_Consumerpoint_AI]
@CompId varchar(50),
@M_Consumerid varchar(50)
as
begin
SELECT COALESCE(SUM(TRY_CAST(bp.Points AS INT)), 0) as TotalPoints
FROM BLoyaltyPointsEarned bp
INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id
INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
WHERE bp.M_Consumerid = @M_Consumerid AND (ms.Comp_ID = @CompId or (@compid IN ('Comp-1650', 'Comp-1567') and ms.Comp_ID IN ('Comp-1650', 'Comp-1567') ));
end
GO
