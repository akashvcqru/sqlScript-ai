USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-13
-- Description: Analyzes a user's lifetime ledger (earnings and redemptions) chronologically and links
--              claims and UPI payouts to identify which redemptions are "fraudulent" (post-transaction
--              running balance < 0) and by how many points. Restored PointsRedeemed column.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetUserNegativeBalanceAnalysis_AI]
(
    @MobileNo NVARCHAR(30),
    @Comp_Id  NVARCHAR(50),
    @DatePreset NVARCHAR(20) = 'ALL',
    @FromDate        NVARCHAR(30) = NULL,
    @ToDate          NVARCHAR(30) = NULL,
    @Page     INT = 1,
    @Limit    INT = 10,
    @Search   NVARCHAR(100) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Comp_Id = 'Comp-1669'
    BEGIN
        SELECT TOP 0
            CAST(NULL AS NVARCHAR(150)) AS CompanyName,
            CAST(NULL AS NVARCHAR(150)) AS ProductName,
            CAST(NULL AS NVARCHAR(50)) AS MobileNo,
            CAST(NULL AS NVARCHAR(150)) AS Code1Code2,
            CAST(NULL AS NVARCHAR(50)) AS ModeOfVerification,
            CAST(0.00 AS DECIMAL(18,2)) AS Amount,
            CAST(0.00 AS DECIMAL(18,2)) AS ClaimRedeemAmount,
            CAST(NULL AS NVARCHAR(50)) AS Status,
            CAST(NULL AS DATETIME) AS CheckedDate,
            CAST(0.00 AS DECIMAL(18,2)) AS RunningBalance,
            CAST(0.00 AS DECIMAL(18,2)) AS ExceededPointsNegative,
            CAST(0 AS INT) AS IsFraudEntry;
        
        SELECT 0 AS TotalRecords, @Page AS CurrentPage, @Limit AS [Limit], 0 AS TotalPages;
        RETURN;
    END

    -- Determine Date Range
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    DECLARE @Preset NVARCHAR(20) = UPPER(ISNULL(@DatePreset, ''));
    IF (@Preset = '' OR @Preset = 'NULL') 
    BEGIN
        IF (@FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
            SET @Preset = 'CUSTOM';
        ELSE
            SET @Preset = 'ALL';
    END

    IF (@Preset = 'TODAY')
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'TOMORROW')
    BEGIN
        SET @StartDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 2, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'YESTERDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
        SET @EndDate   = CAST(GETDATE() AS DATE);
    END
    ELSE IF (@Preset = 'WEEK' OR @Preset = 'THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH' OR @Preset = 'MONTHS')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'YEAR' OR @Preset = 'THIS YEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE -- ALL or default fallback
    BEGIN
        SET @StartDate = CAST('2015-01-01 00:00:00.000' AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    DROP TABLE IF EXISTS #UniqueScans, #ConfigPoints, #Ledger, #ChronologicalLedger, #FinalAnalysis;

    -- Clean the mobile number and resolve consumer info
    DECLARE @CleanMobile NVARCHAR(30) = REPLACE(@MobileNo, '+', '');
    DECLARE @M_ConsumerId INT;
    SELECT TOP 1 @M_ConsumerId = M_ConsumerId FROM M_Consumer WITH (NOLOCK) WHERE MobileNo IN (@CleanMobile, '+' + @CleanMobile) AND IsDelete = 0;

    -- Ensure page/limit values are valid
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    IF @M_ConsumerId IS NULL
    BEGIN
        -- If user not found, return empty results matching output schema
        SELECT 
            CAST(NULL AS NVARCHAR(150)) AS CompanyName,
            CAST(NULL AS NVARCHAR(150)) AS ProductName,
            CAST(NULL AS NVARCHAR(30)) AS MobileNo,
            CAST(NULL AS NVARCHAR(100)) AS Code1Code2,
            CAST(NULL AS NVARCHAR(100)) AS ModeOfVerification,
            CAST(NULL AS DECIMAL(18,2)) AS Amount,
            CAST(NULL AS DECIMAL(18,2)) AS ClaimRedeemAmount,
            CAST(NULL AS NVARCHAR(50)) AS Status,
            CAST(NULL AS DATETIME) AS CheckedDate,
            CAST(NULL AS DECIMAL(18,2)) AS RunningBalance,
            CAST(NULL AS DECIMAL(18,2)) AS ExceededPointsNegative,
            CAST(NULL AS INT) AS IsFraudEntry
        WHERE 1 = 0;

        IF @IsExport = 0
        BEGIN
            SELECT
                0 AS TotalRecords,
                @Page AS CurrentPage,
                @Limit AS [Limit],
                0 AS TotalPages;
        END
        RETURN;
    END

    -- Temporary table to hold unified lifetime ledger transactions
    CREATE TABLE #Ledger (
        LedgerDate DATETIME,
        SortOrder INT, -- 1: Earning, 2: Redemption
        TransactionType NVARCHAR(50),
        RefId BIGINT, -- Changed to BIGINT to allow index seeks on joins
        Amount DECIMAL(18,2), -- positive for earnings, negative for redemptions
        Status NVARCHAR(50)
    );

    ---------------------------------------------------------
    -- LOAD REDEMPTIONS: UPI PAYOUTS (SUCCESS REST) FIRST
    -- (Needed early to match and align timestamps of scans)
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #UPITrans;
    CREATE TABLE #UPITrans (
        Id INT,
        ReqDate DATETIME,
        Amount FLOAT,
        Status VARCHAR(30),
        Code1 VARCHAR(100),
        Code2 VARCHAR(100)
    );

    INSERT INTO #UPITrans (Id, ReqDate, Amount, Status, Code1, Code2)
    SELECT Id, ReqDate, Amount, Status, Code1, Code2
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id 
      AND M_Consumerid = @M_ConsumerId
      AND Status = 'Success'
      AND Code1 IS NOT NULL AND Code1 <> '' AND LEN(Code1) > 1
      AND Code2 IS NOT NULL AND Code2 <> '' AND LEN(Code2) > 6;

    INSERT INTO #UPITrans (Id, ReqDate, Amount, Status, Code1, Code2)
    SELECT Id, ReqDate, Amount, Status, Code1, Code2
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id 
      AND MobileNo = @CleanMobile
      AND Status = 'Success'
      AND Code1 IS NOT NULL AND Code1 <> '' AND LEN(Code1) > 1
      AND Code2 IS NOT NULL AND Code2 <> '' AND LEN(Code2) > 6
      AND NOT EXISTS (SELECT 1 FROM #UPITrans WHERE Id = tblUPITransactionDetails.Id);

    INSERT INTO #UPITrans (Id, ReqDate, Amount, Status, Code1, Code2)
    SELECT Id, ReqDate, Amount, Status, Code1, Code2
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id 
      AND MobileNo = '+' + @CleanMobile
      AND Status = 'Success'
      AND Code1 IS NOT NULL AND Code1 <> '' AND LEN(Code1) > 1
      AND Code2 IS NOT NULL AND Code2 <> '' AND LEN(Code2) > 6
      AND NOT EXISTS (SELECT 1 FROM #UPITrans WHERE Id = tblUPITransactionDetails.Id);

    ---------------------------------------------------------
    -- 1. LOAD EARNINGS: SCAN POINTS (LIFETIME)
    -- Optimized SARGable joins on Pro_Enq MobileNo (UNION ALL ensures index seek)
    ---------------------------------------------------------
    SELECT 
        Row_ID AS M_Codeid, Pro_ID, Series_Order, Series_Serial, Enq_Date,
        ROW_NUMBER() OVER (PARTITION BY Row_ID ORDER BY Enq_Date) as rn
    INTO #UniqueScans
    FROM (
        SELECT M.Row_ID, M.Pro_ID, M.Series_Order, M.Series_Serial, PE.Enq_Date
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = @Comp_Id
        WHERE PE.MobileNo = @CleanMobile AND PE.Is_Success = '1'

        UNION ALL

        SELECT M.Row_ID, M.Pro_ID, M.Series_Order, M.Series_Serial, PE.Enq_Date
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = @Comp_Id
        WHERE PE.MobileNo = '+' + @CleanMobile AND PE.Is_Success = '1'
    ) PE;

    CREATE CLUSTERED INDEX IX_UniqueScans_MCodeid ON #UniqueScans(M_Codeid);



    -- Get Configured points for each scan
    SELECT 
        US.M_Codeid,
        MAX(CAST(
            CASE 
                WHEN SST.Points IS NOT NULL AND SST.Points > 0 THEN SST.Points
                ELSE ISNULL(SST.IsCash, 0) * (1.00 + ISNULL(LC.calculation_value, 0.0) / 100.0)
            END 
        AS DECIMAL(18,2))) AS ConfigPoints,
        MAX(CAST(ISNULL(SST.Points, 0.00) AS DECIMAL(18,2))) AS SSTPoints
    INTO #ConfigPoints
    FROM #UniqueScans US
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = US.Pro_ID AND SS.Comp_ID = @Comp_Id
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    LEFT JOIN loyalty_calculation LC WITH (NOLOCK) ON LC.comp_id = @Comp_Id AND LC.isactive = 1 AND LC.isdelete = 0
    WHERE US.rn = 1
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
      AND (US.Series_Order > SS.start_order OR (US.Series_Order = SS.start_order AND US.Series_Serial >= SS.start_series))
      AND (US.Series_Order < SS.end_order OR (US.Series_Order = SS.end_order AND US.Series_Serial <= SS.end_series))
    GROUP BY US.M_Codeid;

    CREATE CLUSTERED INDEX IX_ConfigPoints ON #ConfigPoints(M_Codeid);

    -- Record Scan earnings in #Ledger (Exclude Comp-1152 which has its own ledger table below)
    -- Join with #UPITrans on Code1/Code2 to align scan LedgerDate with UPI ReqDate
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        ISNULL(ut.ReqDate, US.Enq_Date) AS LedgerDate,
        1 AS SortOrder,
        'SCAN' AS TransactionType,
        US.M_Codeid AS RefId,
        ISNULL(CP.ConfigPoints, 0) AS Amount,
        'Success' AS Status
    FROM #UniqueScans US
    INNER JOIN M_Code M WITH (NOLOCK) ON US.M_Codeid = M.Row_ID
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = US.M_Codeid
    LEFT JOIN #UPITrans ut ON ut.Code1 = M.Code1 AND ut.Code2 = M.Code2
    WHERE US.rn = 1 AND @Comp_Id <> 'Comp-1152';

    -- Override: Load Comp-1152 scans from ConsumerPointsCashDetails (LIFETIME)
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        CP.Enq_Date AS LedgerDate,
        1 AS SortOrder,
        'SCAN' AS TransactionType,
        NULL AS RefId,
        TRY_CAST(CP.points AS DECIMAL(18,2)) AS Amount,
        'Success' AS Status
    FROM dbo.ConsumerPointsCashDetails CP WITH (NOLOCK)
    WHERE CP.MobileNo = @CleanMobile
      AND @Comp_Id = 'Comp-1152'
      AND CP.Enq_Date >= '2022-08-04 00:00:00.000'
      AND CP.Is_Success = 1;

    ---------------------------------------------------------
    -- 2. LOAD EARNINGS: REFERRAL POINTS & OTHER REWARDS
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        BL.UpdateDate AS LedgerDate,
        1 AS SortOrder,
        UPPER(BL.ServiceName) AS TransactionType,
        BL.BLoyalty_PointEarnedID AS RefId,
        CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS Amount,
        'Success' AS Status
    FROM dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
    WHERE BL.M_Consumerid = @M_ConsumerId AND BL.compid = @Comp_Id
      AND LOWER(BL.ServiceName) IN ('refral', 'referral', 'kycrewards', 'supervisor', 'invoicebenifit', 'invoicerewards');

    ---------------------------------------------------------
    -- 3. LOAD REDEMPTIONS: CLAIMS (APPROVED REST)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        CD.Claim_date AS LedgerDate,
        2 AS SortOrder,
        'CLAIM' AS TransactionType,
        CD.Row_ID AS RefId,
        -CD.Amount AS Amount,
        'Approved' AS Status
    FROM ClaimDetails CD WITH (NOLOCK)
    WHERE CD.Comp_id = @Comp_Id AND CD.Mobileno = @CleanMobile
      AND CD.Isapproved = 1;

    -- 4. LOAD REDEMPTIONS: UPI PAYOUTS (SUCCESS REST)
    -- (UPI records are already pre-loaded into #UPITrans)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        ReqDate AS LedgerDate,
        2 AS SortOrder,
        'UPI' AS TransactionType,
        Id AS RefId,
        -ISNULL(Amount, 0) AS Amount,
        Status AS Status
    FROM #UPITrans;

    ---------------------------------------------------------
    -- 5. LOAD REDEMPTIONS: BPOINTS REDEMPTION (ACCEPTED / SUCCESS REST)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        BP.Redeemdate AS LedgerDate,
        2 AS SortOrder,
        'BPOINTS' AS TransactionType,
        NULL AS RefId,
        -ISNULL(BP.RedeemPoints, 0) AS Amount,
        BP.bpstatus AS Status
    FROM BPointsTransaction BP WITH (NOLOCK)
    WHERE BP.companyid = @Comp_Id AND BP.RedeemBy = @M_ConsumerId
      AND BP.bpstatus IN ('Accepted', 'SUCCESS');

    ---------------------------------------------------------
    -- 6. LOAD REDEMPTIONS: LEGACY TRANSACTIONS (SUCCESS REST)
    ---------------------------------------------------------
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        TR.TransactionDate AS LedgerDate,
        2 AS SortOrder,
        'TRANSACTION' AS TransactionType,
        NULL AS RefId,
        -ISNULL(CAST(TR.Amount AS DECIMAL(18,2)), 0) AS Amount,
        'Success' AS Status
    FROM Transactions TR WITH (NOLOCK)
    WHERE TR.CompId = REPLACE(@Comp_Id, 'Comp-', '') AND TR.M_CounserID = CAST(@M_ConsumerId AS VARCHAR(50))
      AND TR.IsSuccess = 1
      AND (@Comp_Id <> 'Comp-1152' OR TR.TransactionDate > '2022-11-25');

    ---------------------------------------------------------
    -- 7. COMPILE LEDGER AND COMPUTE CHRONOLOGICAL RUNNING BALANCE
    ---------------------------------------------------------
    SELECT 
        LedgerDate,
        SortOrder,
        TransactionType,
        RefId,
        Amount,
        Status,
        SUM(Amount) OVER (
            ORDER BY LedgerDate ASC, SortOrder ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningBalance
    INTO #ChronologicalLedger
    FROM #Ledger;

    ---------------------------------------------------------
    -- 8. RETURN HIGHLIGHTED CLAIMS AND UPI DETAILS WITH FRAUD STATUS
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #FinalAnalysis;
    SELECT 
        (SELECT TOP 1 Comp_Name FROM Comp_Reg WITH (NOLOCK) WHERE Comp_ID = @Comp_Id AND Status = 1) AS CompanyName,
        CASE 
            WHEN CL.TransactionType = 'CLAIM' THEN 'NA'
            ELSE ISNULL(PR.Pro_Name, 'NA')
        END AS ProductName,
        @CleanMobile AS MobileNo,
        CASE 
            WHEN CL.TransactionType = 'CLAIM' THEN 'NA'
            ELSE ISNULL(UT.Code1 + '-' + UT.Code2, 'NA')
        END AS Code1Code2,
        CASE 
            WHEN CL.TransactionType = 'CLAIM' THEN 'NA'
            ELSE ISNULL(PE.Dial_Mode, 'NA')
        END AS ModeOfVerification,
        COALESCE(CD.Amount, UT.Amount, 0.00) AS Amount,
        CL.PointsRedeemed AS ClaimRedeemAmount,
        COALESCE(CD.Points_Redeemed, UT.Points_Val, CL.PointsRedeemed, 0.00) AS ActualPointsTransferred,
        CASE 
            WHEN CL.TransactionType = 'UPI' THEN ISNULL(CP_Code.SSTPoints, 0.00) 
            ELSE NULL 
        END AS CodeServicePoints,
        CL.Status AS Status,
        CL.TransactionDate AS CheckedDate,
        CL.RunningBalance AS RunningBalance,
        CL.ExceededPointsNegative AS ExceededPointsNegative,
        CL.IsFraudEntry AS IsFraudEntry
    INTO #FinalAnalysis
    FROM (
        SELECT 
            LedgerDate AS TransactionDate,
            TransactionType,
            RefId AS TransactionRefId,
            -Amount AS PointsRedeemed,
            Status,
            RunningBalance,
            CASE WHEN RunningBalance < 0 THEN 1 ELSE 0 END AS IsFraudEntry,
            CASE WHEN RunningBalance < 0 THEN -RunningBalance ELSE 0 END AS ExceededPointsNegative
        FROM #ChronologicalLedger
        WHERE TransactionType IN ('CLAIM', 'UPI')
          AND LedgerDate >= @StartDate AND LedgerDate < @EndDate
    ) CL
    LEFT JOIN ClaimDetails CD WITH (NOLOCK) ON CL.TransactionType = 'CLAIM' AND CD.Row_ID = CL.TransactionRefId
    LEFT JOIN tblUPITransactionDetails UT WITH (NOLOCK) ON CL.TransactionType = 'UPI' AND UT.Id = CL.TransactionRefId
    LEFT JOIN M_Code MC WITH (NOLOCK) ON CL.TransactionType = 'UPI' AND UT.Code1 = MC.Code1 AND UT.Code2 = MC.Code2
    LEFT JOIN Pro_Reg PR WITH (NOLOCK) ON MC.Pro_ID = PR.Pro_ID
    LEFT JOIN Pro_Enq PE WITH (NOLOCK) ON CL.TransactionType = 'UPI' AND UT.Code1 = PE.Received_Code1 AND UT.Code2 = PE.Received_Code2 AND PE.MobileNo IN (@CleanMobile, '+' + @CleanMobile, RIGHT(@CleanMobile, 10))
    LEFT JOIN #ConfigPoints CP_Code ON CP_Code.M_Codeid = MC.Row_ID;

    -- If Search is provided, filter #FinalAnalysis
    IF @Search IS NOT NULL AND @Search <> ''
    BEGIN
        SET @Search = LTRIM(RTRIM(@Search));
        DELETE FROM #FinalAnalysis
        WHERE ProductName NOT LIKE '%' + @Search + '%'
          AND Code1Code2 NOT LIKE '%' + @Search + '%'
          AND ModeOfVerification NOT LIKE '%' + @Search + '%'
          AND Status NOT LIKE '%' + @Search + '%'
          AND MobileNo NOT LIKE '%' + @Search + '%';
    END

    -- Return Paginated Output OR Export Output
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #FinalAnalysis;

    IF @IsExport = 1
    BEGIN
        SELECT
            CompanyName,
            ProductName,
            MobileNo,
            Code1Code2,
            ModeOfVerification,
             CodeServicePoints as Amount,
            ActualPointsTransferred as ClaimRedeemAmount, 
            Status,
            CheckedDate,
            RunningBalance,
            ExceededPointsNegative,
            IsFraudEntry
        FROM #FinalAnalysis
        ORDER BY CheckedDate DESC;
    END
    ELSE
    BEGIN
        SELECT
            CompanyName,
            ProductName,
            MobileNo,
            Code1Code2,
            ModeOfVerification,
            CodeServicePoints as Amount,
            ActualPointsTransferred as ClaimRedeemAmount,
            Status,
            CheckedDate,
            RunningBalance,
            ExceededPointsNegative,
            IsFraudEntry
        FROM #FinalAnalysis
        ORDER BY CheckedDate DESC
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        -- Meta Pagination Results
        SELECT
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(@TotalRecords * 1.0 / @Limit) AS TotalPages;
    END

    -- Cleanup temp tables
    DROP TABLE IF EXISTS #UniqueScans, #ConfigPoints, #Ledger, #ChronologicalLedger, #FinalAnalysis;
END
GO
