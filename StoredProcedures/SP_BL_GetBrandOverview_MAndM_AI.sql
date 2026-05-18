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
    SELECT MobileNo 
    INTO #SBUTeamMobile 
    FROM UserData_MHCroneJob WITH (NOLOCK) 
    WHERE DealerCode = 'SBUTEAM' AND Comp_ID = 'Comp-1152' AND IsDelete = 0;

    CREATE UNIQUE CLUSTERED INDEX IX_SBUTeamMobile_MobileNo ON #SBUTeamMobile(MobileNo);

    IF OBJECT_ID('tempdb..#SBUTeamConsumerIds') IS NOT NULL DROP TABLE #SBUTeamConsumerIds;
    SELECT M_ConsumerId
    INTO #SBUTeamConsumerIds
    FROM UserData_MHCroneJob WITH (NOLOCK) 
    WHERE DealerCode = 'SBUTEAM' AND Comp_ID = 'Comp-1152' AND IsDelete = 0;

    CREATE UNIQUE CLUSTERED INDEX IX_SBUTeamConsumerIds_Id ON #SBUTeamConsumerIds(M_ConsumerId);

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
    WHERE Comp_ID = 'Comp-1152'
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
        @SBU_RegUsers_Prev = SUM(CASE WHEN Entry_Date < @StartDate THEN 1 ELSE 0 END)
    FROM UserData_MHCroneJob WITH (NOLOCK)
    WHERE DealerCode = 'SBUTEAM' AND Comp_ID = 'Comp-1152' AND IsDelete = 0;

    -- SBU Active
    SELECT @SBU_ActiveUsers_Current = COUNT(DISTINCT PE.MobileNo) 
    FROM Pro_Enq PE WITH (NOLOCK)
    WHERE PE.Comp_ID = 'Comp-1152' 
      AND PE.Enq_Date >= @StartDate AND PE.Enq_Date < @EndDate
      AND PE.MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);

    SELECT @SBU_ActiveUsers_Prev = COUNT(DISTINCT PE.MobileNo) 
    FROM Pro_Enq PE WITH (NOLOCK)
    WHERE PE.Comp_ID = 'Comp-1152' 
      AND PE.Enq_Date >= @PrevStartDate AND PE.Enq_Date < @PrevEndDate
      AND PE.MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);

    -- SBU Qr Verified (Scans)
    SELECT 
        @SBU_QrVerified_Current = COUNT(*),
        @SBU_QrVerified_Prev = SUM(CASE WHEN PE.Enq_Date < @StartDate THEN 1 ELSE 0 END)
    FROM Pro_Enq PE WITH (NOLOCK)
    WHERE PE.Comp_ID = 'Comp-1152' 
      AND PE.Enq_Date >= @CompRegDate
      AND PE.MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);

    -- SBU Cash Utilized (Payouts)
    SELECT 
        @SBU_CashUtilized_Current = SUM(ISNULL(CAST(ut.Amount AS DECIMAL(18,2)), 0)),
        @SBU_CashUtilized_Prev = SUM(CASE WHEN ut.TransactionDate < @StartDate THEN ISNULL(CAST(ut.Amount AS DECIMAL(18,2)), 0) ELSE 0 END)
    FROM Transactions ut WITH (NOLOCK)
    WHERE ut.CompId = '1152'
      AND ut.Issuccess = 1
      AND ut.M_CounserID IN (SELECT M_Consumerid FROM #SBUTeamConsumerIds);

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

    IF @IsSBUTeam = 1
    BEGIN
        SET @RegUsers_Current = @SBU_RegUsers_Current;
        SET @RegUsers_Prev = @SBU_RegUsers_Prev;

        SET @ActiveUsers_Current = @SBU_ActiveUsers_Current;
        SET @ActiveUsers_Prev = @SBU_ActiveUsers_Prev;

        SET @QrCreated_Current = @Cron_GenCodes; -- Generated codes are brand-wide
        SET @QrCreated_Prev = @Cron_GenCodes;

        SET @QrVerified_Current = @SBU_QrVerified_Current;
        SET @QrVerified_Prev = @SBU_QrVerified_Prev;

        SET @CashUtilized_Current = @SBU_CashBurn;
        SET @CashUtilized_Prev = @SBU_CashBurn;
    END
    ELSE
    BEGIN
        -- Non-SBU: Overall Cron Values minus SBU Specific Values
        SET @RegUsers_Current = @Cron_TotalUsers - @SBU_RegUsers_Current;
        SET @RegUsers_Prev = @Cron_TotalUsers - @SBU_RegUsers_Prev;

        SET @ActiveUsers_Current = @Cron_ActiveUsers - @SBU_ActiveUsers_Current;
        SET @ActiveUsers_Prev = @Cron_ActiveUsers - @SBU_ActiveUsers_Prev;

        SET @QrCreated_Current = @Cron_GenCodes;
        SET @QrCreated_Prev = @Cron_GenCodes;

        SET @QrVerified_Current = @Cron_ScannedCodes - @SBU_QrVerified_Current;
        SET @QrVerified_Prev = @Cron_ScannedCodes - @SBU_QrVerified_Prev;

        SET @CashUtilized_Current = @Cron_CashUtilizationAmt - @SBU_CashBurn;
        SET @CashUtilized_Prev = @Cron_CashUtilizationAmt - @SBU_CashBurn;
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
    -- 6. CASH UTILIZATION %
    ---------------------------------------------------------
    DECLARE @CurrentWalletBal DECIMAL(18,2) = 0;
    SELECT TOP 1 @CurrentWalletBal = ISNULL(NewBal, Amount) 
    FROM tblCashWalletBalance WITH (NOLOCK)
    WHERE Comp_Id = @ActualCompId ORDER BY Id DESC;

    DECLARE @Util_Current DECIMAL(18,2) = 0;
    DECLARE @Util_Prev DECIMAL(18,2) = 0;
    
    IF (@CashUtilized_Current + @CurrentWalletBal) > 0
        SET @Util_Current = (@CashUtilized_Current / (@CashUtilized_Current + @CurrentWalletBal)) * 100;

    IF (@CashUtilized_Prev + @CurrentWalletBal) > 0
        SET @Util_Prev = (@CashUtilized_Prev / (@CashUtilized_Prev + @CurrentWalletBal)) * 100;

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

        @Util_Current AS CashUtilization_Current,
        @Util_Prev AS CashUtilization_Previous,
        (@Util_Current - @Util_Prev) AS CashUtilization_Change,

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
        @SBU_ActiveKYC = SUM(CASE WHEN VRKbl_KYC_status = 1 THEN 1 ELSE 0 END),
        @SBU_RejectedKYC = SUM(CASE WHEN VRKbl_KYC_status = 2 THEN 1 ELSE 0 END),
        @SBU_PendingKYC = SUM(CASE WHEN VRKbl_KYC_status NOT IN (1, 2) OR VRKbl_KYC_status IS NULL THEN 1 ELSE 0 END)
    FROM UserData_MHCroneJob WITH (NOLOCK)
    WHERE DealerCode = 'SBUTEAM' AND Comp_ID = 'Comp-1152' AND IsDelete = 0;

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
