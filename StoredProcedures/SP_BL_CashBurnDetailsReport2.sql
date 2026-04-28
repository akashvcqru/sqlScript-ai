/****** Object:  StoredProcedure [dbo].[SP_BL_CashBurnDetailsReport2]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_BL_CashBurnDetailsReport2]
(
    @Comp_Id     NVARCHAR(50),
    @FromDate DATETIME ,
    @Page  INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT =NULL,
    @Search NVARCHAR(30) = NULL 
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- USERS
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Users') IS NOT NULL DROP TABLE #Users;

    SELECT
        V.M_ConsumerId,
        MC.ConsumerName,
        MC.MobileNo
    INTO #Users
    FROM tbl_VendorViseKYCStatus V
    JOIN M_Consumer MC ON MC.M_ConsumerId = V.M_ConsumerId
    WHERE V.Comp_Id = @Comp_Id
      AND MC.IsDelete = '0'
      AND (
            @Search IS NULL
         OR LTRIM(RTRIM(@Search)) = ''
         OR REPLACE(MC.MobileNo,' ','') LIKE '%' + REPLACE(@Search,' ','') + '%'
      );

    ---------------------------------------------------------
    -- UPI DATA
    ---------------------------------------------------------
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
      AND ReqDate >= @FromDate
      AND ReqDate < DATEADD(DAY, 1, @FromDate)
    GROUP BY
        M_ConsumerId, tdsper, OrderId, CAST(ReqDate AS DATE)

    UNION ALL

    SELECT
        M_CounserID,
        0,
        TransctionNumber,
        CAST(TransactionDate AS DATE),
        SUM(Amount),
        0
    FROM Transactions
    WHERE 'Comp-' + CAST(CompId AS VARCHAR) = @Comp_Id
      AND Issuccess = 1
      AND TransactionDate >= @FromDate
      AND TransactionDate < DATEADD(DAY, 1, @FromDate)
    GROUP BY
        M_CounserID, TransctionNumber, CAST(TransactionDate AS DATE);

    ---------------------------------------------------------
    -- SCAN DATA
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Scan') IS NOT NULL DROP TABLE #Scan;

    SELECT
        BLE.M_ConsumerId,
        CAST(BLE.UpdateDate AS DATE) AS ReportDate,
        SUM(BLE.Points) AS PointsEarned
    INTO #Scan
    FROM BLoyaltyPointsEarned BLE
    WHERE BLE.CompId = @Comp_Id
      AND BLE.UpdateDate >= @FromDate
      AND BLE.UpdateDate < DATEADD(DAY, 1, @FromDate)
    GROUP BY
        BLE.M_ConsumerId,
        CAST(BLE.UpdateDate AS DATE)

    UNION ALL

    SELECT
        U.M_ConsumerId,
        @FromDate,
        0
    FROM #UPI U
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM BLoyaltyPointsEarned BLE
        WHERE BLE.M_ConsumerId = U.M_ConsumerId
          AND BLE.CompId = @Comp_Id
          AND BLE.UpdateDate >= @FromDate
          AND BLE.UpdateDate < DATEADD(DAY, 1, @FromDate)
    );

    ---------------------------------------------------------
    -- FACT TABLE
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#Fact') IS NOT NULL DROP TABLE #Fact;

    SELECT
        U.M_ConsumerId,
        U.ConsumerName,
        U.MobileNo,
        S.ReportDate,
        S.PointsEarned,
        ISNULL(UPI.UPIAmount,0) AS CashTransferAmount,
        ISNULL(UPI.UPITDS,0) AS TDSAmount,
        UPI.TdsPercentage,
        UPI.OrderId
    INTO #Fact
    FROM #Scan S
    LEFT JOIN #UPI UPI ON UPI.M_ConsumerId = S.M_ConsumerId
    JOIN #Users U ON U.M_ConsumerId = S.M_ConsumerId;

    ---------------------------------------------------------
    -- FINAL RESULT
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT
            M_ConsumerId,
            ConsumerName,
            MobileNo,
            ReportDate,
            PointsEarned,
            CashTransferAmount,
            TDSAmount,
            TdsPercentage,
            OrderId
        FROM #Fact
        ORDER BY ConsumerName;
    END
    ELSE
    BEGIN
        SELECT
            M_ConsumerId,
            ConsumerName,
            MobileNo,
            ReportDate,
            PointsEarned,
            CashTransferAmount,
            TDSAmount,
            TdsPercentage,
            OrderId
        FROM #Fact
        ORDER BY ConsumerName
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #Fact;
    END
END
GO
