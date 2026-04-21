USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBrandOverview_AI]  
(
   @CompId NVARCHAR(50),  
   @TimeWindow NVARCHAR(20) = NULL   
)  
AS  
BEGIN  
    SET NOCOUNT ON;
 
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @PrevStartDate DATE, @PrevEndDate DATE;
    DECLARE @Days INT;

    IF UPPER(@TimeWindow) = 'TODAY'          SET @Days = 1;
    ELSE IF UPPER(@TimeWindow) = 'YESTERDAY' SET @Days = 1;
    ELSE IF UPPER(@TimeWindow) = 'LASTWEEK'  SET @Days = 14;
    ELSE IF UPPER(@TimeWindow) = 'WEEK'      SET @Days = 7;
    ELSE IF UPPER(@TimeWindow) = 'QUARTER'   SET @Days = 90;
    ELSE                                     SET @Days = 30; -- Default to Month/30 days

    IF UPPER(@TimeWindow) = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, EOMONTH(GETDATE()));
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate   = @StartDate;
    END
    ELSE IF UPPER(@TimeWindow) = 'LASTMONTH'
    BEGIN
        SET @StartDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
        SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
        SET @PrevEndDate   = @StartDate;
    END
    ELSE IF UPPER(@TimeWindow) = 'YESTERDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
        SET @EndDate   = CAST(GETDATE() AS DATE);
        SET @PrevStartDate = DATEADD(DAY, -1, @StartDate);
        SET @PrevEndDate   = @StartDate;
    END
    ELSE
    BEGIN
        SET @StartDate = DATEADD(DAY, -@Days, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @PrevStartDate = DATEADD(DAY, -@Days, @StartDate);
        SET @PrevEndDate   = @StartDate;
    END;

    ---------------------------------------------------------
    -- 1. REGISTERED USERS (Total)
    ---------------------------------------------------------
    DECLARE @RegUsers_Current INT, @RegUsers_Prev INT;
    
    SELECT @RegUsers_Current = COUNT(*) 
    FROM M_Consumer AS MC WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) ON VC.M_consumerId = MC.M_Consumerid
    WHERE VC.Comp_ID = @CompId AND MC.IsDelete = 0;

    SELECT @RegUsers_Prev = COUNT(*) 
    FROM M_Consumer AS MC WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) ON VC.M_consumerId = MC.M_Consumerid
    WHERE VC.Comp_ID = @CompId AND MC.IsDelete = 0
      AND MC.Entry_Date < @StartDate;

    ---------------------------------------------------------
    -- 2. ACTIVE USERS (Users with activity in period)
    ---------------------------------------------------------
    DECLARE @ActiveUsers_Current INT, @ActiveUsers_Prev INT;

    SELECT @ActiveUsers_Current = COUNT(DISTINCT MobileNo) 
    FROM Pro_Enq WITH (NOLOCK)
    WHERE Comp_ID = @CompId AND Enq_Date >= @StartDate AND Enq_Date < @EndDate;

    SELECT @ActiveUsers_Prev = COUNT(DISTINCT MobileNo) 
    FROM Pro_Enq WITH (NOLOCK)
    WHERE Comp_ID = @CompId AND Enq_Date >= @PrevStartDate AND Enq_Date < @PrevEndDate;

    ---------------------------------------------------------
    -- 3. QR CODES CREATED (Total)
    ---------------------------------------------------------
    DECLARE @QrCreated_Current INT, @QrCreated_Prev INT;

    SELECT @QrCreated_Current = COUNT(*) 
    FROM M_Code WITH (NOLOCK)
    WHERE Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WHERE Comp_ID = @CompId);

    SELECT @QrCreated_Prev = COUNT(*) 
    FROM M_Code WITH (NOLOCK)
    WHERE Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WHERE Comp_ID = @CompId)
      AND Allot_Date < @StartDate;

    ---------------------------------------------------------
    -- 4. QR CODES VERIFIED (Total)
    ---------------------------------------------------------
    DECLARE @QrVerified_Current INT, @QrVerified_Prev INT;

    SELECT @QrVerified_Current = COUNT(*) 
    FROM Pro_Enq WITH (NOLOCK)
    WHERE Comp_ID = @CompId;

    SELECT @QrVerified_Prev = COUNT(*) 
    FROM Pro_Enq WITH (NOLOCK)
    WHERE Comp_ID = @CompId AND Enq_Date < @StartDate;

    ---------------------------------------------------------
    -- 5. TOTAL CASH UTILIZED (Total Payouts)
    ---------------------------------------------------------
    DECLARE @CashUtilized_Current DECIMAL(18,2), @CashUtilized_Prev DECIMAL(18,2);

    SELECT @CashUtilized_Current = SUM(ISNULL(Amount, 0)) 
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @CompId AND Status = 'Success';

    SELECT @CashUtilized_Prev = SUM(ISNULL(Amount, 0)) 
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @CompId AND Status = 'Success' AND ReqDate < @StartDate;

    ---------------------------------------------------------
    -- 6. CASH UTILIZATION %
    ---------------------------------------------------------
    DECLARE @CurrentWalletBal DECIMAL(18,2) = 0;
    SELECT TOP 1 @CurrentWalletBal = ISNULL(NewBal, Amount) 
    FROM tblCashWalletBalance WITH (NOLOCK)
    WHERE Comp_Id = @CompId ORDER BY Id DESC;

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
    INTO #KYC_Current
    FROM M_Consumer AS MC WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) ON VC.M_consumerId = MC.M_Consumerid
    WHERE VC.Comp_ID = @CompId AND MC.IsDelete = 0
    GROUP BY 
        CASE 
            WHEN VC.VRKbl_KYC_status = 1 THEN 'ActiveKYC'
            WHEN VC.VRKbl_KYC_status = 2 THEN 'RejectedKYC'
            ELSE 'PendingKYC'
        END;

    SELECT 
        KYCStatus,
        CurrentCount,
        0 AS PreviousCount,
        0 AS Diff
    FROM #KYC_Current;

END;
GO
