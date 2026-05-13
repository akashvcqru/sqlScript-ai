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

    DECLARE @MobileNo VARCHAR(20)
    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_Consumerid AND IsDelete = 0;

    IF (@CompId = 'Comp-1152')
    BEGIN
        SELECT COALESCE(SUM(CAST(cash AS INT)), 0) as TotalPoints
        FROM ConsumerPointsCashDetails
        WHERE M_Consumerid = @M_Consumerid;
        RETURN;
    END

    -- 1. Scan-based points from Config
    DECLARE @ScanPoints DECIMAL(18,2) = 0;
    
    SELECT @ScanPoints = ISNULL(SUM(ConfigPoints), 0)
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
        GROUP BY M.Row_ID
    ) t;

    -- 2. Referral/KYC Rewards
    DECLARE @OtherPoints DECIMAL(18,2) = 0;
    SELECT @OtherPoints = COALESCE(SUM(CAST(Points AS DECIMAL(18,2))), 0)
    FROM BLoyaltyPointsEarned
    WHERE M_Consumerid = @M_Consumerid 
      AND (compid = @CompId OR (@CompId IN ('Comp-1650', 'Comp-1567') AND compid IN ('Comp-1650', 'Comp-1567')))
      AND ServiceName IN ('Referral', 'KYCRewards');

    -- 3. Extra Amount for specific company (if still needed)
    DECLARE @ExtraAmount DECIMAL(18,2) = 0;
    IF @CompId = 'Comp-1841'
    BEGIN
        SELECT @ExtraAmount = COALESCE(SUM(CAST(extraAmount AS DECIMAL(18,2))), 0)
        FROM BLoyaltyPointsEarned
        WHERE M_Consumerid = @M_Consumerid AND compid = @CompId;
    END

    SELECT CAST(@ScanPoints + @OtherPoints + @ExtraAmount AS INT) AS TotalPoints;
END
