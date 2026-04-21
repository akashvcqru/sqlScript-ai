SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_dashboarddata_BL_ServiceWise_AI]
(
@M_consumerid int,
@compid varchar(10)=null,
@Service_ID varchar(10)=null
)
AS
BEGIN
        DECLARE @TotalCode INT, @TotalEarnedPoints INT, @SuccessCode INT, @TotalCash decimal(18,2)

        SELECT @TotalCode = COUNT(pe.[Received_Code1])
        FROM M_Consumer as mc
        INNER JOIN Pro_Enq pe ON pe.MobileNo = mc.MobileNo
        INNER JOIN M_code ON CAST(M_Code.Code1 as nvarchar(20)) = pe.Received_Code1 AND CAST(M_Code.Code2 as nvarchar(20)) = pe.Received_Code2
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID
		INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = (SELECT TOP 1 SST_Id FROM BLoyaltyPointsEarned WHERE Code1 = CAST(M_Code.Code1 as nvarchar(20)) AND Code2 = CAST(M_Code.Code2 as nvarchar(20)))
		INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
        WHERE Comp_Reg.Comp_ID = @compid
          AND mc.[M_Consumerid] = @M_consumerid
		  AND (ms.Service_ID = @Service_ID OR @Service_ID IS NULL)

        SELECT @TotalEarnedPoints = ISNULL(SUM(TRY_CAST(bp.[Points] AS INT)), 0)
        FROM [BLoyaltyPointsEarned] bp with(nolock)
		INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id
		INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
        WHERE bp.M_Consumerid = @M_Consumerid
		  AND (ms.Service_ID = @Service_ID OR @Service_ID IS NULL)

        SELECT @SuccessCode = COUNT(pe.[Received_Code1])
        FROM M_Consumer as mc
        INNER JOIN Pro_Enq pe ON pe.MobileNo = mc.MobileNo
        INNER JOIN M_code ON CAST(M_Code.Code1 as nvarchar(20)) = pe.Received_Code1 AND CAST(M_Code.Code2 as nvarchar(20)) = pe.Received_Code2
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID
		INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = (SELECT TOP 1 SST_Id FROM BLoyaltyPointsEarned WHERE Code1 = CAST(M_Code.Code1 as nvarchar(20)) AND Code2 = CAST(M_Code.Code2 as nvarchar(20)))
		INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
        WHERE Comp_Reg.Comp_ID = @compid
          AND mc.[M_Consumerid] = @M_consumerid
          AND pe.Is_Success = 1
		  AND (ms.Service_ID = @Service_ID OR @Service_ID IS NULL)

        SELECT @TotalCash = ISNULL(SUM(TRY_CAST(bp.Cash AS DECIMAL(18,2))), 0)
        FROM dbo.BLoyaltyPointsEarned bp
		INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id
		INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
        WHERE bp.M_Consumerid = @M_Consumerid
          AND (bp.compid = @compid or (@compid IN ('Comp-1650', 'Comp-1567') and bp.compid IN ('Comp-1650', 'Comp-1567') ))
		  AND (ms.Service_ID = @Service_ID OR @Service_ID IS NULL)

        SELECT @TotalCode as TotalCode, @TotalEarnedPoints as TotalEarnedPoints, @SuccessCode as SuccessCode, @TotalCash as TotalCash
END
GO
