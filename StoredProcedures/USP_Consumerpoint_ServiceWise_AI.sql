SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_Consumerpoint_ServiceWise_AI]
@CompId varchar(50),
@M_Consumerid varchar(50),
@Service_ID varchar(10)=null
as
begin
    SET NOCOUNT ON;

    DECLARE @MobileNo VARCHAR(20)
    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_Consumerid AND IsDelete = 0;

    IF @MobileNo IS NULL RETURN;

    SELECT COALESCE(SUM(ConfigPoints), 0)
    FROM (
        SELECT 
            MAX(CAST(
                CASE 
                    WHEN @CompId = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                    ELSE ISNULL(SST.Points, 0)
                END 
            AS DECIMAL(18,2))) AS ConfigPoints
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        WHERE PE.MobileNo = @MobileNo
          AND PE.Is_Success = '1'
          AND (PR.Comp_ID = @CompId OR (@CompId IN ('Comp-1650', 'Comp-1567') AND PR.Comp_ID IN ('Comp-1650', 'Comp-1567')))
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND (SS.Service_ID = @Service_ID OR @Service_ID IS NULL)
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
          AND (
              M.Series_Order > SS.start_order 
              OR (M.Series_Order = SS.start_order AND M.Series_Serial >= SS.start_series)
          )
          AND (
              M.Series_Order < SS.end_order 
              OR (M.Series_Order = SS.end_order AND M.Series_Serial <= SS.end_series)
          )
        GROUP BY M.Row_ID
    ) t
end
GO
