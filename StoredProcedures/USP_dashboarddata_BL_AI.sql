SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_dashboarddata_BL_AI]
(
@M_consumerid int,
@compid varchar(10)=null
)
AS
BEGIN
        DECLARE @TotalCode INT, @TotalEarnedPoints INT, @SuccessCode INT, @TotalCash decimal(18,2)

        SELECT @TotalCode = COUNT(Pro_Enq.[Received_Code1])
        FROM M_Consumer as mc
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo
        INNER JOIN M_code ON CAST(M_Code.Code1 as nvarchar(20)) = Pro_Enq.Received_Code1 AND CAST(M_Code.Code2 as nvarchar(20)) = Pro_Enq.Received_Code2
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID
        WHERE Comp_Reg.Comp_ID = @compid
          AND [M_Consumerid] = @M_consumerid

        SELECT @TotalEarnedPoints = ISNULL(SUM(TRY_CAST([RedeemPoints] AS INT)), 0)
        FROM [BPointsTransaction] with(nolock)
        WHERE [RedeemBy] = @M_consumerid
          AND bpstatus <> 'FAILURE'

        SELECT @SuccessCode = COUNT(Pro_Enq.[Received_Code1])
        FROM M_Consumer as mc
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo
        INNER JOIN M_code ON CAST(M_Code.Code1 as nvarchar(20)) = Pro_Enq.Received_Code1 AND CAST(M_Code.Code2 as nvarchar(20)) = Pro_Enq.Received_Code2
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID
        WHERE Comp_Reg.Comp_ID = @compid
          AND [M_Consumerid] = @M_consumerid
          AND Is_Success = 1

        SELECT @TotalCash = ISNULL(SUM(TRY_CAST(Cash AS DECIMAL(18,2))), 0)
        FROM dbo.BLoyaltyPointsEarned
        WHERE M_Consumerid = @M_consumerid
          AND (compid = @compid or (@compid IN ('Comp-1650', 'Comp-1567') and compid IN ('Comp-1650', 'Comp-1567') ))

        SELECT @TotalCode as TotalCode, @TotalEarnedPoints as TotalEarnedPoints, @SuccessCode as SuccessCode, @TotalCash as TotalCash
END
GO
