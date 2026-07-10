USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-10
-- Description: Retrieves statement payout report of duplicate transactions, or complete history if searched.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetStatementPayoutReport_AI]
(
    @Comp_Id         NVARCHAR(50),
    @datePreset      NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, LASTMONTH, ALL, LAST7DAYS
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL,
    @Search          NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- DEFAULT PAGINATION & EXPORT FLAGS
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- DATE RANGE SETTING
    ---------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') 
    FROM Comp_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @CompanyName NVARCHAR(150);
    SELECT @CompanyName = ISNULL(Comp_Name, '') 
    FROM Comp_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    DECLARE @Preset NVARCHAR(20) = UPPER(ISNULL(@datePreset, ''));
    IF (@Preset = '' OR @Preset = 'NULL') 
    BEGIN
        SET @Preset = 'MONTH';
    END

    IF (@Preset = 'TODAY')
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTDAY' OR @Preset = 'YESTERDAY')
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
    ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'QUARTER')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'YEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTYEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
    END
    ELSE IF (@Preset = 'LAST7DAYS' OR @Preset = '7DAYS')
    BEGIN
        SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE -- ALL or fallback
    BEGIN
        SET @StartDate = CAST(@CompanyStartDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    -- MULTIPLIER FOR WORN POINTS
    ---------------------------------------------------------
    DECLARE @Multiplier DECIMAL(18,2) = 1.00;
    SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
    FROM loyalty_calculation 
    WHERE comp_id = @Comp_Id AND isactive = 1 AND isdelete = 0;

    ---------------------------------------------------------
    -- CLEANUP TEMP TABLES
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #RawTransactions, #FilteredTransactions, #PagedReport;

    ---------------------------------------------------------
    -- UNION ALL TRANSACTION TYPES FOR LEDGER VIEW (WITHOUT CLAIM PAYOUTS)
    ---------------------------------------------------------
    SELECT *
    INTO #RawTransactions
    FROM (
        -- 1. Code scan earnings (CREDIT)
        SELECT
            @CompanyName AS CompanyName,
            pr.Pro_Name AS ProductName,
            CONCAT(c.Code1, c.Code2) AS CompleteCode,
            m.MobileNo AS MobileNumber,
            CAST(ISNULL(BL.Points, BL.Cash) AS FLOAT) AS Point,
            CONCAT('+', CAST(CAST(ISNULL(BL.Points, BL.Cash) AS INT) AS VARCHAR(30))) AS NetPayout,
            NULL AS TransactionID,
            BL.UpdateDate AS EnquiryTransactionDate,
            'CODE EARN' AS TransactionType,
            CAST(
                COALESCE(
                    CASE WHEN ss.Service_ID = 'SRV1005' THEN sst.IsCash ELSE sst.Points END,
                    CASE WHEN ss_fallback.Service_ID = 'SRV1005' THEN sst_fallback.IsCash ELSE sst_fallback.Points END,
                    0
                )
            AS FLOAT) AS AssignPoint,
            CAST(
                CASE 
                    WHEN BL.compid = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END
            AS FLOAT) AS WornPoint,
            'App Scan' AS ModeOfVerification,
            CONCAT(COALESCE(m.City, ''), CASE WHEN m.City IS NOT NULL AND m.State IS NOT NULL THEN ', ' ELSE '' END, COALESCE(m.State, '')) AS Location,
            COALESCE(s.ServiceName, 'Loyalty Earn') AS ServiceName,
            BL.compid AS Comp_Id,
            m.ConsumerName,
            NULL AS PrevReqDate,
            NULL AS NextReqDate
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN M_Consumer m WITH (NOLOCK) ON m.M_Consumerid = BL.M_Consumerid
        LEFT JOIN BuiltLoyaltyMCodeCheck bmc WITH (NOLOCK) ON bmc.Pkid = BL.BuildLoyaltyOrReferralMCodeCheckid
        LEFT JOIN M_Consumer_M_Code mc WITH (NOLOCK) ON mc.M_Consumer_MCodeid = bmc.M_Consumer_MCOdeid
        LEFT JOIN M_Code c WITH (NOLOCK) ON c.Row_ID = mc.M_Codeid
        LEFT JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = c.Pro_ID
        LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON sst.SST_Id = BL.SST_id
        LEFT JOIN M_ServiceSubscription ss WITH (NOLOCK) ON sst.Subscribe_Id = ss.Subscribe_Id
        -- Fallback subscription if SST_id is null
        LEFT JOIN M_ServiceSubscription ss_fallback WITH (NOLOCK) ON ss_fallback.Pro_ID = c.Pro_ID AND ss_fallback.Comp_ID = BL.compid AND ss_fallback.IsActive = 1 AND ss_fallback.IsDelete = 0
            AND (c.Series_Order > ss_fallback.start_order OR (c.Series_Order = ss_fallback.start_order AND c.Series_Serial >= ss_fallback.start_series))
            AND (c.Series_Order < ss_fallback.end_order OR (c.Series_Order = ss_fallback.end_order AND c.Series_Serial <= ss_fallback.end_series))
        LEFT JOIN M_ServiceSubscriptionTrans sst_fallback WITH (NOLOCK) ON sst_fallback.Subscribe_Id = ss_fallback.Subscribe_Id AND sst_fallback.IsActive = 1 AND sst_fallback.IsDelete = 0
        LEFT JOIN M_Service s WITH (NOLOCK) ON s.Service_ID = ss.Service_ID
        WHERE BL.compid = @Comp_Id
          AND (BL.ServiceName IS NULL OR LOWER(BL.ServiceName) NOT IN ('refral', 'referral'))

        UNION ALL

        -- 2. Referral Earnings (CREDIT)
        SELECT
            @CompanyName AS CompanyName,
            NULL AS ProductName,
            NULL AS CompleteCode,
            m.MobileNo AS MobileNumber,
            CAST(ISNULL(BL.Points, BL.Cash) AS FLOAT) AS Point,
            CONCAT('+', CAST(CAST(ISNULL(BL.Points, BL.Cash) AS INT) AS VARCHAR(30))) AS NetPayout,
            NULL AS TransactionID,
            BL.UpdateDate AS EnquiryTransactionDate,
            'REFERRAL EARN' AS TransactionType,
            NULL AS AssignPoint,
            NULL AS WornPoint,
            'Referral Bonus' AS ModeOfVerification,
            CONCAT(COALESCE(m.City, ''), CASE WHEN m.City IS NOT NULL AND m.State IS NOT NULL THEN ', ' ELSE '' END, COALESCE(m.State, '')) AS Location,
            'Referral Service' AS ServiceName,
            BL.compid AS Comp_Id,
            m.ConsumerName,
            NULL AS PrevReqDate,
            NULL AS NextReqDate
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN M_Consumer m WITH (NOLOCK) ON m.M_Consumerid = BL.M_Consumerid
        WHERE BL.compid = @Comp_Id
          AND LOWER(BL.ServiceName) IN ('refral', 'referral')

        UNION ALL

        -- 3. UPI/IMPS Payouts (DEBIT)
        SELECT
            @CompanyName AS CompanyName,
            pr.Pro_Name AS ProductName,
            CASE 
                WHEN p.Code1 IS NULL OR p.Code1 = '0' OR p.Code1 = '' 
                  OR p.Code2 IS NULL OR p.Code2 = '0' OR p.Code2 = '' THEN NULL 
                ELSE CONCAT(p.Code1, p.Code2) 
            END AS CompleteCode,
            p.MobileNo AS MobileNumber,
            CAST(ISNULL(p.Points_Val, p.Amount) AS FLOAT) AS Point,
            CONCAT('-', CAST(CAST(ISNULL(p.Points_Val, p.Amount) AS INT) AS VARCHAR(30))) AS NetPayout,
            CAST(p.Id AS VARCHAR(50)) AS TransactionID,
            p.ReqDate AS EnquiryTransactionDate,
            'PAYOUT' AS TransactionType,
            NULL AS AssignPoint,
            NULL AS WornPoint,
            CASE
                WHEN p.UPI_Id IS NOT NULL AND p.UPI_Id <> '' THEN 'UPI Payout'
                ELSE 'IMPS/NEFT Payout'
            END AS ModeOfVerification,
            CONCAT(COALESCE(m.City, ''), CASE WHEN m.City IS NOT NULL AND m.State IS NOT NULL THEN ', ' ELSE '' END, COALESCE(m.State, '')) AS Location,
            COALESCE(s.ServiceName, 'UPI Payout') AS ServiceName,
            p.Comp_Id AS Comp_Id,
            m.ConsumerName,
            -- Window function to check previous transaction date within same group
            LAG(p.ReqDate) OVER (PARTITION BY p.Comp_Id, p.MobileNo, ISNULL(p.Code1, ''), ISNULL(p.Code2, ''), p.Amount, p.Status ORDER BY p.ReqDate) AS PrevReqDate,
            -- Window function to check next transaction date within same group
            LEAD(p.ReqDate) OVER (PARTITION BY p.Comp_Id, p.MobileNo, ISNULL(p.Code1, ''), ISNULL(p.Code2, ''), p.Amount, p.Status ORDER BY p.ReqDate) AS NextReqDate
        FROM tblUPITransactionDetails p WITH (NOLOCK)
        LEFT JOIN M_Consumer m WITH (NOLOCK) ON m.M_Consumerid = p.M_Consumerid
        LEFT JOIN M_Code mc WITH (NOLOCK) ON mc.Code1 = TRY_CAST(p.Code1 AS NUMERIC(5,0)) AND mc.Code2 = TRY_CAST(p.Code2 AS NUMERIC(8,0))
        LEFT JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mc.Pro_ID
        LEFT JOIN M_ServiceSubscription ss WITH (NOLOCK) ON ss.Pro_ID = mc.Pro_ID AND ss.Comp_ID = p.Comp_Id AND ss.IsActive = 1 AND ss.IsDelete = 0
            AND (mc.Series_Order > ss.start_order OR (mc.Series_Order = ss.start_order AND mc.Series_Serial >= ss.start_series))
            AND (mc.Series_Order < ss.end_order OR (mc.Series_Order = ss.end_order AND mc.Series_Serial <= ss.end_series))
        LEFT JOIN M_Service s WITH (NOLOCK) ON s.Service_ID = ss.Service_ID
        WHERE p.Comp_Id = @Comp_Id
          AND p.Status = 'Success'
    ) AS U;

    ---------------------------------------------------------
    -- FILTER TRANSACTIONS BY DATE AND SEARCH / DUPLICATE RULE
    ---------------------------------------------------------
    -- Normalized search parameter: check if search is provided
    DECLARE @HasSearch BIT = 0;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> '' AND @Search <> 'null'
    BEGIN
        SET @HasSearch = 1;
    END

    SELECT *
    INTO #FilteredTransactions
    FROM (
        SELECT 
            CompanyName, ProductName, CompleteCode, MobileNumber, Point, NetPayout, TransactionID, EnquiryTransactionDate, TransactionType, AssignPoint, WornPoint, ModeOfVerification, Location, ServiceName, Comp_Id, ConsumerName,
            CASE 
                WHEN TransactionType = 'PAYOUT' 
                     AND ((PrevReqDate IS NOT NULL AND DATEDIFF(SECOND, PrevReqDate, EnquiryTransactionDate) <= 300)
                          OR (NextReqDate IS NOT NULL AND DATEDIFF(SECOND, EnquiryTransactionDate, NextReqDate) <= 300))
                THEN 1 
                ELSE 0 
            END AS IsDuplicatePayout
        FROM #RawTransactions
    ) U
    WHERE EnquiryTransactionDate >= @StartDate
      AND EnquiryTransactionDate <  @EndDate
      AND (
          -- If Search is provided: show all matching history for this search query
          (@HasSearch = 1 AND (
              MobileNumber LIKE '%' + @Search + '%' OR
              ConsumerName LIKE '%' + @Search + '%' OR
              CompleteCode LIKE '%' + @Search + '%' OR
              TransactionID LIKE '%' + @Search + '%'
          ))
          OR
          -- If Search is NOT provided: show only duplicate payouts
          (@HasSearch = 0 AND IsDuplicatePayout = 1)
      );

    ---------------------------------------------------------
    -- PAGINATION AND OUTPUT
    ---------------------------------------------------------
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY EnquiryTransactionDate DESC, TransactionID DESC) AS RN
    INTO #PagedReport
    FROM #FilteredTransactions;

    IF @IsExport = 1
    BEGIN
        SELECT
            CompanyName, ProductName, CompleteCode, MobileNumber, Point, NetPayout, TransactionID, EnquiryTransactionDate, TransactionType, AssignPoint, WornPoint, ModeOfVerification, Location, ServiceName
        FROM #PagedReport
        ORDER BY RN;
    END
    ELSE
    BEGIN
        SELECT
            CompanyName, ProductName, CompleteCode, MobileNumber, Point, NetPayout, TransactionID, EnquiryTransactionDate, TransactionType, AssignPoint, WornPoint, ModeOfVerification, Location, ServiceName
        FROM #PagedReport
        WHERE RN BETWEEN @Offset + 1 AND @Offset + @Limit
        ORDER BY RN;

        ---------------------------------------------------------
        -- META
        ---------------------------------------------------------
        SELECT
            COUNT(*) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #PagedReport;
    END
END
GO
