SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antigravity AI
-- Create date: 2026-03-31
-- Description:	Stored procedure to get total loyalty points by brand for a consumer
-- =============================================
CREATE OR ALTER PROCEDURE USP_GetPointsByBrand_AI
	@ConsumerId VARCHAR(50),
	@CompId VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @MobileNo VARCHAR(20)
    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @ConsumerId AND IsDelete = 0;

    IF @MobileNo IS NULL RETURN;

	SELECT 
		SUM(ConfigPoints) AS TotalPoints, 
		Brand_Code
    FROM (
        SELECT 
            PR.Brand_Code,
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
          AND (SS.Comp_ID = @CompId OR (@CompId IN ('Comp-1650', 'Comp-1567') AND SS.Comp_ID IN ('Comp-1650', 'Comp-1567')))
          AND SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
          AND CONCAT(FORMAT(M.Series_Order, '000#'), FORMAT(M.Series_Serial, '000#')) 
              BETWEEN CONCAT(FORMAT(SS.start_order, '000#'), FORMAT(SS.start_series, '000#')) 
                  AND CONCAT(FORMAT(SS.end_order, '000#'), FORMAT(SS.end_series, '000#'))
        GROUP BY M.Row_ID, PR.Brand_Code
    ) t
	GROUP BY Brand_Code;
END
GO
