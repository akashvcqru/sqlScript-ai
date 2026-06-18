USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetBrandOverview_MAndM_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBrandOverview_MAndM_AI]  
(
   @CompId NVARCHAR(50),  
   @datePreset NVARCHAR(20) = NULL   
)  
AS  
BEGIN  
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(50) = @CompId;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @CompId AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @CompId AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END
 
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PrevStartDate DATE, @PrevEndDate DATE;
    DECLARE @Days INT;
    DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
    
    -- Normalize the filter string
    SET @Win = REPLACE(@Win, ' ', '');
    IF @Win = 'THISMONTH' SET @Win = 'MONTH';
    IF @Win = 'THISWEEK' SET @Win = 'WEEK';
    IF @Win = 'QUARTER(90DAYS)' SET @Win = 'QUARTER';

    IF @Win = 'LASTWEEK'  SET @Days = 14;
    ELSE IF @Win = 'WEEK' OR @Win = 'THISWEEK' SET @Days = 7;
    ELSE IF @Win = 'QUARTER' SET @Days = 90;
    ELSE SET @Days = 30; -- Default to Month/30 days

    -- Fetch Company Registration Date for optimization
    DECLARE @CompRegDate DATE;
    SELECT TOP 1 @CompRegDate = CAST(Reg_Date AS DATE) 
    FROM Comp_Reg WITH (NOLOCK) 
    WHERE Comp_ID = @ActualCompId AND Status = 1;

    IF @CompRegDate IS NULL 
        SET @CompRegDate = '2000-01-01';

    IF @Win = 'WEEK' OR @Win = 'THISWEEK'
    BEGIN
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0); -- Monday
        SET @EndDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @PrevStartDate = DATEADD(WEEK, -1, @StartDate);
        SET @PrevEndDate = @StartDate;
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0); -- Prev Monday
        SET @EndDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0); -- Current Monday
        SET @PrevStartDate = DATEADD(WEEK, -1, @StartDate);
        SET @PrevEndDate = @StartDate;
    END
    ELSE IF @Win = 'MONTH' OR @Win = 'THISMONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate = @StartDate;
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate = @StartDate;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
        SET @EndDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        SET @PrevStartDate = DATEADD(QUARTER, -1, @StartDate);
        SET @PrevEndDate = @StartDate;
    END
    ELSE
    BEGIN
        -- Default to THIS WEEK
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        SET @EndDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @PrevStartDate = DATEADD(WEEK, -1, @StartDate);
        SET @PrevEndDate = @StartDate;
    END;

    ---------------------------------------------------------
    -- SBU Team Temp Tables from UserData_MHCroneJob (DealerCode = 'SBUTEAM')
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#SBUTeamMobile') IS NOT NULL DROP TABLE #SBUTeamMobile;
    SELECT MobileNo, M_ConsumerId, Entry_Date, VRKbl_KYC_status
    INTO #SBUTeamMobile 
    FROM UserData_MHCroneJob WITH (NOLOCK) 
    WHERE DealerCode = 'SBUTEAM' AND Comp_ID = @ActualCompId AND IsDelete = 0;

    CREATE UNIQUE CLUSTERED INDEX IX_SBUTeamMobile_MobileNo ON #SBUTeamMobile(MobileNo);
    CREATE NONCLUSTERED INDEX IX_SBUTeamMobile_ConsumerId ON #SBUTeamMobile(M_ConsumerId);

    ---------------------------------------------------------
    -- Fetch High-Level Cron Data (Old Stored Procedure Logic)
    ---------------------------------------------------------
    DECLARE @Cron_TotalUsers INT = 0;
    DECLARE @Cron_ActiveUsers INT = 0;
    DECLARE @Cron_GenCodes INT = 0;
    DECLARE @Cron_ScannedCodes INT = 0;
    DECLARE @Cron_CashUtilization DECIMAL(18,2) = 0;
    DECLARE @Cron_CashTransfer DECIMAL(18,2) = 0;
    DECLARE @Cron_ApprovedKyc INT = 0;
    DECLARE @Cron_RejectKyc INT = 0;
    DECLARE @Cron_PendingKyc INT = 0;

    SELECT TOP 1
        @Cron_TotalUsers = ISNULL(Total_User, 0),
        @Cron_ActiveUsers = ISNULL(Total_ActiveUser, 0),
        @Cron_GenCodes = ISNULL(Total_GenCode, 0),
        @Cron_ScannedCodes = ISNULL(Total_CodeCheck, 0),
        @Cron_CashUtilization = ISNULL(Total_Cash_Utilization, 0),
        @Cron_CashTransfer = ISNULL(Total_CashTransfer, 0),
        @Cron_ApprovedKyc = ISNULL(Total_Approved_Kyc, 0),
        @Cron_RejectKyc = ISNULL(Total_Reject_Kyc, 0),
        @Cron_PendingKyc = ISNULL(Total_pending_Kyc, 0)
    FROM BrandData_MHCroneJob WITH (NOLOCK)
    WHERE Comp_ID = @ActualCompId
    ORDER BY CreatedDate DESC;

    -- Fetch Previous Cron Data for accurate historical totals
    DECLARE @Cron_TotalUsers_Prev INT = 0;
    DECLARE @Cron_GenCodes_Prev INT = 0;
    DECLARE @Cron_ScannedCodes_Prev INT = 0;
    DECLARE @Cron_CashUtilizationAmt_Prev DECIMAL(18,2) = 0;
    DECLARE @Cron_TotalBurnedCash_Prev DECIMAL(18,2) = 0;

    SELECT TOP 1
        @Cron_TotalUsers_Prev = ISNULL(Total_User, 0),
        @Cron_GenCodes_Prev = ISNULL(Total_GenCode, 0),
        @Cron_ScannedCodes_Prev = ISNULL(Total_CodeCheck, 0),
        @Cron_CashUtilizationAmt_Prev = ISNULL(Total_Cash_Utilization, 0),
        @Cron_TotalBurnedCash_Prev = ISNULL(Total_CashTransfer, 0)
    FROM BrandData_MHCroneJob WITH (NOLOCK)
    WHERE Comp_ID = @ActualCompId AND CreatedDate < @StartDate
    ORDER BY CreatedDate DESC;

    ---------------------------------------------------------
    -- Calculate SBU Specific Numbers
    ---------------------------------------------------------
    DECLARE @SBU_RegUsers_Current INT = 0, @SBU_RegUsers_Prev INT = 0;
    DECLARE @SBU_ActiveUsers_Current INT = 0, @SBU_ActiveUsers_Prev INT = 0;
    DECLARE @SBU_QrVerified_Current INT = 0, @SBU_QrVerified_Prev INT = 0;
    DECLARE @SBU_CashUtilized_Current DECIMAL(18,2) = 0, @SBU_CashUtilized_Prev DECIMAL(18,2) = 0;

    -- SBU Registered
    SELECT 
        @SBU_RegUsers_Current = COUNT(*),
        @SBU_RegUsers_Prev = ISNULL(SUM(CASE WHEN Entry_Date < @StartDate THEN 1 ELSE 0 END), 0)
    FROM #SBUTeamMobile;

    ---------------------------------------------------------
    -- Consolidated Scan for Active Users (Period Bounded)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#ActiveScanData') IS NOT NULL DROP TABLE #ActiveScanData;

    SELECT 
        PE.MobileNo,
        MAX(CASE WHEN PE.Enq_Date >= @StartDate AND PE.Enq_Date < @EndDate THEN 1 ELSE 0 END) AS IsCurrent,
        MAX(CASE WHEN PE.Enq_Date >= @PrevStartDate AND PE.Enq_Date < @PrevEndDate THEN 1 ELSE 0 END) AS IsPrev
    INTO #ActiveScanData
    FROM ConsumerPointsCashDetails PE WITH (NOLOCK)
    WHERE PE.Comp_id = @ActualCompId
      AND (
          (PE.Enq_Date >= @StartDate AND PE.Enq_Date < @EndDate)
          OR (PE.Enq_Date >= @PrevStartDate AND PE.Enq_Date < @PrevEndDate)
      )
    GROUP BY PE.MobileNo;

    CREATE CLUSTERED INDEX IX_ActiveScanData_MobileNo ON #ActiveScanData(MobileNo);

    -- SBU Active
    SELECT @SBU_ActiveUsers_Current = COUNT(DISTINCT MobileNo)
    FROM #ActiveScanData
    WHERE IsCurrent = 1
      AND MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);

    SELECT @SBU_ActiveUsers_Prev = COUNT(DISTINCT MobileNo)
    FROM #ActiveScanData
    WHERE IsPrev = 1
      AND MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);

    -- Non-SBU Active
    DECLARE @NonSBU_ActiveUsers_Current INT = 0, @NonSBU_ActiveUsers_Prev INT = 0;

    SELECT @NonSBU_ActiveUsers_Current = COUNT(DISTINCT MobileNo)
    FROM #ActiveScanData
    WHERE IsCurrent = 1
      AND NOT EXISTS (SELECT 1 FROM #SBUTeamMobile S WHERE S.MobileNo = #ActiveScanData.MobileNo);

    SELECT @NonSBU_ActiveUsers_Prev = COUNT(DISTINCT MobileNo)
    FROM #ActiveScanData
    WHERE IsPrev = 1
      AND NOT EXISTS (SELECT 1 FROM #SBUTeamMobile S WHERE S.MobileNo = #ActiveScanData.MobileNo);

    -- SBU Qr Verified (Scans)
    SELECT 
        @SBU_QrVerified_Current = COUNT(*),
        @SBU_QrVerified_Prev = ISNULL(SUM(CASE WHEN PE.Enq_Date < @StartDate THEN 1 ELSE 0 END), 0)
    FROM ConsumerPointsCashDetails PE WITH (NOLOCK)
    INNER JOIN #SBUTeamMobile S ON S.MobileNo = PE.MobileNo
    WHERE PE.Comp_id = @ActualCompId 
      AND PE.Enq_Date >= @CompRegDate;

    -- SBU Cash Utilized (Payouts)
    SELECT 
        @SBU_CashUtilized_Current = ISNULL(SUM(ISNULL(CAST(ut.Amount AS DECIMAL(18,2)), 0)), 0),
        @SBU_CashUtilized_Prev = ISNULL(SUM(CASE WHEN ut.TransactionDate < @StartDate THEN ISNULL(CAST(ut.Amount AS DECIMAL(18,2)), 0) ELSE 0 END), 0)
    FROM Transactions ut WITH (NOLOCK)
    INNER JOIN #SBUTeamMobile S ON S.M_ConsumerId = ut.M_CounserID
    WHERE ut.CompId = REPLACE(@ActualCompId, 'Comp-', '')
      AND ut.Issuccess = 1;

    ---------------------------------------------------------
    -- Separate SBU and Non-SBU Values
    ---------------------------------------------------------
    DECLARE @RegUsers_Current INT = 0, @RegUsers_Prev INT = 0;
    DECLARE @ActiveUsers_Current INT = 0, @ActiveUsers_Prev INT = 0;
    DECLARE @QrCreated_Current INT = 0, @QrCreated_Prev INT = 0;
    DECLARE @QrVerified_Current INT = 0, @QrVerified_Prev INT = 0;
    DECLARE @CashUtilized_Current DECIMAL(18,2) = 0, @CashUtilized_Prev DECIMAL(18,2) = 0;

    -- Calculate SBU cash proportion based on Total Burned Cash (Cron's Total_CashTransfer)
    DECLARE @Cron_TotalBurnedCash DECIMAL(18,2) = @Cron_CashTransfer;
    DECLARE @Cron_CashUtilizationAmt DECIMAL(18,2) = @Cron_CashUtilization;
    DECLARE @SBU_TotalBurnedCash DECIMAL(18,2) = @SBU_CashUtilized_Current;
    
    DECLARE @SBU_Ratio DECIMAL(18,6) = 0.000000;
    IF @Cron_TotalBurnedCash > 0
        SET @SBU_Ratio = @SBU_TotalBurnedCash / @Cron_TotalBurnedCash;

    DECLARE @SBU_CashBurn DECIMAL(18,2) = @Cron_CashUtilizationAmt * @SBU_Ratio;

    -- Previous calculations
    DECLARE @SBU_TotalBurnedCash_Prev DECIMAL(18,2) = @SBU_CashUtilized_Prev;
    
    DECLARE @SBU_Ratio_Prev DECIMAL(18,6) = 0.000000;
    IF @Cron_TotalBurnedCash_Prev > 0
        SET @SBU_Ratio_Prev = @SBU_TotalBurnedCash_Prev / @Cron_TotalBurnedCash_Prev;

    DECLARE @SBU_CashBurn_Prev DECIMAL(18,2) = @Cron_CashUtilizationAmt_Prev * @SBU_Ratio_Prev;

    IF @IsSBUTeam = 1
    BEGIN
        SET @RegUsers_Current = @SBU_RegUsers_Current;
        SET @RegUsers_Prev = @SBU_RegUsers_Prev;

        SET @ActiveUsers_Current = @SBU_ActiveUsers_Current;
        SET @ActiveUsers_Prev = @SBU_ActiveUsers_Prev;

        SET @QrCreated_Current = @Cron_GenCodes; -- Generated codes are brand-wide
        SET @QrCreated_Prev = @Cron_GenCodes_Prev;

        SET @QrVerified_Current = @SBU_QrVerified_Current;
        SET @QrVerified_Prev = @SBU_QrVerified_Prev;

        SET @CashUtilized_Current = @SBU_CashBurn;
        SET @CashUtilized_Prev = @SBU_CashBurn_Prev;
    END
    ELSE
    BEGIN
        -- Non-SBU: Overall Cron Values minus SBU Specific Values
        SET @RegUsers_Current = @Cron_TotalUsers - @SBU_RegUsers_Current;
        SET @RegUsers_Prev = @Cron_TotalUsers_Prev - @SBU_RegUsers_Prev;

        SET @ActiveUsers_Current = @NonSBU_ActiveUsers_Current;
        SET @ActiveUsers_Prev = @NonSBU_ActiveUsers_Prev;

        SET @QrCreated_Current = @Cron_GenCodes;
        SET @QrCreated_Prev = @Cron_GenCodes_Prev;

        SET @QrVerified_Current = @Cron_ScannedCodes - @SBU_QrVerified_Current;
        SET @QrVerified_Prev = @Cron_ScannedCodes_Prev - @SBU_QrVerified_Prev;

        SET @CashUtilized_Current = @Cron_CashUtilizationAmt - @SBU_CashBurn;
        SET @CashUtilized_Prev = @Cron_CashUtilizationAmt_Prev - @SBU_CashBurn_Prev;
    END

    -- Ensure values do not drop below zero due to sync differences
    IF @RegUsers_Current < 0 SET @RegUsers_Current = 0;
    IF @RegUsers_Prev < 0 SET @RegUsers_Prev = 0;
    IF @ActiveUsers_Current < 0 SET @ActiveUsers_Current = 0;
    IF @ActiveUsers_Prev < 0 SET @ActiveUsers_Prev = 0;
    IF @QrVerified_Current < 0 SET @QrVerified_Current = 0;
    IF @QrVerified_Prev < 0 SET @QrVerified_Prev = 0;
    IF @CashUtilized_Current < 0.00 SET @CashUtilized_Current = 0.00;
    IF @CashUtilized_Prev < 0.00 SET @CashUtilized_Prev = 0.00;

    ---------------------------------------------------------
    -- 6. PERIOD CASH UTILIZATION (CURRENT & PREV) 
    ---------------------------------------------------------
    DECLARE @PeriodCashUtilized_Current DECIMAL(18,2) = 0;
    DECLARE @PeriodCashUtilized_Prev DECIMAL(18,2) = 0;

    IF OBJECT_ID('tempdb..#PeriodScans') IS NOT NULL DROP TABLE #PeriodScans;
    
    SELECT 
        pc.Code1, pc.Code2, pc.Enq_Date, pc.Cash, pc.Points, pc.distributedid, pc.m_consumerid
    INTO #PeriodScans
    FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
    WHERE pc.Comp_Id = @ActualCompId
      AND pc.Enq_Date >= @PrevStartDate
      AND pc.Enq_Date < @EndDate;

    IF OBJECT_ID('tempdb..#DedupScans') IS NOT NULL DROP TABLE #DedupScans;
    
    SELECT Code1, Code2, Enq_Date, Cash, Points, distributedid, m_consumerid
    INTO #DedupScans
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY Code1, Code2, Enq_Date ORDER BY Enq_Date DESC) AS rn
        FROM #PeriodScans
    ) T WHERE rn = 1;

    CREATE NONCLUSTERED INDEX IX_DedupScans_Codes ON #DedupScans(Code1, Code2);

    SELECT @PeriodCashUtilized_Current = ISNULL(SUM(
        CASE 
            WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, ISNULL(ds.Cash, 0))
            ELSE CASE WHEN ds.Points IS NULL OR ds.Points = 0 THEN ISNULL(ds.Cash, 0) ELSE ds.Points END
        END
    ), 0)
    FROM #DedupScans ds
    LEFT JOIN dbo.M_Consumer mc WITH (NOLOCK) ON mc.M_Consumerid = ds.m_consumerid AND mc.IsDelete = 0
    LEFT JOIN dbo.M_Code mcd WITH (NOLOCK) ON mcd.Code1 = ds.Code1 AND mcd.Code2 = ds.Code2
    LEFT JOIN dbo.M_ServiceSubscription ss WITH (NOLOCK) 
        ON ss.Pro_ID = mcd.Pro_ID
       AND (CAST(mcd.Series_Order AS BIGINT) * 10000 + CAST(mcd.Series_Serial AS BIGINT))
           BETWEEN (CAST(ss.start_order AS BIGINT) * 10000 + CAST(ss.start_series AS BIGINT))
           AND (CAST(ss.end_order AS BIGINT) * 10000 + CAST(ss.end_series AS BIGINT))
           AND ss.IsActive = 1 AND ss.IsDelete = 0
    LEFT JOIN dbo.BLoyaltyPointsEarned BL WITH (NOLOCK) ON BL.Code1 = ds.Code1 AND BL.Code2 = ds.Code2 AND BL.compid = @ActualCompId
    WHERE ds.Enq_Date >= ISNULL(@StartDate, '2022-08-04 07:48:02.000') AND ds.Enq_Date < @EndDate
      AND (
          (@IsSBUTeam = 0 AND (ds.distributedid <> 'SBUTEAM' OR ds.distributedid IS NULL) AND (mc.distributorID <> 'SBUTEAM' OR mc.distributorID IS NULL)) OR
          (@IsSBUTeam = 1 AND (ds.distributedid = 'SBUTEAM' OR mc.distributorID = 'SBUTEAM'))
      );

    SELECT @PeriodCashUtilized_Prev = ISNULL(SUM(
        CASE 
            WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, ISNULL(ds.Cash, 0))
            ELSE CASE WHEN ds.Points IS NULL OR ds.Points = 0 THEN ISNULL(ds.Cash, 0) ELSE ds.Points END
        END
    ), 0)
    FROM #DedupScans ds
    LEFT JOIN dbo.M_Consumer mc WITH (NOLOCK) ON mc.M_Consumerid = ds.m_consumerid AND mc.IsDelete = 0
    LEFT JOIN dbo.M_Code mcd WITH (NOLOCK) ON mcd.Code1 = ds.Code1 AND mcd.Code2 = ds.Code2
    LEFT JOIN dbo.M_ServiceSubscription ss WITH (NOLOCK) 
        ON ss.Pro_ID = mcd.Pro_ID
       AND (CAST(mcd.Series_Order AS BIGINT) * 10000 + CAST(mcd.Series_Serial AS BIGINT))
           BETWEEN (CAST(ss.start_order AS BIGINT) * 10000 + CAST(ss.start_series AS BIGINT))
           AND (CAST(ss.end_order AS BIGINT) * 10000 + CAST(ss.end_series AS BIGINT))
           AND ss.IsActive = 1 AND ss.IsDelete = 0
    LEFT JOIN dbo.BLoyaltyPointsEarned BL WITH (NOLOCK) ON BL.Code1 = ds.Code1 AND BL.Code2 = ds.Code2 AND BL.compid = @ActualCompId
    WHERE ds.Enq_Date >= @PrevStartDate AND ds.Enq_Date < ISNULL(@StartDate, '2022-08-04 07:48:02.000')
      AND (
          (@IsSBUTeam = 0 AND (ds.distributedid <> 'SBUTEAM' OR ds.distributedid IS NULL) AND (mc.distributorID <> 'SBUTEAM' OR mc.distributorID IS NULL)) OR
          (@IsSBUTeam = 1 AND (ds.distributedid = 'SBUTEAM' OR mc.distributorID = 'SBUTEAM'))
      );

    ---------------------------------------------------------
    -- Final Burned Cash Determination
    ---------------------------------------------------------
    DECLARE @Final_BurnedCash DECIMAL(18,2) = 0.00;
    IF @IsSBUTeam = 1
        SET @Final_BurnedCash = @SBU_TotalBurnedCash;
    ELSE
        SET @Final_BurnedCash = @Cron_TotalBurnedCash - @SBU_TotalBurnedCash;

    ---------------------------------------------------------
    -- RESULT SET 1: KPI SUMMARY
    ---------------------------------------------------------
    SELECT
        @RegUsers_Current AS RegisteredUsers_Current,
        @RegUsers_Prev AS RegisteredUsers_Previous,
        CASE WHEN @RegUsers_Prev > 0 THEN ((CAST(@RegUsers_Current AS DECIMAL(18,2)) - @RegUsers_Prev) / @RegUsers_Prev) * 100 ELSE 0 END AS RegisteredUsers_Change,

        @ActiveUsers_Current AS ActiveUsers_Current,
        @ActiveUsers_Prev AS ActiveUsers_Previous,
        CASE WHEN @ActiveUsers_Prev > 0 THEN ((CAST(@ActiveUsers_Current AS DECIMAL(18,2)) - @ActiveUsers_Prev) / @ActiveUsers_Prev) * 100 ELSE 0 END AS ActiveUsers_Change,

        @QrCreated_Current AS QrCodesCreated_Current,
        @QrCreated_Prev AS QrCodesCreated_Previous,
        CASE WHEN @QrCreated_Prev > 0 THEN ((CAST(@QrCreated_Current AS DECIMAL(18,2)) - @QrCreated_Prev) / @QrCreated_Prev) * 100 ELSE 0 END AS QrCodesCreated_Change,

        @QrVerified_Current AS QrCodesVerified_Current,
        @QrVerified_Prev AS QrCodesVerified_Previous,
        CASE WHEN @QrVerified_Prev > 0 THEN ((CAST(@QrVerified_Current AS DECIMAL(18,2)) - @QrVerified_Prev) / @QrVerified_Prev) * 100 ELSE 0 END AS QrCodesVerified_Change,

        ISNULL(@PeriodCashUtilized_Current, 0) AS CashUtilization_Current,
        ISNULL(@PeriodCashUtilized_Prev, 0) AS CashUtilization_Previous,
        CASE WHEN @PeriodCashUtilized_Prev > 0 THEN ((ISNULL(@PeriodCashUtilized_Current, 0) - @PeriodCashUtilized_Prev) / @PeriodCashUtilized_Prev) * 100 ELSE 0 END AS CashUtilization_Change,

        ISNULL(@CashUtilized_Current, 0) AS TotalCashUtilized_Current,
        ISNULL(@CashUtilized_Prev, 0) AS TotalCashUtilized_Previous,
        CASE WHEN @CashUtilized_Prev > 0 THEN ((@CashUtilized_Current - @CashUtilized_Prev) / @CashUtilized_Prev) * 100 ELSE 0 END AS TotalCashUtilized_Change,

        -- Backward Compatibility Fields
        ISNULL(@CashUtilized_Current, 0) AS TotalCash_Current,
        ISNULL(@CashUtilized_Prev, 0) AS TotalCash_Previous,
        ISNULL(@CashUtilized_Current, 0) AS CashBurn_Current,
        ISNULL(@CashUtilized_Prev, 0) AS CashBurn_Previous,
        @RegUsers_Current AS TotalUsers,
        @QrCreated_Current AS Total_GeneratedCodes,
        @QrVerified_Current AS Total_ScannedCodes,
        @Final_BurnedCash AS Total_BurnedCash;

    ---------------------------------------------------------
    -- RESULT SET 2: KYC BREAKDOWN
    ---------------------------------------------------------
    DECLARE @SBU_ActiveKYC INT = 0;
    DECLARE @SBU_RejectedKYC INT = 0;
    DECLARE @SBU_PendingKYC INT = 0;

    SELECT 
        @SBU_ActiveKYC = ISNULL(SUM(CASE WHEN VRKbl_KYC_status = 1 THEN 1 ELSE 0 END), 0),
        @SBU_RejectedKYC = ISNULL(SUM(CASE WHEN VRKbl_KYC_status = 2 THEN 1 ELSE 0 END), 0),
        @SBU_PendingKYC = ISNULL(SUM(CASE WHEN VRKbl_KYC_status NOT IN (1, 2) OR VRKbl_KYC_status IS NULL THEN 1 ELSE 0 END), 0)
    FROM #SBUTeamMobile;

    IF @IsSBUTeam = 1
    BEGIN
        SELECT 'ActiveKYC' AS KYCStatus, @SBU_ActiveKYC AS CurrentCount
        UNION ALL
        SELECT 'RejectedKYC', @SBU_RejectedKYC
        UNION ALL
        SELECT 'PendingKYC', @SBU_PendingKYC;
    END
    ELSE
    BEGIN
        SELECT 'ActiveKYC' AS KYCStatus, (@Cron_ApprovedKyc - @SBU_ActiveKYC) AS CurrentCount
        UNION ALL
        SELECT 'RejectedKYC', (@Cron_RejectKyc - @SBU_RejectedKYC)
        UNION ALL
        SELECT 'PendingKYC', (@Cron_PendingKyc - @SBU_PendingKYC);
    END

END;
GO
