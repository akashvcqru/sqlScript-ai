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
    DECLARE @Last10Mobile NVARCHAR(10) = RIGHT(@CleanMobile, 10);
    DECLARE @M_ConsumerId INT;
    SELECT TOP 1 @M_ConsumerId = M_ConsumerId FROM M_Consumer WITH (NOLOCK) 
    WHERE IsDelete = 0 
      AND (
          MobileNo IN (@CleanMobile, '+' + @CleanMobile, '91' + @CleanMobile, '+91' + @CleanMobile)
          OR RIGHT(MobileNo, 10) = @Last10Mobile
      );

    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (calculation_value / 100.0) 
    FROM loyalty_calculation WITH (NOLOCK)
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;
    IF @Multiplier IS NULL OR @Multiplier <= 0 SET @Multiplier = 1.00;

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
        Points_Val FLOAT,
        Status VARCHAR(30),
        Code1 VARCHAR(100),
        Code2 VARCHAR(100)
    );

    INSERT INTO #UPITrans (Id, ReqDate, Amount, Points_Val, Status, Code1, Code2)
    SELECT Id, ReqDate, Amount, Points_Val, Status, Code1, Code2
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id 
      AND M_Consumerid = @M_ConsumerId
      AND Status = 'Success'
      AND Code1 IS NOT NULL AND Code1 <> '' AND LEN(Code1) > 1
      AND Code2 IS NOT NULL AND Code2 <> '' AND LEN(Code2) > 6;

    INSERT INTO #UPITrans (Id, ReqDate, Amount, Points_Val, Status, Code1, Code2)
    SELECT Id, ReqDate, Amount, Points_Val, Status, Code1, Code2
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id 
      AND (
          MobileNo IN (@CleanMobile, '+' + @CleanMobile, '91' + @CleanMobile, '+91' + @CleanMobile)
          OR RIGHT(MobileNo, 10) = @Last10Mobile
      )
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
        WHERE PE.MobileNo = @Last10Mobile AND PE.Is_Success = '1'

        UNION ALL

        SELECT M.Row_ID, M.Pro_ID, M.Series_Order, M.Series_Serial, PE.Enq_Date
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = @Comp_Id
        WHERE PE.MobileNo = '+' + @Last10Mobile AND PE.Is_Success = '1'

        UNION ALL

        SELECT M.Row_ID, M.Pro_ID, M.Series_Order, M.Series_Serial, PE.Enq_Date
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = @Comp_Id
        WHERE PE.MobileNo = '91' + @Last10Mobile AND PE.Is_Success = '1'

        UNION ALL

        SELECT M.Row_ID, M.Pro_ID, M.Series_Order, M.Series_Serial, PE.Enq_Date
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID AND PR.Comp_Id = @Comp_Id
        WHERE PE.MobileNo = '+91' + @Last10Mobile AND PE.Is_Success = '1'
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

    -- Get actual earned points from BLoyaltyPointsEarned
    DROP TABLE IF EXISTS #EarnedPoints;
    SELECT
        M_Codeid,
        SUM(Points) AS Points
    INTO #EarnedPoints
    FROM (
        SELECT
            MC.M_Codeid,
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
            WHERE MC2.M_Consumerid = @M_ConsumerId
        ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
        INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        WHERE BL.compid = @Comp_Id
          AND MC.M_Consumerid = @M_ConsumerId

        UNION ALL

        SELECT
            MC.M_Codeid,
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
            WHERE MC2.M_Consumerid = @M_ConsumerId
        ) BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND BMC.rn = 1
        INNER JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
        WHERE BL.compid IS NULL
          AND MC.M_Consumerid = @M_ConsumerId
          AND PR.Comp_ID = @Comp_Id
    ) x
    GROUP BY M_Codeid;

    CREATE CLUSTERED INDEX IX_EarnedPoints ON #EarnedPoints(M_Codeid);

    -- Record Scan earnings in #Ledger (Exclude Comp-1152 which has its own ledger table below)
    -- Join with #UPITrans on Code1/Code2 to align scan LedgerDate with UPI ReqDate
    INSERT INTO #Ledger (LedgerDate, SortOrder, TransactionType, RefId, Amount, Status)
    SELECT 
        ISNULL(ut.ReqDate, US.Enq_Date) AS LedgerDate,
        1 AS SortOrder,
        'SCAN' AS TransactionType,
        US.M_Codeid AS RefId,
        ISNULL(NULLIF(P.Points, 0), ISNULL(CP.ConfigPoints, 0)) AS Amount,
        'Success' AS Status
    FROM #UniqueScans US
    INNER JOIN M_Code M WITH (NOLOCK) ON US.M_Codeid = M.Row_ID
    LEFT JOIN #EarnedPoints P ON P.M_Codeid = US.M_Codeid
    LEFT JOIN #ConfigPoints CP ON CP.M_Codeid = US.M_Codeid
    LEFT JOIN #UPITrans ut ON ut.Code1 = M.Code1 AND ut.Code2 = M.Code2
    WHERE US.rn = 1 AND @Comp_Id <> 'Comp-1152';

    SELECT 
        CompanyName,
        '' AS ConsumerName,
        ProductName,
        MobileNo,
        Code1Code2,
        ModeOfVerification,
        Amount,
        ClaimRedeemAmount,
        Status,
        CheckedDate,
        CAST(0.00 AS DECIMAL(18,2)) AS RunningBalance,
        CAST(ClaimRedeemAmount - Amount AS DECIMAL(18,2)) AS ExceededPointsNegative,
        CAST(1 AS INT) AS IsFraudEntry
    INTO #FinalAnalysis
    FROM
    (
        SELECT
            CompanyName,
            ProductName,
            MobileNo,
            Code1Code2,
            ModeOfVerification,
            CAST(Points AS DECIMAL(18,2)) AS Amount,
            CAST(TransferedAmount AS DECIMAL(18,2)) AS ClaimRedeemAmount,
            'Success' AS Status,
            CheckedDate
        FROM ProEnq_Transactions WITH (NOLOCK)
        WHERE TransferedAmount > Points
          AND (@Comp_Id IS NULL OR Comp_ID = @Comp_Id)
          AND CheckedDate >= @StartDate
          AND CheckedDate < @EndDate
          AND (
              MobileNo IN (@CleanMobile, '+' + @CleanMobile, '91' + @CleanMobile, '+91' + @CleanMobile)
              OR RIGHT(MobileNo, 10) = @Last10Mobile
          )

        UNION ALL

        SELECT
            Comp_Name,
            'NA',
            Mobileno,
            'NA',
            'NA',
            CAST(EarnedPoints AS DECIMAL(18,2)),
            CAST(Amount AS DECIMAL(18,2)),
            'Success',
            Claim_date
        FROM Claim_Transaction WITH (NOLOCK)
        WHERE Amount > EarnedPoints
          AND (@Comp_Id IS NULL OR Comp_ID = @Comp_Id)
          AND Claim_date >= @StartDate
          AND Claim_date < @EndDate
          AND (
              Mobileno IN (@CleanMobile, '+' + @CleanMobile, '91' + @CleanMobile, '+91' + @CleanMobile)
              OR RIGHT(Mobileno, 10) = @Last10Mobile
          )
    ) X;

    -- If Search is provided, filter #FinalAnalysis
    IF @Search IS NOT NULL AND @Search <> ''
    BEGIN
        SET @Search = LTRIM(RTRIM(@Search));
        DELETE FROM #FinalAnalysis
        WHERE ProductName NOT LIKE '%' + @Search + '%'
          AND Code1Code2 NOT LIKE '%' + @Search + '%'
          AND ModeOfVerification NOT LIKE '%' + @Search + '%'
          AND Status NOT LIKE '%' + @Search + '%'
          AND MobileNo NOT LIKE '%' + @Search + '%'
          AND CompanyName NOT LIKE '%' + @Search + '%';
    END

    -- Return Paginated Output OR Export Output
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #FinalAnalysis;

    IF @IsExport = 1
    BEGIN
        SELECT
            CompanyName,
            ConsumerName,
            ProductName,
            MobileNo,
            Code1Code2,
            ModeOfVerification,
            Amount,
            ClaimRedeemAmount,
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
            ConsumerName,
            ProductName,
            MobileNo,
            Code1Code2,
            ModeOfVerification,
            Amount,
            ClaimRedeemAmount,
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
END
GO
