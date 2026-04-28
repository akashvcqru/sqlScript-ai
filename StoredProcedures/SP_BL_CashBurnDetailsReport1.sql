/****** Object:  StoredProcedure [dbo].[SP_BL_CashBurnDetailsReport1]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_BL_CashBurnDetailsReport1]
(
    @Comp_Id     NVARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Page  INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT =NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------------
    -- 1️⃣ Date Range Fix (NO CAST)
    ------------------------------------------------------------
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize datePreset
    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @Win NVARCHAR(50) = @datePreset;

    -- Explicit date range overrides TimeWindow
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1; -- Monday start

        IF (@Win = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@Win = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@Win = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);
            
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END

        ELSE -- ALL / NULL
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    ------------------------------------------------------------
    -- 2️⃣ USERS (MASTER)
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Users') IS NOT NULL DROP TABLE #Users;

    SELECT
        V.M_ConsumerId,
        MC.ConsumerName,
        MC.MobileNo
    INTO #Users
    FROM tbl_VendorViseKYCStatus V
    JOIN M_Consumer MC ON MC.M_ConsumerId = V.M_ConsumerId
    WHERE V.Comp_Id = @Comp_Id
      AND MC.IsDelete = '0';

    ------------------------------------------------------------
    -- 3️⃣ DATE-WISE SCANS
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Scan') IS NOT NULL DROP TABLE #Scan;

    ------------------------------------------------------------
    -- 5️⃣ DATE-WISE UPI
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#UPI') IS NOT NULL DROP TABLE #UPI;

    SELECT
        M_ConsumerId,
        tdsper AS TdsPercentage,
        OrderId,
        CAST(ReqDate AS DATE) AS ReportDate,
        SUM(Amount) AS UPIAmount,
        SUM(ISNULL(tdsAmount,0)) AS UPITDS
    INTO #UPI
    FROM tblUPITransactionDetails
    WHERE Comp_Id = @Comp_Id
      AND Status = 'Success'
      AND ReqDate >= @StartDate
      AND ReqDate <  @EndDate
    GROUP BY
        M_ConsumerId,
        tdsper,
        OrderId,
        CAST(ReqDate AS DATE)
    
    UNION ALL

    SELECT M_CounserID,0 AS TdsPercentage,TransctionNumber as OrderId,  CAST(TransactionDate AS DATE) AS ReportDate,SUM(Amount) AS UPIAmount,0  AS UPITDS
     FROM Transactions UPI 
     WHERE 'Comp-' + CAST(UPI.CompId AS VARCHAR) = @Comp_Id
        AND UPI.Issuccess = 1
        AND UPI.TransactionDate >= @StartDate
        AND UPI.TransactionDate < DATEADD(SECOND, 1, @EndDate)
        GROUP BY M_CounserID,TransctionNumber,TransactionDate

    ------------------------------------------------------------
    -- 6️⃣ FINAL FACT TABLE (DATE + USER)
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Fact') IS NOT NULL DROP TABLE #Fact;

    SELECT
        BLE.M_ConsumerId,
        CAST(BLE.UpdateDate AS DATE) AS ReportDate,
        SUM(BLE.Points) AS PointsEarned
    INTO #Scan
    FROM BLoyaltyPointsEarned BLE
    WHERE BLE.CompId = @Comp_Id
      AND BLE.UpdateDate >= @StartDate
      AND BLE.UpdateDate <  @EndDate
    GROUP BY
        BLE.M_ConsumerId,
        CAST(BLE.UpdateDate AS DATE)

    UNION ALL

    SELECT M_ConsumerId , @FromDate as ReportDate , 0  AS PointsEarned FROM #UPI U
    WHERE NOT EXISTS
      (
          SELECT 1
          FROM BLoyaltyPointsEarned BLE
          WHERE BLE.M_ConsumerId = U.M_ConsumerId
            AND BLE.CompId = @Comp_Id
            AND BLE.UpdateDate >= @FromDate
            AND BLE.UpdateDate < DATEADD(DAY, 1, @FromDate)
      );

    -- SCAN FACT
    SELECT
        U.M_ConsumerId,
        U.ConsumerName,
        U.MobileNo,
        S.ReportDate,
        S.PointsEarned,
        ISNULL(UPIAmount, 0) AS CashTransferAmount,
        ISNULL(UPITDS, 0) AS TDSAmount,
        0 AS HasClaim,    
        NULL AS TdsPercentage,
        NULL AS OrderId
    INTO #Fact
    FROM #Scan S
    LEFT JOIN #UPI Up ON up.M_Consumerid = S.M_Consumerid
    JOIN #Users U ON U.M_ConsumerId = S.M_ConsumerId

    ------------------------------------------------------------
    -- 7️⃣ SUMMARY REPORT (LEVEL-1)
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Summary') IS NOT NULL DROP TABLE #Summary;

    SELECT
        ReportDate AS ReportDateSummary,
        SUM(PointsEarned) AS TotalCashEarnAmount,
        SUM(CashTransferAmount) AS TotalCashTransferAmount,
        SUM(TDSAmount) AS TotalTDSAmount,
        COUNT(DISTINCT CASE WHEN HasClaim = 1 THEN M_ConsumerId END) AS TotalRedeemCashUser
    INTO #Summary
    FROM #Fact
    GROUP BY ReportDate
    ORDER BY ReportDate DESC;

    SELECT
        ReportDateSummary,
        TotalCashEarnAmount,
        TotalCashTransferAmount,
        TotalTDSAmount,
        TotalRedeemCashUser
    FROM #Summary
    ORDER BY ReportDateSummary DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END ROWS ONLY;

    IF (@IsExport = 0)
    BEGIN
        SELECT
            COUNT(1) AS TotalRecords,
            @Page    AS CurrentPage,
            @Limit   AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #Summary;
    END
END
GO
