USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Description: Optimized dashboard data retrieval for multi-user dashboard.
-- Returns ONLY basic scan counts, skipping point and cash calculations for performance.
CREATE OR ALTER PROCEDURE [dbo].[USP_dashboarddata_BL_V2_AI]
(    
 @M_consumerid INT,    
 @compid VARCHAR(10) = NULL 
)    
AS    
BEGIN  
    SET NOCOUNT ON;
    DECLARE @TotalCodeCheck INT = 0;
    DECLARE @TotalSuccessCheck INT = 0;
    DECLARE @TotalUnsuccessCheck INT = 0;
    DECLARE @TotalInvalidCheck INT = 0;
    DECLARE @USERTYPE INT = 0;
    DECLARE @FilterDate DATETIME = '1900-08-04 00:00:00.000';
    DECLARE @MobileNo VARCHAR(20);

    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_consumerid AND IsDelete = 0;
    IF @MobileNo IS NULL RETURN;

    IF (@compid = 'Comp-1152')
    BEGIN
        SELECT @USERTYPE = Vrkabel_User_Type FROM M_Consumer WHERE M_Consumerid = @M_consumerid;
        IF (@USERTYPE IN (121)) SET @FilterDate = '2024-02-24 00:00:00.000';
        IF (@USERTYPE IN (141,119)) SET @FilterDate = '2022-08-04 00:00:00.000';

        SELECT @TotalSuccessCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate AND Is_Success = 1;
        SELECT @TotalCodeCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate;
        SET @TotalUnsuccessCheck = @TotalCodeCheck - @TotalSuccessCheck;
        SET @TotalInvalidCheck = 0;
    END
    ELSE
    BEGIN
        -- Create temp table for user scans
        DROP TABLE IF EXISTS #UserScans;
        DROP TABLE IF EXISTS #ConfigPoints;

        SELECT 
            M.Row_ID as M_Codeid,
            M.Pro_ID,
            M.Series_Order,
            M.Series_Serial,
            ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2 ORDER BY PE.Enq_Date) as rn
        INTO #UserScans
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
        WHERE PE.MobileNo = @MobileNo 
          AND PR.Comp_ID = @compid
          AND PE.Is_Success = '1';

        -- Get Config Points and Frequency
        SELECT 
            US.M_Codeid,
            SS.Service_ID,
            MAX(ISNULL(SST.Frequency, 1)) AS Frequency
        INTO #ConfigPoints
        FROM #UserScans US
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        WHERE SS.IsActive = 1 AND SS.IsDelete = 0
          AND SST.IsActive = 1 AND SST.IsDelete = 0
          AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
          AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
          AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
        GROUP BY US.M_Codeid, SS.Service_ID;

        SELECT @TotalSuccessCheck = COUNT(*)
        FROM #UserScans US
        LEFT JOIN (
            SELECT M_Codeid, MAX(Frequency) AS Frequency
            FROM #ConfigPoints
            GROUP BY M_Codeid
        ) CP ON CP.M_Codeid = US.M_Codeid
        WHERE US.rn <= ISNULL(CP.Frequency, 1);

        SELECT @TotalUnsuccessCheck = COUNT(pe.Received_Code1)
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_code M WITH (NOLOCK) ON pe.Received_Code1 = M.Code1 AND pe.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
        WHERE pe.MobileNo = @MobileNo
          AND PR.Comp_ID = @compid
          -- Count ONLY 'Already Scanned' (Is_Success = '2')
          AND pe.Is_Success = '2';

        SELECT @TotalInvalidCheck = COUNT(pe.Received_Code1)
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_code M WITH (NOLOCK) ON pe.Received_Code1 = M.Code1 AND pe.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
        WHERE pe.MobileNo = @MobileNo
          AND PR.Comp_ID = @compid
          AND pe.Is_Success NOT IN ('1', '2');

        SET @TotalCodeCheck = @TotalSuccessCheck + @TotalUnsuccessCheck + @TotalInvalidCheck;

        DROP TABLE IF EXISTS #UserScans;
        DROP TABLE IF EXISTS #ConfigPoints;
    END

    DECLARE @LastCodeCheckDate DATETIME = NULL;
    SELECT TOP 1 @LastCodeCheckDate = Enq_date 
    FROM Pro_enq WITH (NOLOCK) 
    WHERE mobileno = @MobileNo 
    ORDER BY Enq_date DESC;

    -- Result Set 1: Overall Stats (Simplified)
    SELECT @TotalCodeCheck as TotalCode, 
           0 as ReedemPoints, 
           @TotalSuccessCheck as SuccessCode, 
           @TotalUnsuccessCheck as UnsuccessCode,
           @TotalInvalidCheck as InvalidCode,
           0 as TotalCash, 
           0 as TransferredCash,
           @LastCodeCheckDate as LastCodeCheckDate;
END
GO
