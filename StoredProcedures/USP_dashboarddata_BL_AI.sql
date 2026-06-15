USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_dashboarddata_BL_AI]
(    
 @M_consumerid INT,    
 @compid VARCHAR(10) = NULL ,
 @FromDate datetime = null,
 @endDate datetime = null
)    
AS    
BEGIN  
    SET NOCOUNT ON;
    DECLARE @TotalCash DECIMAL(18,2) = 0;
    DECLARE @TotalCodeCheck INT = 0;
    DECLARE @TotalSuccessCheck INT = 0;
    DECLARE @USERTYPE INT = 0;
    DECLARE @FilterDate DATETIME = '1900-08-04 00:00:00.000';

    IF (@compid = 'Comp-1152')
    BEGIN
        SELECT @USERTYPE = Vrkabel_User_Type FROM M_Consumer WHERE M_Consumerid = @M_consumerid;
        IF (@USERTYPE IN (121)) SET @FilterDate = '2024-02-24 00:00:00.000';
        IF (@USERTYPE IN (141,119)) SET @FilterDate = '2022-08-04 00:00:00.000';

        SELECT @TotalCash = ISNULL(SUM(Cash), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate;
        SELECT @TotalSuccessCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate AND Is_Success = 1;
        SELECT @TotalCodeCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate;
    END
    ELSE
    BEGIN
        DECLARE @MobileNo VARCHAR(20)
        SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_consumerid AND IsDelete = 0;

        -- Calculate from Config
        SELECT 
            @TotalCash = SUM(ConfigCash)
        FROM (
            SELECT 
                MAX(CAST(
                    CASE 
                        WHEN @compid = 'Comp-1274' THEN ISNULL(SST.IsCash, 0) * 1.10
                        ELSE ISNULL(SST.IsCash, 0)
                    END 
                AS DECIMAL(18,2))) AS ConfigCash
            FROM Pro_Enq PE WITH (NOLOCK)
            INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
            INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
            INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = M.Pro_ID
            INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
            WHERE PE.MobileNo = @MobileNo
              AND PE.Is_Success = '1'
              AND PR.Comp_ID = @compid --(PR.Comp_ID = @compid OR (@compid IN ('Comp-1650', 'Comp-1567') AND PR.Comp_ID IN ('Comp-1650', 'Comp-1567')))
              AND SS.IsActive = 1 AND SS.IsDelete = 0
              AND SST.IsActive = 1 AND SST.IsDelete = 0
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
        ) t;

        SELECT @TotalSuccessCheck = COUNT(Pro_Enq.Received_Code1)  
        FROM M_Consumer AS mc  
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo  
        WHERE Pro_Enq.Comp_ID = @compid-- (Pro_Enq.Comp_ID = @compid OR (@compid IN ('Comp-1650', 'Comp-1567') AND Pro_Enq.Comp_ID IN ('Comp-1650', 'Comp-1567') ) ) AND mc.M_Consumerid = @M_consumerid AND Is_Success = 1;

        SELECT @TotalCodeCheck = COUNT(Pro_Enq.Received_Code1)  
        FROM M_Consumer AS mc  
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo  
        WHERE Pro_Enq.Comp_ID = @compid-- (Pro_Enq.Comp_ID = @compid OR (@compid IN ('Comp-1650', 'Comp-1567') AND Pro_Enq.Comp_ID IN ('Comp-1650', 'Comp-1567') ) ) AND mc.M_Consumerid = @M_consumerid;
    END

    -- Result 0: Total Code Check
    SELECT @TotalCodeCheck as Val;

    -- Result 1: Redeem Points (BPointsTransaction + tblUPITransactionDetails)
    SELECT 
        ISNULL((SELECT SUM(CONVERT(INT, RedeemPoints)) FROM BPointsTransaction WITH (NOLOCK) WHERE RedeemBy = @M_consumerid AND bpstatus <> 'FAILURE'), 0) 
        + ISNULL((SELECT SUM(CONVERT(INT, Amount)) FROM tblUPITransactionDetails WHERE M_Consumerid = @M_consumerid AND Comp_Id = @compid AND Status = 'Success' AND LEN(Code1) > 1 AND LEN(Code2) > 6), 0) as Val;

    -- Result 2: Total Success Check
    SELECT @TotalSuccessCheck as Val;

    -- Result 3: Total Cash
    SELECT @TotalCash as Val;

    -- Result 4: Transferred Cash
    SELECT ISNULL(SUM(CONVERT(INT, Amount)), 0) as Val
    FROM Transactions WITH (NOLOCK)
    WHERE M_CounserID = @M_consumerid AND Issuccess = 1 AND TransactionDate >= @FilterDate AND CompId = SUBSTRING(@compid, CHARINDEX('-', @compid) + 1, LEN(@compid))
      AND (@FromDate IS NULL OR TransactionDate >= @FromDate) AND (@endDate IS NULL OR TransactionDate <= @endDate);
END;
