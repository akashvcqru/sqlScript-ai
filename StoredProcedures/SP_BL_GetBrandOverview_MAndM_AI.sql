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
    -- SBU Team Temp Tables for Performance Optimization
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#SBUTeamMobile') IS NOT NULL DROP TABLE #SBUTeamMobile;
    SELECT MobileNo 
    INTO #SBUTeamMobile 
    FROM M_Consumer WITH (NOLOCK) 
    WHERE distributorID = 'SBUTEAM' AND IsDelete = 0;

    CREATE UNIQUE CLUSTERED INDEX IX_SBUTeamMobile_MobileNo ON #SBUTeamMobile(MobileNo);

    IF OBJECT_ID('tempdb..#SBUTeamConsumerIds') IS NOT NULL DROP TABLE #SBUTeamConsumerIds;
    SELECT CAST(M_Consumerid AS VARCHAR(50)) AS M_Consumerid
    INTO #SBUTeamConsumerIds
    FROM M_Consumer WITH (NOLOCK) 
    WHERE distributorID = 'SBUTEAM' AND IsDelete = 0;

    CREATE UNIQUE CLUSTERED INDEX IX_SBUTeamConsumerIds_Id ON #SBUTeamConsumerIds(M_Consumerid);

    ---------------------------------------------------------
    -- 1. REGISTERED USERS (Total)
    ---------------------------------------------------------
    DECLARE @RegUsers_Current INT, @RegUsers_Prev INT;
    
    SELECT 
        @RegUsers_Current = COUNT(*),
        @RegUsers_Prev = SUM(CASE WHEN MC.Entry_Date < @StartDate THEN 1 ELSE 0 END)
    FROM M_Consumer AS MC WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) ON VC.M_consumerId = MC.M_Consumerid
    WHERE VC.Comp_ID = @ActualCompId 
      AND MC.IsDelete = 0 
      AND MC.Entry_Date >= @CompRegDate
      AND (
            (@IsSBUTeam = 0 AND (MC.distributorID <> 'SBUTEAM' OR MC.distributorID IS NULL)) OR
            (@IsSBUTeam = 1 AND MC.distributorID = 'SBUTEAM')
          );

    ---------------------------------------------------------
    -- 2. ACTIVE USERS (Users with activity in period)
    ---------------------------------------------------------
    DECLARE @ActiveUsers_Current INT, @ActiveUsers_Prev INT;

    IF @IsSBUTeam = 1
    BEGIN
        SELECT @ActiveUsers_Current = COUNT(DISTINCT PE.MobileNo) 
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_ID = @ActualCompId 
          AND PE.Enq_Date >= @StartDate AND PE.Enq_Date < @EndDate
          AND PE.MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);

        SELECT @ActiveUsers_Prev = COUNT(DISTINCT PE.MobileNo) 
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_ID = @ActualCompId 
          AND PE.Enq_Date >= @PrevStartDate AND PE.Enq_Date < @PrevEndDate
          AND PE.MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);
    END
    ELSE
    BEGIN
        SELECT @ActiveUsers_Current = COUNT(DISTINCT PE.MobileNo) 
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_ID = @ActualCompId 
          AND PE.Enq_Date >= @StartDate AND PE.Enq_Date < @EndDate
          AND PE.MobileNo NOT IN (SELECT MobileNo FROM #SBUTeamMobile);

        SELECT @ActiveUsers_Prev = COUNT(DISTINCT PE.MobileNo) 
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_ID = @ActualCompId 
          AND PE.Enq_Date >= @PrevStartDate AND PE.Enq_Date < @PrevEndDate
          AND PE.MobileNo NOT IN (SELECT MobileNo FROM #SBUTeamMobile);
    END

    ---------------------------------------------------------
    -- 3. QR CODES CREATED (Total)
    ---------------------------------------------------------
    DECLARE @QrCreated_Current INT, @QrCreated_Prev INT;

    SELECT 
        @QrCreated_Current = COUNT(*),
        @QrCreated_Prev = SUM(CASE WHEN Allot_Date < @StartDate THEN 1 ELSE 0 END)
    FROM M_Code WITH (NOLOCK)
    WHERE Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WHERE Comp_ID = @ActualCompId) 
      AND Allot_Date >= @CompRegDate;

    ---------------------------------------------------------
    -- 4. QR CODES VERIFIED (Total)
    ---------------------------------------------------------
    DECLARE @QrVerified_Current INT, @QrVerified_Prev INT;

    IF @IsSBUTeam = 1
    BEGIN
        SELECT 
            @QrVerified_Current = COUNT(*),
            @QrVerified_Prev = SUM(CASE WHEN PE.Enq_Date < @StartDate THEN 1 ELSE 0 END)
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_ID = @ActualCompId 
          AND PE.Enq_Date >= @CompRegDate
          AND PE.MobileNo IN (SELECT MobileNo FROM #SBUTeamMobile);
    END
    ELSE
    BEGIN
        SELECT 
            @QrVerified_Current = COUNT(*),
            @QrVerified_Prev = SUM(CASE WHEN PE.Enq_Date < @StartDate THEN 1 ELSE 0 END)
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_ID = @ActualCompId 
          AND PE.Enq_Date >= @CompRegDate
          AND PE.MobileNo NOT IN (SELECT MobileNo FROM #SBUTeamMobile);
    END

    ---------------------------------------------------------
    -- 5. TOTAL CASH UTILIZED (Total Payouts)
    ---------------------------------------------------------
    DECLARE @CashUtilized_Current DECIMAL(18,2), @CashUtilized_Prev DECIMAL(18,2);

    IF @IsSBUTeam = 1
    BEGIN
        SELECT 
            @CashUtilized_Current = SUM(ISNULL(ut.Amount, 0)),
            @CashUtilized_Prev = SUM(CASE WHEN ut.ReqDate < @StartDate THEN ISNULL(ut.Amount, 0) ELSE 0 END)
        FROM tblUPITransactionDetails ut WITH (NOLOCK)
        WHERE ut.Comp_Id = @ActualCompId 
          AND ut.Status = 'Success'
          AND ut.M_Consumerid IN (SELECT M_Consumerid FROM #SBUTeamConsumerIds);
    END
    ELSE
    BEGIN
        SELECT 
            @CashUtilized_Current = SUM(ISNULL(ut.Amount, 0)),
            @CashUtilized_Prev = SUM(CASE WHEN ut.ReqDate < @StartDate THEN ISNULL(ut.Amount, 0) ELSE 0 END)
        FROM tblUPITransactionDetails ut WITH (NOLOCK)
        WHERE ut.Comp_Id = @ActualCompId 
          AND ut.Status = 'Success'
          AND ut.M_Consumerid NOT IN (SELECT M_Consumerid FROM #SBUTeamConsumerIds);
    END

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

    -- For simplicity, we use the same wallet balance logic for previous or adjust if history available
    IF (@CashUtilized_Prev + @CurrentWalletBal) > 0
        SET @Util_Prev = (@CashUtilized_Prev / (@CashUtilized_Prev + @CurrentWalletBal)) * 100;

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
        ISNULL(@CashUtilized_Current, 0) AS Total_BurnedCash;

    ---------------------------------------------------------
    -- RESULT SET 2: KYC STATUS
    ---------------------------------------------------------
    SELECT 
        CASE 
            WHEN VC.VRKbl_KYC_status = 1 THEN 'ActiveKYC'
            WHEN VC.VRKbl_KYC_status = 2 THEN 'RejectedKYC'
            ELSE 'PendingKYC'
        END AS KYCStatus,
        COUNT(*) AS CurrentCount
    FROM M_Consumer AS MC WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) ON VC.M_consumerId = MC.M_Consumerid
    WHERE VC.Comp_ID = @ActualCompId 
      AND MC.IsDelete = 0
      AND (
            (@IsSBUTeam = 0 AND (MC.distributorID <> 'SBUTEAM' OR MC.distributorID IS NULL)) OR
            (@IsSBUTeam = 1 AND MC.distributorID = 'SBUTEAM')
          )
    GROUP BY 
        CASE 
            WHEN VC.VRKbl_KYC_status = 1 THEN 'ActiveKYC'
            WHEN VC.VRKbl_KYC_status = 2 THEN 'RejectedKYC'
            ELSE 'PendingKYC'
        END;

END;
GO
