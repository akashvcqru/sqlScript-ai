USE [Vcqru]
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_FillThreeCombinedActivityReports_AllCompanies_AI]
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 1. Fetch All Active Companies
    ---------------------------------------------------------
    DECLARE @Companies TABLE
    (
        ID INT IDENTITY(1,1),
        Comp_ID VARCHAR(50),
        Comp_Name NVARCHAR(250)
    );

    INSERT INTO @Companies (Comp_ID, Comp_Name)
    SELECT DISTINCT Comp_ID, Comp_Name
    FROM Comp_Reg WITH (NOLOCK)
    WHERE ISNULL(IsDelete, 0) = 0
      AND Status = 1;

    DECLARE
        @i INT = 1,
        @MaxID INT,
        @Comp_ID VARCHAR(50),
        @Comp_Name NVARCHAR(250);

    SET @MaxID = (SELECT MAX(ID) FROM @Companies);

    ---------------------------------------------------------
    -- 2. Loop Through Companies One by One
    ---------------------------------------------------------
    WHILE @i <= @MaxID
    BEGIN
        SELECT 
            @Comp_ID = Comp_ID,
            @Comp_Name = Comp_Name
        FROM @Companies
        WHERE ID = @i;

        IF @Comp_ID IS NOT NULL
        BEGIN
            BEGIN TRY
                PRINT 'Processing Company [' + CAST(@i AS VARCHAR) + '/' + CAST(@MaxID AS VARCHAR) + ']: ' + ISNULL(@Comp_Name, '') + ' (' + @Comp_ID + ')';

                ---------------------------------------------------------
                -- A. Process Codes Activity Report (Point Earned)
                ---------------------------------------------------------
                IF OBJECT_ID('tempdb..#TempCodesActivity') IS NOT NULL DROP TABLE #TempCodesActivity;

                CREATE TABLE #TempCodesActivity (
                    Row_id          BIGINT,
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
                EXEC dbo.SP_BL_GetCodesActivityReport_Combined_AI
                    @Comp_Id    = @Comp_ID,
                    @datePreset = 'ALL',
                    @IsExport   = 1;

                DELETE FROM dbo.tbl_BL_CodesActivityReport_AI WHERE Comp_ID = @Comp_ID;

                INSERT INTO dbo.tbl_BL_CodesActivityReport_AI
                (
                    Row_id, Comp_ID, UniqueCode, Enq_Date, Dial_Mode, ConsumerName, MobileNo,
                    State, City, Pro_Name, Points, Result, Latitude, Longitude,
                    AssignPoint, WornPoint, ReferralPoints
                )
                SELECT 
                    Row_id, @Comp_ID, UniqueCode, Enq_Date, Dial_Mode, ConsumerName, MobileNo,
                    State, City, Pro_Name, Points, Result, Latitude, Longitude,
                    AssignPoint, WornPoint, ReferralPoints
                FROM #TempCodesActivity;

                DECLARE @ActivityCount INT = @@ROWCOUNT;

                ---------------------------------------------------------
                -- B. Process Payment Claim Report (Point Claimed)
                ---------------------------------------------------------
                IF OBJECT_ID('tempdb..#TempPaymentClaim') IS NOT NULL DROP TABLE #TempPaymentClaim;

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
                EXEC dbo.SP_BL_GetPaymentClaimReport
                    @Comp_Id    = @Comp_ID,
                    @datePreset = 'ALL',
                    @IsExport   = 1;

                DELETE FROM dbo.tbl_BL_PaymentClaimReport_AI WHERE Comp_ID = @Comp_ID;

                INSERT INTO dbo.tbl_BL_PaymentClaimReport_AI
                (
                    Row_id, Comp_ID, Comp_Name, Claim_date, Mobileno, Points, PointsValue,
                    tdsAmount, tdsper, ConsumerName, City, Pincode, State, Account_No,
                    Account_HolderNm, BankName, IFSC_Code, PaymentStatus, BankRefID,
                    TransactionDate, PaymentRemarks, Claim_Status, vendor_comment, action_date, GiftName
                )
                SELECT 
                    Claim_id, Comp_ID, Comp_Name, Claim_date, Mobileno, Points, PointsValue,
                    tdsAmount, tdsper, ConsumerName, City, Pincode, State, Account_No,
                    Account_HolderNm, BankName, IFSC_Code, PaymentStatus, BankRefID,
                    TransactionDate, PaymentRemarks, Claim_Status, vendor_comment, action_date, GiftName
                FROM #TempPaymentClaim;

                DECLARE @ClaimCount INT = @@ROWCOUNT;

                ---------------------------------------------------------
                -- C. Process UPI Payout Report (Point Paid)
                ---------------------------------------------------------
                IF OBJECT_ID('tempdb..#TempUPIPayout') IS NOT NULL DROP TABLE #TempUPIPayout;

                CREATE TABLE #TempUPIPayout (
                    tblUPITransactionDetailsID BIGINT,
                    Comp_ID       VARCHAR(50),
                    Comp_Name     NVARCHAR(250),
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
                EXEC dbo.GetUPIpayoutRportBL_AI_FillData
                    @Compid     = @Comp_ID,
                    @datePreset = 'ALL',
                    @IsExport   = 1;

                DELETE FROM dbo.tbl_BL_UPIPayoutReport_AI WHERE Comp_ID = @Comp_ID;

                INSERT INTO dbo.tbl_BL_UPIPayoutReport_AI
                (
                    tblUPITransactionDetailsID, Comp_ID, ConsumerName, MobileNo, Code1, Code2,
                    UPI_Id, OldBal, Amount, FinalPayment, tdsAmount, tdsper, ChargedAmount,
                    GstAmount, NewBal, OrderId, BankStatus, BankRemark, ReqDate, FinalStatus, FinalRemark
                )
                SELECT 
                    tblUPITransactionDetailsID, Comp_ID, ConsumerName, MobileNo, Code1, Code2,
                    UPI_Id, OldBal, Amount, FinalPayment, tdsAmount, tdsper, ChargedAmount,
                    GstAmount, NewBal, OrderId, BankStatus, BankRemark, ReqDate, FinalStatus, FinalRemark
                FROM #TempUPIPayout;

                DECLARE @PayoutCount INT = @@ROWCOUNT;

                ---------------------------------------------------------
                -- D. Log Execution Status into TempDataSyncLog
                ---------------------------------------------------------
                IF EXISTS (
                    SELECT 1 
                    FROM dbo.TempDataSyncLog 
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE)
                )
                BEGIN
                    UPDATE dbo.TempDataSyncLog
                    SET 
                        CodeActivityCount = @ActivityCount,
                        PayoutReportCount = @PayoutCount,
                        Status = 'Success',
                        ErrorMessage = NULL,
                        SyncDateTime = GETDATE()
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE);
                END
                ELSE
                BEGIN
                    INSERT INTO dbo.TempDataSyncLog
                    (
                        Comp_ID,
                        Comp_Name,
                        CodeActivityCount,
                        PayoutReportCount,
                        Status,
                        SyncDateTime
                    )
                    VALUES
                    (
                        @Comp_ID,
                        @Comp_Name,
                        @ActivityCount,
                        @PayoutCount,
                        'Success',
                        GETDATE()
                    );
                END
            END TRY
            BEGIN CATCH
                DECLARE @ErrorMsg NVARCHAR(1000) = ERROR_MESSAGE();
                PRINT 'Error Processing Company ' + ISNULL(@Comp_Name, '') + ' (' + @Comp_ID + '): ' + @ErrorMsg;

                IF EXISTS (
                    SELECT 1 
                    FROM dbo.TempDataSyncLog 
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE)
                )
                BEGIN
                    UPDATE dbo.TempDataSyncLog
                    SET 
                        Status = 'Failed',
                        ErrorMessage = LEFT(@ErrorMsg, 1000),
                        SyncDateTime = GETDATE()
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE);
                END
                ELSE
                BEGIN
                    INSERT INTO dbo.TempDataSyncLog
                    (
                        Comp_ID,
                        Comp_Name,
                        Status,
                        ErrorMessage,
                        SyncDateTime
                    )
                    VALUES
                    (
                        @Comp_ID,
                        @Comp_Name,
                        'Failed',
                        LEFT(@ErrorMsg, 1000),
                        GETDATE()
                    );
                END
            END CATCH
        END

        SET @i = @i + 1;
    END
END
GO
