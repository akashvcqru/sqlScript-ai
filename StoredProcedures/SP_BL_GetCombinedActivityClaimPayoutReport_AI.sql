USE [Vcqru]
GO

/****** Object:  StoredProcedure [dbo].[SP_BL_GetCombinedActivityClaimPayoutReport_AI]    Script Date: 8/6/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCombinedActivityClaimPayoutReport_AI]
(
    @CompId     VARCHAR(50),
    @MobileNo   VARCHAR(50),
    @Page       INT          = 1,
    @Limit      INT          = 50,
    @IsExport   BIT          = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Pagination safety defaults (Default Limit = 3)
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 3;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Clean up Temp Tables if exist
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#TempCodesActivity') IS NOT NULL DROP TABLE #TempCodesActivity;
    IF OBJECT_ID('tempdb..#TempPaymentClaim') IS NOT NULL DROP TABLE #TempPaymentClaim;
    IF OBJECT_ID('tempdb..#TempUPIPayout') IS NOT NULL DROP TABLE #TempUPIPayout;
    IF OBJECT_ID('tempdb..#CombinedResult') IS NOT NULL DROP TABLE #CombinedResult;

    ---------------------------------------------------------
    -- 1. Temp Table for SP_BL_GetCodesActivityReport_AI
    ---------------------------------------------------------
    CREATE TABLE #TempCodesActivity (
        UniqueCode      VARCHAR(100),
        Enq_Date        DATETIME,
        Dial_Mode       VARCHAR(50),
        ConsumerName    NVARCHAR(150),
        MobileNo        VARCHAR(50),
        State           NVARCHAR(100),
        City            NVARCHAR(100),
        Pro_Name        NVARCHAR(200),
        Points          DECIMAL(18,2),
        Result          VARCHAR(50),
        Latitude        VARCHAR(50),
        Longitude       VARCHAR(50),
        AssignPoint     DECIMAL(18,2),
        WornPoint       DECIMAL(18,2),
        ReferralPoints  DECIMAL(18,2)
    );

    INSERT INTO #TempCodesActivity
    EXEC [dbo].[SP_BL_GetCodesActivityReport_Combined_AI]
        @Comp_Id    = @CompId,
        @datePreset = 'ALL',
        @IsExport   = 1,
        @Search     = @MobileNo;

    ---------------------------------------------------------
    -- 2. Temp Table for SP_BL_GetPaymentClaimReport
    ---------------------------------------------------------
    CREATE TABLE #TempPaymentClaim (
        Comp_ID          VARCHAR(50),
        Comp_Name        NVARCHAR(250),
        Claim_id         BIGINT,
        Claim_date       DATETIME,
        Mobileno         VARCHAR(50),
        Points           DECIMAL(18,2),
        PointsValue      DECIMAL(18,2),
        tdsAmount        DECIMAL(18,2),
        tdsper           DECIMAL(18,2),
        ConsumerName     NVARCHAR(250),
        City             NVARCHAR(100),
        Pincode          NVARCHAR(50),
        State            NVARCHAR(100),
        Account_No       NVARCHAR(100),
        Account_HolderNm NVARCHAR(250),
        BankName         NVARCHAR(250),
        IFSC_Code        NVARCHAR(50),
        PaymentStatus    NVARCHAR(50),
        BankRefID        NVARCHAR(100),
        TransactionDate  NVARCHAR(100),
        PaymentRemarks   NVARCHAR(MAX),
        Claim_Status     NVARCHAR(50),
        vendor_comment   NVARCHAR(MAX),
        action_date      DATETIME,
        GiftName         NVARCHAR(250)
    );

    INSERT INTO #TempPaymentClaim
    EXEC [dbo].[SP_BL_GetPaymentClaimReport]
        @Comp_Id    = @CompId,
        @datePreset = 'ALL',
        @IsExport   = 1,
        @search     = @MobileNo;

    ---------------------------------------------------------
    -- 3. Temp Table for GetUPIpayoutRportBL_AI
    ---------------------------------------------------------
    CREATE TABLE #TempUPIPayout (
        ConsumerName  NVARCHAR(250),
        MobileNo      VARCHAR(50),
        Code1         VARCHAR(50),
        Code2         VARCHAR(50),
        UPI_Id        NVARCHAR(100),
        OldBal        DECIMAL(18,2),
        Amount        DECIMAL(18,2),
        FinalPayment  DECIMAL(18,2),
        tdsAmount     DECIMAL(18,2),
        tdsper        DECIMAL(18,2),
        ChargedAmount DECIMAL(18,2),
        GstAmount     DECIMAL(18,2),
        NewBal        DECIMAL(18,2),
        OrderId       NVARCHAR(100),
        BankStatus    NVARCHAR(50),
        BankRemark    NVARCHAR(MAX),
        ReqDate       DATETIME,
        FinalStatus   NVARCHAR(500),
        FinalRemark   NVARCHAR(MAX)
    );

    INSERT INTO #TempUPIPayout
    EXEC [dbo].[GetUPIpayoutRportBL_AI]
        @Compid     = @CompId,
        @datePreset = 'ALL',
        @MobileNo   = @MobileNo,
        @IsExport   = 1;

    ---------------------------------------------------------
    -- 4. Combine Results into Fourth Temp Table
    ---------------------------------------------------------
    CREATE TABLE #CombinedResult (
        [Type]       NVARCHAR(50),
        [Points]     DECIMAL(18,2),
        [Date]       DATETIME,
        [UniqueCode] NVARCHAR(100),
        [Pro_Name]   NVARCHAR(200),
        [Result]     NVARCHAR(50)
    );

    INSERT INTO #CombinedResult ([Type], [Points], [Date], [UniqueCode], [Pro_Name], [Result])
    SELECT 
        'Point Earned'              AS [Type],
        ABS(ISNULL(WornPoint, 0))   AS [Points],
        Enq_Date                    AS [Date],
        ISNULL(UniqueCode, '')      AS [UniqueCode],
        ISNULL(Pro_Name, '')        AS [Pro_Name],
        ISNULL(Result, '')          AS [Result]
    FROM #TempCodesActivity WHERE [Result] = 'Verified'

    UNION ALL

    SELECT 
        'Point Claimed'             AS [Type],
        -1 * ABS(ISNULL(Points, 0)) AS [Points],
        Claim_date                  AS [Date],
        ''                          AS [UniqueCode],
        ''                          AS [Pro_Name],
        ISNULL(PaymentStatus, '')   AS [Result]
    FROM #TempPaymentClaim where PaymentStatus = 'Success'

    UNION ALL

    SELECT 
        'Point Paid'                AS [Type],
        -1 * ABS(ISNULL(Amount, 0)) AS [Points],
        ReqDate                     AS [Date],
        ISNULL(Code1, '') + ISNULL(Code2, '') AS [UniqueCode],
        ''                          AS [Pro_Name],
        ISNULL(BankStatus, '')      AS [Result]
    FROM #TempUPIPayout WHERE BankStatus = 'Success' and code1 >0;

    ---------------------------------------------------------
    -- 5. Final Output with Pagination & Running Balance
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalCalculatedResult') IS NOT NULL DROP TABLE #FinalCalculatedResult;

    SELECT 
        [Type],
        [Points],
        [Date],
        [UniqueCode],
        [Pro_Name],
        [Result],
        SUM([Points]) OVER (
            ORDER BY [Date] ASC, [UniqueCode] ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS [RunningBalance]
    INTO #FinalCalculatedResult
    FROM #CombinedResult;

    IF @IsExport = 1
    BEGIN
        SELECT 
            [Type],
            [Points],
            [Date],
            [UniqueCode],
            [Pro_Name],
            [Result],
            [RunningBalance]
        FROM #FinalCalculatedResult
        ORDER BY [Date] DESC;
    END
    ELSE
    BEGIN
        -- Paginated records
        SELECT 
            [Type],
            [Points],
            [Date],
            [UniqueCode],
            [Pro_Name],
            [Result],
            [RunningBalance]
        FROM #FinalCalculatedResult
        ORDER BY [Date] DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Metadata result set
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalCalculatedResult;
    END
END
GO
