USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:      Antigravity
-- Create date: 2026-07-29
-- Description: Iterates through all users in tbl_Vendorvisekycstatus for a given CompID,
--              internally calculates overall stats of USP_GetDashboardSummary_AI 
--              for each user without calling the SP, returning combined data.
-- ==========================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDashboardSummaryAllUsers_AI]
(
    @CompID VARCHAR(50)
)
WITH RECOMPILE
AS
BEGIN
    SET NOCOUNT ON;

    -- Flag for service-wise gifts presence (Calculated ONCE)
    DECLARE @HasServiceWiseGifts INT = 0;
    IF EXISTS (SELECT 1 FROM Claim_gift WHERE CompID = @CompID AND Service_id IS NOT NULL AND Isdelete = 0)
    BEGIN
        SET @HasServiceWiseGifts = 1;
    END

    -- Multiplier for loyalty calculation (Calculated ONCE)
    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (calculation_value / 100.0) 
    FROM loyalty_calculation 
    WHERE comp_id = @CompID AND isactive = 1 AND isdelete = 0;

    -- Table to accumulate overall stats for all users
    CREATE TABLE #TempUserStats
    (
        M_consumerId INT,
        MobileNo VARCHAR(100),
        Name VARCHAR(500),
        TotalCode INT,
        ReedemPoints DECIMAL(18,2),
        SuccessCode INT,
        TotalCash DECIMAL(18,2),
        TotalPoints DECIMAL(18,2),
        HasServiceWiseGifts INT
    );

    -- Helper temp tables (created once, truncated inside the cursor loop)
    CREATE TABLE #UserScans
    (
        M_Codeid INT,
        Pro_ID VARCHAR(50),
        Series_Order INT,
        Series_Serial INT,
        rn INT
    );

    CREATE TABLE #EarnedPoints
    (
        M_Codeid INT,
        Service_ID VARCHAR(50),
        Points DECIMAL(18,2)
    );

    CREATE TABLE #ConfigPoints
    (
        M_Codeid INT,
        Service_ID VARCHAR(50),
        ConfigPoints DECIMAL(18,2),
        ConfigCash DECIMAL(18,2)
    );

    CREATE TABLE #ReferralStats
    (
        RefPoints DECIMAL(18,2),
        RefCash DECIMAL(18,2)
    );

    -- Cursor to iterate through users
    DECLARE @M_consumerId INT;
    DECLARE @MobileNo VARCHAR(100);
    DECLARE @Name VARCHAR(500);

    -- Join with M_Consumer to get actual MobileNo and ConsumerName
    DECLARE UserCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT 
        v.M_consumerId,
        m.MobileNo,
        m.ConsumerName AS Name
    FROM dbo.tbl_Vendorvisekycstatus v WITH (NOLOCK)
    INNER JOIN dbo.M_Consumer m WITH (NOLOCK) ON v.M_consumerId = m.M_Consumerid
    WHERE v.Comp_id = @CompID 
      AND v.IsDelete = 0
      AND m.IsDelete = 0;

    OPEN UserCursor;

    FETCH NEXT FROM UserCursor INTO @M_consumerId, @MobileNo, @Name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Clear helpers
        DELETE FROM #UserScans;
        DELETE FROM #EarnedPoints;
        DELETE FROM #ConfigPoints;
        DELETE FROM #ReferralStats;

        BEGIN TRY
            -- 1. Get user scans
            INSERT INTO #UserScans
            SELECT 
                M.Row_ID as M_Codeid,
                M.Pro_ID,
                M.Series_Order,
                M.Series_Serial,
                ROW_NUMBER() OVER (PARTITION BY PE.Received_Code1, PE.Received_Code2 ORDER BY PE.Enq_Date) as rn
            FROM Pro_Enq PE WITH (NOLOCK)
            INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
            INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
            WHERE PR.Comp_Id = @CompID
              AND PE.MobileNo = @MobileNo 
              AND PE.Is_Success = '1';

            -- 2. Get Earned Points
            INSERT INTO #EarnedPoints
            SELECT
                M_Codeid,
                ISNULL(Service_ID, 'SRV1001') AS Service_ID,
                SUM(Points) AS Points
            FROM (
                SELECT
                    MC.M_Codeid,
                    ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
                    CAST(
                        CASE 
                            WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                            ELSE ISNULL(BL.Points, 0)
                        END 
                    AS DECIMAL(18,2)) AS Points
                FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
                INNER JOIN (
                    SELECT BMC2.Pkid, BMC2.M_Consumer_MCOdeid, ROW_NUMBER() OVER (PARTITION BY BMC2.M_Consumer_MCOdeid ORDER BY BMC2.Createdate ASC) as rn
                    FROM BuiltLoyaltyMCodeCheck BMC2 WITH (NOLOCK)
                    INNER JOIN M_Consumer_M_Code MC2 WITH (NOLOCK) ON BMC2.M_Consumer_MCOdeid = MC2.M_Consumer_MCodeid
                    WHERE MC2.M_Consumerid = @M_consumerId
                ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
                INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
                LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON BL.SST_id = SST.SST_Id
                LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
                WHERE BL.compid = @CompID
                  AND MC.M_Consumerid = @M_consumerId

                UNION ALL

                SELECT
                    MC.M_Codeid,
                    ISNULL(SS.Service_ID, 'SRV1001') AS Service_ID,
                    CAST(
                        CASE 
                            WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                            ELSE ISNULL(BL.Points, 0)
                        END 
                    AS DECIMAL(18,2)) AS Points
                FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
                INNER JOIN (
                    SELECT BMC2.Pkid, BMC2.M_Consumer_MCOdeid, ROW_NUMBER() OVER (PARTITION BY BMC2.M_Consumer_MCOdeid ORDER BY BMC2.Createdate ASC) as rn
                    FROM BuiltLoyaltyMCodeCheck BMC2 WITH (NOLOCK)
                    INNER JOIN M_Consumer_M_Code MC2 WITH (NOLOCK) ON BMC2.M_Consumer_MCOdeid = MC2.M_Consumer_MCodeid
                    WHERE MC2.M_Consumerid = @M_consumerId
                ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
                INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
                INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
                INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
                LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON BL.SST_id = SST.SST_Id
                LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
                WHERE BL.compid IS NULL
                  AND PR.Comp_ID = @CompID
                  AND MC.M_Consumerid = @M_consumerId
            ) x
            GROUP BY M_Codeid, ISNULL(Service_ID, 'SRV1001');

            -- 3. Get Config Points
            INSERT INTO #ConfigPoints
            SELECT 
                US.M_Codeid,
                SS.Service_ID,
                MAX(CAST(
                    CASE 
                        WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                        ELSE ISNULL(SST.IsCash, 0) * @Multiplier
                    END 
                AS DECIMAL(18,2))) AS ConfigPoints,
                MAX(CAST(ISNULL(SST.IsCash, 0) AS DECIMAL(18,2))) AS ConfigCash
            FROM #UserScans US
            INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID
            INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
            WHERE US.rn = 1
              AND SS.Comp_Id = @CompID
              AND SS.IsActive = 1 AND SS.IsDelete = 0
              AND SST.IsActive = 1 AND SST.IsDelete = 0
              AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
              AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
              AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
            GROUP BY US.M_Codeid, SS.Service_ID;

            -- 4. Calculate total config points and cash
            DECLARE @TotalConfigPoints DECIMAL(18,2) = 0;
            DECLARE @TotalConfigCash DECIMAL(18,2) = 0;

            SELECT 
                @TotalConfigPoints = ISNULL(SUM(ISNULL(EP.Points, ISNULL(CP.ConfigPoints, 0))), 0),
                @TotalConfigCash = ISNULL(SUM(ISNULL(CP.ConfigCash, 0)), 0)
            FROM #UserScans US
            LEFT JOIN (
                SELECT M_Codeid, MAX(ConfigPoints) AS ConfigPoints, MAX(ConfigCash) AS ConfigCash
                FROM #ConfigPoints
                GROUP BY M_Codeid
            ) CP ON CP.M_Codeid = US.M_Codeid
            LEFT JOIN (
                SELECT M_Codeid, MAX(Points) AS Points
                FROM #EarnedPoints
                GROUP BY M_Codeid
            ) EP ON EP.M_Codeid = US.M_Codeid
            WHERE US.rn = 1;

            -- 5. Get referral stats
            INSERT INTO #ReferralStats
            SELECT 
                ISNULL(SUM(CAST(Points AS DECIMAL(18,2))), 0) as RefPoints,
                ISNULL(SUM(CAST(Cash AS DECIMAL(18,2))), 0) as RefCash
            FROM BLoyaltyPointsEarned BL
            WHERE BL.M_Consumerid = @M_consumerId 
              AND BL.compid = @CompID
              AND BL.ServiceName IN ('Referral', 'KYCRewards', 'Supervisor', 'InvoiceBenifit', 'InvoiceRewards');

            DECLARE @RefPoints DECIMAL(18,2) = 0;
            DECLARE @RefCash DECIMAL(18,2) = 0;
            SELECT @RefPoints = RefPoints, @RefCash = RefCash FROM #ReferralStats;

            -- 6. Calculate specific redeem totals for this consumer
            DECLARE @BPointsAmount DECIMAL(18,2) = 0;
            SELECT @BPointsAmount = ISNULL(SUM(ISNULL(RedeemPoints, 0)), 0)
            FROM BPointsTransaction WITH (NOLOCK)
            WHERE bpstatus IN ('Accepted', 'SUCCESS')
              AND RedeemBy = @M_consumerId
              AND companyid = @CompID;

            DECLARE @TransactionsAmount DECIMAL(18,2) = 0;
            SELECT @TransactionsAmount = ISNULL(SUM(ISNULL(CAST(Amount AS DECIMAL(18,2)), 0)), 0)
            FROM Transactions WITH (NOLOCK)
            WHERE CompId = REPLACE(@CompID, 'Comp-', '')
              AND IsSuccess = 1
              AND M_CounserID = CAST(@M_consumerId AS VARCHAR(50)) 
              AND (
                @CompID <> 'Comp-1152'
                OR TransactionDate > '2022-11-25'
              );

            DECLARE @UPIAmount DECIMAL(18,2) = 0;
            SELECT @UPIAmount = ISNULL(SUM(ISNULL(Amount, 0)), 0)
            FROM tblUPITransactionDetails WITH (NOLOCK)
            WHERE Comp_Id = @CompID
              AND Status = 'Success'
              AND LEN(Code1) > 3
              AND M_Consumerid = CAST(@M_consumerId AS VARCHAR(50));

            DECLARE @ClaimsAmount DECIMAL(18,2) = 0;
            SELECT @ClaimsAmount = ISNULL(SUM(CASE WHEN ISNULL(Amount, 0) > 0 THEN Amount ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue), 0) END), 0)
            FROM ClaimDetails CD WITH (NOLOCK)
            WHERE Isapproved IN (0, 1)
              AND CD.Mobileno = @MobileNo
              AND CD.Comp_id = @CompID;

            DECLARE @RedeemAmount DECIMAL(18,2) = 0;
            SET @RedeemAmount = @BPointsAmount + @TransactionsAmount + @UPIAmount + @ClaimsAmount;

            DECLARE @TotalCode INT = 0;
            SELECT @TotalCode = COUNT(pe.Received_Code1) FROM Pro_Enq pe WHERE pe.MobileNo = @MobileNo;

            DECLARE @SuccessCode INT = 0;
            SELECT @SuccessCode = COUNT(pe.Received_Code1) FROM Pro_Enq pe WHERE pe.MobileNo = @MobileNo AND pe.Is_Success = 1;

            DECLARE @TotalCash DECIMAL(18,2) = 0;
            DECLARE @TotalPoints DECIMAL(18,2) = 0;

            IF @CompID = 'Comp-1274'
            BEGIN
                SELECT @TotalCash = ISNULL(SUM(cash), 0) FROM BLoyaltyPointsEarned WHERE M_Consumerid = @M_consumerId AND compid LIKE '%' + @CompID + '%';
                SET @TotalPoints = @TotalConfigPoints + @RefPoints;
            END
            ELSE IF @CompID IN ('comp-1152', 'Comp-1152')
            BEGIN
                SELECT @TotalCash = ISNULL(SUM(TRY_CAST(cash AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = @MobileNo and Enq_Date >='2022-08-04 00:00:00.000' and Is_Success=1;
                SELECT @TotalPoints = ISNULL(SUM(TRY_CAST(points AS DECIMAL(18,2))), 0) FROM [dbo].[ConsumerPointsCashDetails] WHERE MobileNo = @MobileNo and Enq_Date >='2022-08-04 00:00:00.000' and Is_Success=1;
            END
            ELSE
            BEGIN
                SET @TotalCash = @TotalConfigCash + @RefCash;
                SET @TotalPoints = @TotalConfigPoints + @RefPoints;
            END

            -- Combine current user info with captured stats
            INSERT INTO #TempUserStats (M_consumerId, MobileNo, Name, TotalCode, ReedemPoints, SuccessCode, TotalCash, TotalPoints, HasServiceWiseGifts)
            VALUES (@M_consumerId, @MobileNo, @Name, @TotalCode, @RedeemAmount, @SuccessCode, @TotalCash, @TotalPoints, @HasServiceWiseGifts);
            
        END TRY
        BEGIN CATCH
            DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
            PRINT 'Error processing M_consumerId: ' + CAST(@M_consumerId AS VARCHAR(20)) + ' - ' + @ErrorMsg;
        END CATCH

        FETCH NEXT FROM UserCursor INTO @M_consumerId, @MobileNo, @Name;
    END

    CLOSE UserCursor;
    DEALLOCATE UserCursor;

    -- Return final aggregated data
    SELECT 
        M_consumerId,
        MobileNo,
        Name,
        ISNULL(TotalCode, 0) AS TotalCode,
        ISNULL(ReedemPoints, 0.00) AS ReedemPoints,
        ISNULL(SuccessCode, 0) AS SuccessCode,
        ISNULL(TotalCash, 0.00) AS TotalCash,
        ISNULL(TotalPoints, 0.00) AS TotalPoints,
        ISNULL(TotalPoints, 0.00) - ISNULL(ReedemPoints, 0.00) AS NetAvailablePoints,
        ISNULL(HasServiceWiseGifts, 0) AS HasServiceWiseGifts
    FROM #TempUserStats
    ORDER BY TotalPoints DESC;

    -- Clean up temp tables
    DROP TABLE IF EXISTS #TempUserStats;
    DROP TABLE IF EXISTS #UserScans;
    DROP TABLE IF EXISTS #EarnedPoints;
    DROP TABLE IF EXISTS #ConfigPoints;
    DROP TABLE IF EXISTS #ReferralStats;
END
GO
