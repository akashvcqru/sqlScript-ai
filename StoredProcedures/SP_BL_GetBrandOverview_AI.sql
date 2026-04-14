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
 
   ---------------------------------------------------------
   -- DATE RANGE LOGIC
   ---------------------------------------------------------

   DECLARE @StartDate DATE, @EndDate DATE;
DECLARE @PrevStartDate DATE, @PrevEndDate DATE;
DECLARE @Days INT;

----------------------------------------------------
-- Days mapping
----------------------------------------------------
IF UPPER(@TimeWindow) = 'TODAY'          SET @Days = 1;
ELSE IF UPPER(@TimeWindow) = 'YESTERDAY' SET @Days = 1;
ELSE IF UPPER(@TimeWindow) = 'LASTWEEK'  SET @Days = 14;
ELSE IF UPPER(@TimeWindow) = 'WEEK'      SET @Days = 7;
ELSE IF UPPER(@TimeWindow) = 'QUARTER'   SET @Days = 90;
ELSE                                     SET @Days = 7;

----------------------------------------------------
-- Date range logic
----------------------------------------------------
IF UPPER(@TimeWindow) = 'MONTH'
BEGIN
    SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    SET @EndDate   = EOMONTH(GETDATE());

    SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
    SET @PrevEndDate   = EOMONTH(DATEADD(MONTH, -1, GETDATE()));
END
ELSE IF UPPER(@TimeWindow) = 'LASTMONTH'
BEGIN
    SET @StartDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
    SET @EndDate   = EOMONTH(DATEADD(MONTH, -1, GETDATE()));

    SET @PrevStartDate = DATEADD(MONTH, -1, @StartDate);
    SET @PrevEndDate   = EOMONTH(DATEADD(MONTH, -1, @EndDate));
END
ELSE IF UPPER(@TimeWindow) = 'YESTERDAY'
BEGIN
    SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
    SET @EndDate   = CAST(GETDATE() AS DATE);

    SET @PrevEndDate   = @StartDate;
    SET @PrevStartDate = DATEADD(DAY, -1, @StartDate);
END
ELSE
BEGIN
    SET @StartDate = DATEADD(DAY, -@Days, CAST(GETDATE() AS DATE));
    SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));

    SET @PrevEndDate   = @StartDate;
    SET @PrevStartDate = DATEADD(DAY, -@Days, @StartDate);
END;

   ---------------------------------------------------------
   -- TOTAL CASH EARNED
   ---------------------------------------------------------
   SELECT SUM(ISNULL(Amount, 0)) AS TotalCash_Current
   INTO #Cash_Current
   FROM tblUPITransactionDetails UPI WITH (NOLOCK)
   WHERE Comp_Id = @CompId
    AND Status = 'Success'
     AND ReqDate >= @StartDate
     AND ReqDate < @EndDate;
 
   SELECT SUM(ISNULL(Amount, 0)) AS TotalCash_Previous
   INTO #Cash_Prev
   FROM tblUPITransactionDetails WITH (NOLOCK)
   WHERE Comp_Id = @CompId
   AND Status = 'Success'
     AND ReqDate >= @PrevStartDate
     AND ReqDate < @PrevEndDate;
 
   ---------------------------------------------------------
   -- TOTAL CASH BURN (REDEEM) FROM SAME TABLE
   ---------------------------------------------------------
   SELECT SUM(ISNULL(Amount, 0)) AS CashBurn_Current
   INTO #Burn_Current
   FROM tblUPITransactionDetails WITH (NOLOCK)
   WHERE Comp_Id = @CompId
   AND Status = 'Success'
     AND ReqDate >= @StartDate
     AND ReqDate < @EndDate;
 
   SELECT SUM(ISNULL(Amount, 0)) AS CashBurn_Previous
   INTO #Burn_Prev
   FROM tblUPITransactionDetails WITH (NOLOCK)
   WHERE Comp_Id = @CompId
     AND Status = 'Success'
     AND ReqDate >= @PrevStartDate
     AND ReqDate < @PrevEndDate;
 
   ---------------------------------------------------------
   -- ACTIVE USERS
   ---------------------------------------------------------
   SELECT COUNT(*) AS ActiveUsers_Current
   INTO #AU_Current
   FROM M_Consumer AS MC   
   INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) 
   ON VC.M_consumerId=MC.M_Consumerid
   WHERE VC.Comp_ID = @CompId AND MC.IsDelete=0
     AND VC.Entry_date >= @StartDate
     AND VC.Entry_date < @EndDate;
 
   SELECT COUNT(*) AS ActiveUsers_Previous
   INTO #AU_Prev
   FROM M_Consumer AS MC   
   INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) 
   ON VC.M_consumerId=MC.M_Consumerid
   WHERE VC.Comp_ID = @CompId AND MC.IsDelete=0
     AND VC.Entry_date >= @PrevStartDate
     AND VC.Entry_date < @PrevEndDate;
 
   ---------------------------------------------------------
   -- TOTAL USERS (ALL-TIME)
   ---------------------------------------------------------
   SELECT COUNT(*) AS TotalUsers
   INTO #TotalUsers
   FROM M_Consumer AS MC   
   INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) 
   ON VC.M_consumerId=MC.M_Consumerid
   WHERE VC.Comp_ID = @CompId AND MC.IsDelete=0

 
   ---------------------------------------------------------
   -- KYC SUMMARY
   ---------------------------------------------------------
   SELECT 
        CASE 
            WHEN VC.VRKbl_KYC_status = 1 THEN 'ActiveKYC'
            WHEN VC.VRKbl_KYC_status = 2 THEN 'RejectedKYC'
            ELSE 'PendingKYC'
        END AS KYCStatus,
        COUNT(*) AS CurrentCount
   INTO #KYC_Current
   FROM M_Consumer AS MC   
   INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) 
   ON VC.M_consumerId=MC.M_Consumerid
   WHERE VC.Comp_ID = @CompId AND MC.IsDelete=0
     AND VC.Entry_date >= @StartDate   
     AND VC.Entry_date < @EndDate
   GROUP BY 
        CASE 
            WHEN VC.VRKbl_KYC_status = 1 THEN 'ActiveKYC'
            WHEN VC.VRKbl_KYC_status = 2 THEN 'RejectedKYC'
            ELSE 'PendingKYC'
        END;
 
   SELECT 
        CASE 
            WHEN VC.VRKbl_KYC_status = 1 THEN 'ActiveKYC'
            WHEN VC.VRKbl_KYC_status = 2 THEN 'RejectedKYC'
            ELSE 'PendingKYC'
        END AS KYCStatus,
        COUNT(*) AS PreviousCount
   INTO #KYC_Prev
   FROM M_Consumer AS MC   
   INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) 
   ON VC.M_consumerId=MC.M_Consumerid
   WHERE VC.Comp_ID = @CompId AND MC.IsDelete=0
     AND VC.Entry_date >= @PrevStartDate   
     AND VC.Entry_date < @PrevEndDate
   GROUP BY 
        CASE 
            WHEN VC.VRKbl_KYC_status = 1 THEN 'ActiveKYC'
            WHEN VC.VRKbl_KYC_status = 2 THEN 'RejectedKYC'
            ELSE 'PendingKYC'
        END;
 
   ---------------------------------------------------------
   -- TOTAL GENERATED CODES (STATIC)
   ---------------------------------------------------------
   SELECT COUNT(*) AS GeneratedCodes
   INTO #Codes_Generated
   FROM M_Code WITH (NOLOCK) WHERE pro_id in (select pro_id from Pro_reg where Comp_ID = @CompId);
 
   ---------------------------------------------------------
   -- TOTAL SCANNED CODES
   ---------------------------------------------------------
   SELECT COUNT(*) AS ScannedCodes
   INTO #Codes_Scanned
   FROM Pro_Enq PE WITH (NOLOCK)
   WHERE PE.Comp_ID = @CompId
 
   ---------------------------------------------------------
   -- TOTAL BURNED
   ---------------------------------------------------------
   SELECT DISTINCT pe.MobileNo
   INTO #ThisMobileNo
   FROM M_Code mc WITH (NOLOCK)
   INNER JOIN Pro_Enq pe WITH (NOLOCK)
         ON pe.Received_Code1 = CONVERT(VARCHAR(50), mc.code1)
        AND pe.Received_Code2 = CONVERT(VARCHAR(50), mc.code2)
   WHERE mc.pro_id IN (SELECT pro_id FROM Pro_reg WHERE Comp_ID = @CompID)
     AND pe.Received_Code1 IS NOT NULL and pe.Is_Success=1;

   SELECT SUM(ut.Amount) AS Burn2
   INTO #Burn2
   from tblUPITransactionDetails ut WITH (NOLOCK) 
   WHERE ut.Status = 'Success' AND Comp_Id=@CompId;

   ---------------------------------------------------------
   -- RESULT SET 1: KPI SUMMARY
   ---------------------------------------------------------
   SELECT
        (SELECT TotalCash_Current FROM #Cash_Current) AS TotalCash_Current,
        (SELECT TotalCash_Previous FROM #Cash_Prev) AS TotalCash_Previous,
 
        (SELECT CashBurn_Current FROM #Burn_Current) AS CashBurn_Current,
        (SELECT CashBurn_Previous FROM #Burn_Prev) AS CashBurn_Previous,
 
        (SELECT ActiveUsers_Current FROM #AU_Current) AS ActiveUsers_Current,
        (SELECT ActiveUsers_Previous FROM #AU_Prev) AS ActiveUsers_Previous,
 
        (SELECT TotalUsers FROM #TotalUsers) AS TotalUsers,
 
        (SELECT GeneratedCodes FROM #Codes_Generated) AS Total_GeneratedCodes,
        (SELECT ScannedCodes FROM #Codes_Scanned) AS Total_ScannedCodes,
 
        ISNULL((SELECT Burn2 FROM #Burn2),0) AS Total_BurnedCash;
 
 
   ---------------------------------------------------------
   -- RESULT SET 2: KYC STATUS
   ---------------------------------------------------------
   SELECT 
        C.KYCStatus,
        C.CurrentCount,
        P.PreviousCount,
        (C.CurrentCount - P.PreviousCount) AS Diff
   FROM #KYC_Current C
   LEFT JOIN #KYC_Prev P ON C.KYCStatus = P.KYCStatus;

END;
GO
