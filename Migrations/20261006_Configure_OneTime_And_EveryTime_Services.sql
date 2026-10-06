-- ============================================================
-- Migration: 20261006_Configure_OneTime_And_EveryTime_Services.sql
-- Purpose  : Configure ONE-TIME vs EVERY-TIME service subscription patterns:
--
--            1. ONE-TIME SERVICES (Product-Level, Single Record in both tables):
--               - SRV1018 (Anti-Counterfeiting)
--               - SRV1021 (Track & Trace)
--               - SRV1023 (E-Warranty)
--               * Rule: Creates 1 record in M_ServiceSubscription and 1 record 
--                 in M_ServiceSubscriptionTrans on the first batch.
--               * Subsequent batches for the same product REUSE the existing 
--                 Subscribe_Id and UPDATE existing records in-place without duplicates.
--
--            2. EVERY-TIME SERVICES (Batch-Level, New Record every time):
--               - SRV1001 (Brand Loyalty)
--               - SRV1005 (Cash Transfer)
--               - SRV1029 (Cashback UPI)
--               - SRV1028 (Instant Payout)
--               * Rule: Always generates a fresh Subscribe_Id from Code_Gen 
--                 and creates new records in both tables for each batch.
-- ============================================================

-- ============================================================
-- 1. Stored Procedure: USP_InsertServiceSettingWarranty_AI (SRV1023 - ONE TIME)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingWarranty_AI]
    @Comp_ID        NVARCHAR(50),
    @Pro_ID         NVARCHAR(50),
    @Service_ID     NVARCHAR(50)   = 'SRV1023',
    @Subscribe_Id   NVARCHAR(50)   = NULL,

    @WarrantyPeriod INT            = 12,          -- Warranty duration in months
    @Frequency      INT            = 1,
    @DateFrom       DATETIME       = NULL,
    @DateTo         DATETIME       = NULL,
    @Comments       NVARCHAR(1000) = NULL,
    @EntryDate      DATETIME       = NULL,

    -- Batch-related fields
    @Batch_No       NVARCHAR(100)  = NULL,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    @MRP            NUMERIC(18, 2) = 0,
    @BatchSize      INT            = NULL,

    -- Optional Points / Cash settings
    @Points         NUMERIC(18, 0) = 0,
    @IsCashConvert  INT            = 0,
    @IsCash         NUMERIC(18, 0) = 0,

    -- Optional explicit series range
    @SeriesStart    VARCHAR(100)   = NULL,
    @SeriesEnd      VARCHAR(100)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Service_ID IS NULL OR LTRIM(RTRIM(@Service_ID)) = ''
        SET @Service_ID = 'SRV1023';

    IF @MRP IS NULL
        SET @MRP = 0;

    -- Sanitize Subscribe_Id: treat empty / whitespace as NULL
    IF LTRIM(RTRIM(ISNULL(@Subscribe_Id, ''))) = ''
        SET @Subscribe_Id = NULL;

    IF @Mfd_Date IS NULL OR LTRIM(RTRIM(@Mfd_Date)) = ''
        SET @Mfd_Date = CONVERT(VARCHAR(50), GETDATE(), 120);

    IF @Exp_Date IS NULL OR LTRIM(RTRIM(@Exp_Date)) = ''
    BEGIN
        IF @DateTo IS NOT NULL
            SET @Exp_Date = CONVERT(VARCHAR(50), @DateTo, 120);
        ELSE IF @WarrantyPeriod IS NOT NULL
            SET @Exp_Date = CONVERT(VARCHAR(50), DATEADD(MONTH, @WarrantyPeriod, GETDATE()), 120);
        ELSE
            SET @Exp_Date = CONVERT(VARCHAR(50), DATEADD(YEAR, 1, GETDATE()), 120);
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Fetch latest plan details from the last inserted record Service_ID wise
        DECLARE @PlanID_Last NVARCHAR(50), 
                @PlanName_Last NVARCHAR(150), 
                @PlanMasterPeriod_Last NUMERIC(18,0), 
                @PlanSalePeriod_Last NUMERIC(18,0), 
                @PlanMasterPrice_Last NUMERIC(18,0), 
                @PlanSalePrice_Last NUMERIC(18,0),
                @IsActive_Last INT,
                @IsDelete_Last INT,
                @IsAdminVerify_Last INT,
                @TransType_Last NVARCHAR(50);

        -- Priority 1: Match Comp_ID, Pro_ID and Service_ID
        SELECT TOP 1 
            @PlanID_Last = Plan_ID, 
            @PlanName_Last = PlanName, 
            @PlanMasterPeriod_Last = PlanMasterPeriod, 
            @PlanSalePeriod_Last = PlanSalePeriod, 
            @PlanMasterPrice_Last = PlanMasterPrice, 
            @PlanSalePrice_Last = PlanSalePrice,
            @IsActive_Last = IsActive,
            @IsDelete_Last = IsDelete,
            @IsAdminVerify_Last = IsAdminVerify,
            @TransType_Last = TransType
        FROM M_ServiceSubscription WITH (NOLOCK)
        WHERE Service_ID = @Service_ID
          AND Comp_ID = @Comp_ID
          AND Pro_ID = @Pro_ID
        ORDER BY EntryDate DESC, Subscribe_Id DESC;

        -- Priority 2: Match Comp_ID and Service_ID
        IF @PlanID_Last IS NULL
        BEGIN
            SELECT TOP 1 
                @PlanID_Last = Plan_ID, 
                @PlanName_Last = PlanName, 
                @PlanMasterPeriod_Last = PlanMasterPeriod, 
                @PlanSalePeriod_Last = PlanSalePeriod, 
                @PlanMasterPrice_Last = PlanMasterPrice, 
                @PlanSalePrice_Last = PlanSalePrice,
                @IsActive_Last = IsActive,
                @IsDelete_Last = IsDelete,
                @IsAdminVerify_Last = IsAdminVerify,
                @TransType_Last = TransType
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Service_ID = @Service_ID
              AND Comp_ID = @Comp_ID
            ORDER BY EntryDate DESC, Subscribe_Id DESC;
        END

        -- Priority 3: Match Service_ID overall
        IF @PlanID_Last IS NULL
        BEGIN
            SELECT TOP 1 
                @PlanID_Last = Plan_ID, 
                @PlanName_Last = PlanName, 
                @PlanMasterPeriod_Last = PlanMasterPeriod, 
                @PlanSalePeriod_Last = PlanSalePeriod, 
                @PlanMasterPrice_Last = PlanMasterPrice, 
                @PlanSalePrice_Last = PlanSalePrice,
                @IsActive_Last = IsActive,
                @IsDelete_Last = IsDelete,
                @IsAdminVerify_Last = IsAdminVerify,
                @TransType_Last = TransType
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Service_ID = @Service_ID
            ORDER BY EntryDate DESC, Subscribe_Id DESC;
        END

        -- Set defaults if no previous record exists
        SET @PlanID_Last = ISNULL(@PlanID_Last, 'PLAN_WARRANTY');
        SET @PlanName_Last = ISNULL(@PlanName_Last, 'Warranty Subscription');
        SET @PlanMasterPeriod_Last = ISNULL(@WarrantyPeriod, ISNULL(@PlanMasterPeriod_Last, 12));
        SET @PlanSalePeriod_Last = ISNULL(@WarrantyPeriod, ISNULL(@PlanSalePeriod_Last, 12));
        SET @PlanMasterPrice_Last = ISNULL(@PlanMasterPrice_Last, 0);
        SET @PlanSalePrice_Last = ISNULL(@PlanSalePrice_Last, 0);
        SET @IsActive_Last = ISNULL(@IsActive_Last, 1);
        SET @IsDelete_Last = ISNULL(@IsDelete_Last, 0);
        SET @IsAdminVerify_Last = ISNULL(@IsAdminVerify_Last, 1);
        SET @TransType_Last = ISNULL(@TransType_Last, 'Service');

        -- 2. ONE TIME PATTERN: Look for existing subscription for this product first
        IF @Subscribe_Id IS NULL
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID
            ORDER BY EntryDate DESC;
        END

        -- If still NULL, generate new Subscribe_Id for the first time
        IF @Subscribe_Id IS NULL
        BEGIN
            DECLARE @PrPrefix VARCHAR(50), @PrStart BIGINT;
            SELECT TOP 1 @PrPrefix = PrPrefix, @PrStart = PrStart 
            FROM Code_Gen WITH (UPDLOCK, HOLDLOCK) 
            WHERE Prfor = 'Subscription';

            IF @PrPrefix IS NULL
                SET @Subscribe_Id = 'SSI' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
            ELSE
            BEGIN
                SET @Subscribe_Id = @PrPrefix + CAST(@PrStart AS VARCHAR(50));
                UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'Subscription' AND PrPrefix = @PrPrefix;
            END
        END

        -- 2.1 Check if this Batch already exists in T_Pro (e.g. created via AddAssignLabelToProduct)
        DECLARE @ExistingTPro_RowID BIGINT = NULL;
        IF @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            SELECT TOP 1 @ExistingTPro_RowID = Row_ID 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;
        END

        -- 3. Parse and Validate Series Range if provided
        DECLARE @StartOrder INT = NULL, @StartSerial INT = NULL;
        DECLARE @EndOrder INT = NULL, @EndSerial INT = NULL;

        IF ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> ''
        BEGIN
            -- Parse SeriesStart (handles "0000-0400" or "BP17-0000-0400")
            IF @SeriesStart LIKE '%-%-%'
            BEGIN
                DECLARE @StartPrefix VARCHAR(50) = LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1);
                IF UPPER(LTRIM(RTRIM(@StartPrefix))) <> UPPER(LTRIM(RTRIM(@Pro_ID)))
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Enter series proid not match Selected product' AS message;
                    RETURN;
                END
                DECLARE @StartP2 VARCHAR(50) = SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart));
                SET @StartOrder = TRY_CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
            END
            ELSE IF @SeriesStart LIKE '%-%'
            BEGIN
                SET @StartOrder = TRY_CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
            END

            -- Parse SeriesEnd (handles "0000-0450" or "BP17-0000-0450")
            IF @SeriesEnd LIKE '%-%-%'
            BEGIN
                DECLARE @EndPrefix VARCHAR(50) = LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1);
                IF UPPER(LTRIM(RTRIM(@EndPrefix))) <> UPPER(LTRIM(RTRIM(@Pro_ID)))
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Enter series proid not match Selected product' AS message;
                    RETURN;
                END
                DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
                SET @EndOrder = TRY_CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
                SET @EndSerial = TRY_CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
            END
            ELSE IF @SeriesEnd LIKE '%-%'
            BEGIN
                SET @EndOrder = TRY_CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
                SET @EndSerial = TRY_CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
            END

            IF @StartOrder IS NULL OR @StartSerial IS NULL OR @EndOrder IS NULL OR @EndSerial IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid series format in SeriesStart/SeriesEnd. Expected format: 0000-0400 or Prefix-0000-0400.' AS message;
                RETURN;
            END

            IF @StartOrder > @EndOrder OR (@StartOrder = @EndOrder AND @StartSerial > @EndSerial)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'SeriesStart (' + @SeriesStart + ') cannot be greater than SeriesEnd (' + @SeriesEnd + ').' AS message;
                RETURN;
            END

            -- Validate that both Start code and End code exist in M_Code
            DECLARE @StartCodeExists BIT = 0, @EndCodeExists BIT = 0;

            IF @Comp_ID = 'Comp-1693'
            BEGIN
                IF EXISTS (SELECT 1 FROM M_Code_PFL WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @StartOrder AND Series_Serial = @StartSerial)
                    SET @StartCodeExists = 1;
                IF EXISTS (SELECT 1 FROM M_Code_PFL WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @EndOrder AND Series_Serial = @EndSerial)
                    SET @EndCodeExists = 1;
            END
            ELSE
            BEGIN
                IF EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @StartOrder AND Series_Serial = @StartSerial)
                    SET @StartCodeExists = 1;
                IF EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @EndOrder AND Series_Serial = @EndSerial)
                    SET @EndCodeExists = 1;
            END

            IF @StartCodeExists = 0 OR @EndCodeExists = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                RETURN;
            END

            -- Check code existence and batch status in M_Code (or M_Code_PFL)
            DECLARE @TotalSeriesCount INT = 0;
            DECLARE @UnassignedBatchCount INT = 0;
            DECLARE @DistinctBatchCount INT = 0;
            DECLARE @AssignedBatchNo NVARCHAR(50) = NULL;

            IF @Comp_ID = 'Comp-1693'
            BEGIN
                SELECT 
                    @TotalSeriesCount = COUNT(1),
                    @UnassignedBatchCount = SUM(CASE WHEN Batch_No IS NULL OR LTRIM(RTRIM(Batch_No)) = '' THEN 1 ELSE 0 END),
                    @DistinctBatchCount = COUNT(DISTINCT CASE WHEN Batch_No IS NOT NULL AND LTRIM(RTRIM(Batch_No)) <> '' THEN Batch_No END),
                    @AssignedBatchNo = MAX(Batch_No)
                FROM M_Code_PFL WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END
            ELSE
            BEGIN
                SELECT 
                    @TotalSeriesCount = COUNT(1),
                    @UnassignedBatchCount = SUM(CASE WHEN Batch_No IS NULL OR LTRIM(RTRIM(Batch_No)) = '' THEN 1 ELSE 0 END),
                    @DistinctBatchCount = COUNT(DISTINCT CASE WHEN Batch_No IS NOT NULL AND LTRIM(RTRIM(Batch_No)) <> '' THEN Batch_No END),
                    @AssignedBatchNo = MAX(Batch_No)
                FROM M_Code WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END

            IF @StartOrder = @EndOrder
            BEGIN
                DECLARE @ExpectedCount INT = (@EndSerial - @StartSerial) + 1;
                IF @TotalSeriesCount < @ExpectedCount
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                    RETURN;
                END
            END

            IF ISNULL(@TotalSeriesCount, 0) = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                RETURN;
            END

            -- Check if any codes in the series range are pending label assignment
            IF ISNULL(@UnassignedBatchCount, 0) > 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'As per given series, label assignment is pending. Please assign labels to product first via Assign Label to Product.' AS message;
                RETURN;
            END

            -- Check if codes span multiple batches
            IF @DistinctBatchCount > 1
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'The specified series range spans multiple batches. Please configure services for one batch range at a time.' AS message;
                RETURN;
            END

            -- Auto-resolve existing T_Pro Row_ID from M_Code.Batch_No (which stores T_Pro.Row_ID)
            IF @ExistingTPro_RowID IS NULL AND @AssignedBatchNo IS NOT NULL
            BEGIN
                SET @ExistingTPro_RowID = TRY_CAST(@AssignedBatchNo AS BIGINT);
            END
        END
        ELSE IF @ExistingTPro_RowID IS NULL AND @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            -- If series not provided, check if batch exists in T_Pro
            SELECT TOP 1 @ExistingTPro_RowID = Row_ID 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = @Pro_ID AND (Batch_No = @Batch_No OR Row_ID = TRY_CAST(@Batch_No AS BIGINT));
        END

        -- 4. ONE TIME PATTERN: Insert or Update M_ServiceSubscription
        IF NOT EXISTS (SELECT 1 FROM M_ServiceSubscription WITH (NOLOCK) WHERE Subscribe_Id = @Subscribe_Id)
        BEGIN
            INSERT INTO M_ServiceSubscription
            (
                Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName,
                PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice,
                DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify,
                TransType, start_order, start_series, end_order, end_series
            )
            VALUES
            (
                @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, @PlanID_Last, @PlanName_Last,
                @PlanMasterPeriod_Last, @PlanSalePeriod_Last, @PlanMasterPrice_Last, @PlanSalePrice_Last,
                ISNULL(@DateFrom, CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE GETDATE() END),
                ISNULL(@DateTo, CASE 
                    WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) 
                    ELSE DATEADD(MONTH, CAST(ISNULL(@WarrantyPeriod, 12) AS INT), GETDATE()) 
                END),
                ISNULL(@EntryDate, GETDATE()), 
                @IsActive_Last, @IsDelete_Last, @IsAdminVerify_Last,
                @TransType_Last, @StartOrder, @StartSerial, @EndOrder, @EndSerial
            );
        END
        ELSE
        BEGIN
            UPDATE M_ServiceSubscription
            SET PlanMasterPeriod = ISNULL(@WarrantyPeriod, PlanMasterPeriod),
                PlanSalePeriod = ISNULL(@WarrantyPeriod, PlanSalePeriod),
                DateFrom = ISNULL(@DateFrom, DateFrom),
                DateTo = ISNULL(@DateTo, DateTo)
            WHERE Subscribe_Id = @Subscribe_Id;
        END

        -- 5. ONE TIME PATTERN: Insert or Update M_ServiceSubscriptionTrans (Single record per product)
        DECLARE @NewSST_Id BIGINT;

        SELECT TOP 1 @NewSST_Id = SST_Id 
        FROM M_ServiceSubscriptionTrans WITH (NOLOCK)
        WHERE Subscribe_Id = @Subscribe_Id 
        ORDER BY Entry_Date DESC;

        IF @NewSST_Id IS NULL
        BEGIN
            INSERT INTO M_ServiceSubscriptionTrans
            (
                Subscribe_Id,
                WarrantyPeriod,
                Points, IsCashConvert, IsCash,
                DateFrom, DateTo,
                Comments, Entry_Date,
                Frequency, IsActive, IsDelete,
                AmtType, Minval, Maxval, totalamont
            )
            VALUES
            (
                @Subscribe_Id,
                ISNULL(@WarrantyPeriod, 12),
                @Points, @IsCashConvert, @IsCash,
                ISNULL(@DateFrom, CASE WHEN ISDATE(@Mfd_Date) = 1 THEN CAST(@Mfd_Date AS DATETIME) ELSE GETDATE() END),
                ISNULL(@DateTo, CASE 
                    WHEN ISDATE(@Exp_Date) = 1 THEN CAST(@Exp_Date AS DATETIME) 
                    ELSE DATEADD(MONTH, ISNULL(@WarrantyPeriod, 12), GETDATE()) 
                END),
                @Comments, ISNULL(@EntryDate, GETDATE()),
                ISNULL(@Frequency, 1), 1, 0,
                'Fixed', 0, 0, 0
            );

            SET @NewSST_Id = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE M_ServiceSubscriptionTrans
            SET WarrantyPeriod = ISNULL(@WarrantyPeriod, WarrantyPeriod),
                DateFrom = ISNULL(@DateFrom, CASE WHEN ISDATE(@Mfd_Date) = 1 THEN CAST(@Mfd_Date AS DATETIME) ELSE DateFrom END),
                DateTo = ISNULL(@DateTo, CASE 
                    WHEN ISDATE(@Exp_Date) = 1 THEN CAST(@Exp_Date AS DATETIME) 
                    WHEN @WarrantyPeriod IS NOT NULL THEN DATEADD(MONTH, @WarrantyPeriod, ISNULL(DateFrom, GETDATE()))
                    ELSE DateTo 
                END),
                Comments = ISNULL(@Comments, Comments),
                Frequency = ISNULL(@Frequency, Frequency),
                Points = ISNULL(@Points, Points),
                IsCashConvert = ISNULL(@IsCashConvert, IsCashConvert),
                IsCash = ISNULL(@IsCash, IsCash)
            WHERE SST_Id = @NewSST_Id;
        END

        -- 6. Update T_Pro metadata only if Batch exists (never create a new batch here)
        IF @ExistingTPro_RowID IS NOT NULL
        BEGIN
            UPDATE T_Pro
            SET MRP = ISNULL(@MRP, MRP),
                Mfd_Date = CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE Mfd_Date END,
                Exp_Date = CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE Exp_Date END,
                Comments = ISNULL(@Comments, Comments),
                WarrantyDurationMonth = ISNULL(@WarrantyPeriod, WarrantyDurationMonth),
                IsWarranty = 1,
                Series_Limit = CASE WHEN ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> '' 
                                    THEN CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd) 
                                    ELSE ISNULL(Series_Limit, '') END
            WHERE Row_ID = @ExistingTPro_RowID;
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Warranty service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id, @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO


-- ============================================================
-- 2. Stored Procedure: USP_InsertServiceSettingTracTraceV2_AI (SRV1021 - ONE TIME)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingTracTraceV2_AI]
    @Comp_ID             VARCHAR(50),
    @Pro_ID              VARCHAR(50),
    @Service_ID          VARCHAR(50)    = 'SRV1021',
    @Subscribe_Id        VARCHAR(50)    = NULL,
    @Batch_No            VARCHAR(100)   = NULL,
    @SeriesStart         VARCHAR(100)   = NULL,
    @SeriesEnd           VARCHAR(100)   = NULL,
    @MasterCode          VARCHAR(100)   = NULL,
    @Comments            NVARCHAR(1000) = NULL,
    @EntryDate           DATETIME       = NULL,
    
    -- Dealer Details
    @Dealer_Name         NVARCHAR(150)  = NULL,
    @Dealer_Location     NVARCHAR(150)  = NULL,
    @Mobile              NVARCHAR(150)  = NULL,
    @Email               NVARCHAR(150)  = NULL,
    @Invoice_Number      NVARCHAR(50)   = NULL,

    -- Additional Metadata
    @SST_Id              BIGINT         = NULL,
    @BatchSize           INT            = NULL,
    @DateFrom            VARCHAR(50)    = NULL,
    @DateTo              VARCHAR(50)    = NULL,
    @MRP                 NUMERIC(18, 2) = NULL,
    @Mfd_Date            VARCHAR(50)    = NULL,
    @Exp_Date            VARCHAR(50)    = NULL,
    @Latitude            NVARCHAR(50)   = NULL,
    @Longitude           NVARCHAR(50)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Service_ID IS NULL OR LTRIM(RTRIM(@Service_ID)) = ''
        SET @Service_ID = 'SRV1021';

    IF @MRP IS NULL
        SET @MRP = 0;

    -- Sanitize Subscribe_Id: treat empty / whitespace as NULL
    IF LTRIM(RTRIM(ISNULL(@Subscribe_Id, ''))) = ''
        SET @Subscribe_Id = NULL;

    IF @Mfd_Date IS NULL OR LTRIM(RTRIM(@Mfd_Date)) = ''
        SET @Mfd_Date = CONVERT(VARCHAR(50), GETDATE(), 120);

    IF @Exp_Date IS NULL OR LTRIM(RTRIM(@Exp_Date)) = ''
    BEGIN
        IF @DateTo IS NOT NULL AND LTRIM(RTRIM(@DateTo)) <> ''
            SET @Exp_Date = @DateTo;
        ELSE
            SET @Exp_Date = CONVERT(VARCHAR(50), DATEADD(YEAR, 1, GETDATE()), 120);
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check if Batch already exists in T_Pro (e.g. created by AddAssignLabelToProduct API)
        DECLARE @ExistingTPro_RowID BIGINT = NULL;
        IF @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            SELECT TOP 1 @ExistingTPro_RowID = Row_ID 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;
        END

        -- 0.1 Parse SeriesStart / SeriesEnd
        DECLARE @StartOrder INT, @StartSerial INT;
        DECLARE @EndOrder   INT, @EndSerial   INT;

        -- 0.2 Automated Range Calculation (if series not provided)
        IF ISNULL(@SeriesStart, '') = '' OR ISNULL(@SeriesEnd, '') = ''
        BEGIN
            IF @BatchSize IS NULL OR @BatchSize <= 0
            BEGIN
                SELECT @BatchSize = BatchSize FROM Pro_Reg WITH (NOLOCK) WHERE Pro_ID = @Pro_ID;
                IF @BatchSize IS NULL OR @BatchSize <= 0
                    SET @BatchSize = 10;
            END

            -- Find the last assigned range from codeassign_tractrac
            DECLARE @LastEndOrder INT, @LastEndSerial INT;
            SELECT TOP 1 
                @LastEndOrder = TRY_CAST(PARSENAME(REPLACE(SeriesEnd, '-', '.'), 2) AS INT),
                @LastEndSerial = TRY_CAST(PARSENAME(REPLACE(SeriesEnd, '-', '.'), 1) AS INT)
            FROM codeassign_tractrac
            WHERE Pro_ID = @Pro_ID AND SeriesEnd IS NOT NULL
            ORDER BY entry_date DESC, ID DESC;

            IF @LastEndOrder IS NULL
            BEGIN
                SELECT TOP 1 @StartOrder = Series_Order, @StartSerial = Series_Serial
                FROM M_Code 
                WHERE Pro_ID = @Pro_ID AND (Batch_No IS NULL OR Batch_No = '' OR (@Batch_No IS NOT NULL AND Batch_No = @Batch_No))
                ORDER BY Series_Order, Series_Serial;
            END
            ELSE
            BEGIN
                SELECT TOP 1 @StartOrder = Series_Order, @StartSerial = Series_Serial
                FROM M_Code 
                WHERE Pro_ID = @Pro_ID 
                  AND (Batch_No IS NULL OR Batch_No = '' OR (@Batch_No IS NOT NULL AND Batch_No = @Batch_No))
                  AND (Series_Order > @LastEndOrder OR (Series_Order = @LastEndOrder AND Series_Serial > @LastEndSerial))
                ORDER BY Series_Order, Series_Serial;
            END

            IF @StartOrder IS NULL
            BEGIN
                SELECT TOP 1 @StartOrder = Series_Order, @StartSerial = Series_Serial
                FROM M_Code 
                WHERE Pro_ID = @Pro_ID
                ORDER BY Series_Order, Series_Serial;
            END

            IF @StartOrder IS NULL
            BEGIN
                SELECT 0 AS success, 'No available codes found in M_Code for this product.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- Calculate End series based on BatchSize
            ;WITH NextBatch AS (
                SELECT TOP (@BatchSize) Series_Order, Series_Serial
                FROM M_Code
                WHERE Pro_ID = @Pro_ID
                  AND (Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
                ORDER BY Series_Order, Series_Serial
            )
            SELECT 
                @EndOrder = MAX(Series_Order),
                @EndSerial = MAX(Series_Serial)
            FROM (SELECT TOP (@BatchSize) * FROM NextBatch ORDER BY Series_Order DESC, Series_Serial DESC) AS LastCode;
            
            IF @EndSerial IS NULL SELECT @EndSerial = MAX(Series_Serial) FROM (SELECT TOP (@BatchSize) * FROM NextBatch) t WHERE Series_Order = @EndOrder;

            SET @SeriesStart = CONCAT(FORMAT(@StartOrder, '0000'), '-', FORMAT(@StartSerial, '0000'));
            SET @SeriesEnd = CONCAT(FORMAT(@EndOrder, '0000'), '-', FORMAT(@EndSerial, '0000'));
        END
        ELSE
        BEGIN
            -- Manual Parsing
            IF @SeriesStart LIKE '%-%-%'
            BEGIN
                DECLARE @StartPrefix VARCHAR(50) = LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1);
                IF UPPER(LTRIM(RTRIM(@StartPrefix))) <> UPPER(LTRIM(RTRIM(@Pro_ID)))
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Enter series proid not match Selected product' AS message;
                    RETURN;
                END
                DECLARE @StartP2 VARCHAR(50) = SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart));
                SET @StartOrder = CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
                SET @StartSerial = CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
            END
            ELSE IF @SeriesStart LIKE '%-%'
            BEGIN
                SET @StartOrder = CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
                SET @StartSerial = CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
            END

            IF @SeriesEnd LIKE '%-%-%'
            BEGIN
                DECLARE @EndPrefix VARCHAR(50) = LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1);
                IF UPPER(LTRIM(RTRIM(@EndPrefix))) <> UPPER(LTRIM(RTRIM(@Pro_ID)))
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Enter series proid not match Selected product' AS message;
                    RETURN;
                END
                DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
                SET @EndOrder = CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
                SET @EndSerial = CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
            END
            ELSE IF @SeriesEnd LIKE '%-%'
            BEGIN
                SET @EndOrder = CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
                SET @EndSerial = CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
            END

            -- Validate that both Start code and End code exist in M_Code
            IF NOT EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @StartOrder AND Series_Serial = @StartSerial)
               OR NOT EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @EndOrder AND Series_Serial = @EndSerial)
            BEGIN
                SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- Check code existence and batch status in M_Code
            DECLARE @TotalSeriesCount INT = 0;
            DECLARE @UnassignedBatchCount INT = 0;
            DECLARE @DistinctBatchCount INT = 0;
            DECLARE @AssignedBatchNo NVARCHAR(50) = NULL;

            SELECT 
                @TotalSeriesCount = COUNT(1),
                @UnassignedBatchCount = SUM(CASE WHEN Batch_No IS NULL OR LTRIM(RTRIM(Batch_No)) = '' THEN 1 ELSE 0 END),
                @DistinctBatchCount = COUNT(DISTINCT CASE WHEN Batch_No IS NOT NULL AND LTRIM(RTRIM(Batch_No)) <> '' THEN Batch_No END),
                @AssignedBatchNo = MAX(Batch_No)
            FROM M_Code WITH (NOLOCK)
            WHERE Pro_ID = @Pro_ID 
              AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                   OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));

            IF @StartOrder = @EndOrder
            BEGIN
                DECLARE @ExpectedRangeCount INT = (@EndSerial - @StartSerial) + 1;
                IF @TotalSeriesCount < @ExpectedRangeCount
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                    RETURN;
                END
            END

            IF ISNULL(@TotalSeriesCount, 0) = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                RETURN;
            END

            -- Check if any codes in the series range are pending label assignment
            IF ISNULL(@UnassignedBatchCount, 0) > 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'As per given series, label assignment is pending. Please assign labels to product first via Assign Label to Product.' AS message;
                RETURN;
            END

            -- Check if codes span multiple batches
            IF @DistinctBatchCount > 1
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'The specified series range spans multiple batches. Please configure services for one batch range at a time.' AS message;
                RETURN;
            END

            -- Auto-resolve existing T_Pro Row_ID from M_Code.Batch_No (which stores T_Pro.Row_ID)
            IF @ExistingTPro_RowID IS NULL AND @AssignedBatchNo IS NOT NULL
            BEGIN
                SET @ExistingTPro_RowID = TRY_CAST(@AssignedBatchNo AS BIGINT);
            END
        END
        
        IF @ExistingTPro_RowID IS NULL AND @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            -- If series not provided, check if batch exists in T_Pro
            SELECT TOP 1 @ExistingTPro_RowID = Row_ID 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = @Pro_ID AND (Batch_No = @Batch_No OR Row_ID = TRY_CAST(@Batch_No AS BIGINT));
        END

        -- 1. MasterCode Resolution & Validation
        -- If MasterCode is not provided, default to the SeriesStart code
        IF ISNULL(@MasterCode, '') = ''
        BEGIN
            SET @MasterCode = @SeriesStart;
        END

        -- Check MasterCode in codeassign_tractrac
        DECLARE @ExistingTracID BIGINT = NULL;
        SELECT TOP 1 @ExistingTracID = ID 
        FROM codeassign_tractrac WITH (NOLOCK) 
        WHERE mastercode = @MasterCode;

        IF @ExistingTracID IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM codeassign_tractrac WITH (NOLOCK) WHERE ID = @ExistingTracID AND Pro_ID <> @Pro_ID)
            BEGIN
                SELECT 0 AS success, CONCAT('Master code ', @MasterCode, ' already exists for another product.') AS message;
                ROLLBACK TRANSACTION; RETURN;
            END
        END

        -- Parse MasterCode parts
        DECLARE @MasterOrd INT = NULL, @MasterSer INT = NULL;
        IF @MasterCode LIKE '%-%-%'
        BEGIN
            DECLARE @MP2 VARCHAR(50) = SUBSTRING(@MasterCode, CHARINDEX('-', @MasterCode) + 1, LEN(@MasterCode));
            SET @MasterOrd = TRY_CAST(LEFT(@MP2, CHARINDEX('-', @MP2) - 1) AS INT);
            SET @MasterSer = TRY_CAST(SUBSTRING(@MP2, CHARINDEX('-', @MP2) + 1, LEN(@MasterCode)) AS INT);
        END
        ELSE IF @MasterCode LIKE '%-%'
        BEGIN
            SET @MasterOrd = TRY_CAST(LEFT(@MasterCode, CHARINDEX('-', @MasterCode) - 1) AS INT);
            SET @MasterSer = TRY_CAST(SUBSTRING(@MasterCode, CHARINDEX('-', @MasterCode) + 1, LEN(@MasterCode)) AS INT);
        END

        -- Check if MasterCode falls inside the batch series
        DECLARE @IsMasterInBatch BIT = 0;
        IF @MasterOrd IS NOT NULL AND @MasterSer IS NOT NULL
        BEGIN
            IF (@MasterOrd > @StartOrder OR (@MasterOrd = @StartOrder AND @MasterSer >= @StartSerial))
               AND (@MasterOrd < @EndOrder OR (@MasterOrd = @EndOrder AND @MasterSer <= @EndSerial))
            BEGIN
                SET @IsMasterInBatch = 1;
            END
        END

        DECLARE @TotalBatchSize INT = @BatchSize;
        IF @IsMasterInBatch = 0 AND @BatchSize IS NOT NULL
        BEGIN
            SET @TotalBatchSize = @BatchSize + 1;
        END

        -- =========================================================================
        -- STEP 2: ONE TIME PATTERN - Resolve Plan & Ensure M_ServiceSubscription
        -- =========================================================================
        DECLARE @PlanID_Last NVARCHAR(50), 
                @PlanName_Last NVARCHAR(150), 
                @PlanMasterPeriod_Last NUMERIC(18,0), 
                @PlanSalePeriod_Last NUMERIC(18,0), 
                @PlanMasterPrice_Last NUMERIC(18,0), 
                @PlanSalePrice_Last NUMERIC(18,0),
                @IsActive_Last INT,
                @IsDelete_Last INT,
                @IsAdminVerify_Last INT,
                @TransType_Last NVARCHAR(50);

        -- Priority 1: Match Comp_ID, Pro_ID and Service_ID
        SELECT TOP 1 
            @PlanID_Last = Plan_ID, 
            @PlanName_Last = PlanName, 
            @PlanMasterPeriod_Last = PlanMasterPeriod, 
            @PlanSalePeriod_Last = PlanSalePeriod, 
            @PlanMasterPrice_Last = PlanMasterPrice, 
            @PlanSalePrice_Last = PlanSalePrice,
            @IsActive_Last = IsActive,
            @IsDelete_Last = IsDelete,
            @IsAdminVerify_Last = IsAdminVerify,
            @TransType_Last = TransType
        FROM M_ServiceSubscription WITH (NOLOCK)
        WHERE Service_ID = @Service_ID
          AND Comp_ID = @Comp_ID
          AND Pro_ID = @Pro_ID
        ORDER BY EntryDate DESC, Subscribe_Id DESC;

        -- Priority 2: Match Comp_ID and Service_ID
        IF @PlanID_Last IS NULL
        BEGIN
            SELECT TOP 1 
                @PlanID_Last = Plan_ID, 
                @PlanName_Last = PlanName, 
                @PlanMasterPeriod_Last = PlanMasterPeriod, 
                @PlanSalePeriod_Last = PlanSalePeriod, 
                @PlanMasterPrice_Last = PlanMasterPrice, 
                @PlanSalePrice_Last = PlanSalePrice,
                @IsActive_Last = IsActive,
                @IsDelete_Last = IsDelete,
                @IsAdminVerify_Last = IsAdminVerify,
                @TransType_Last = TransType
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Service_ID = @Service_ID
              AND Comp_ID = @Comp_ID
            ORDER BY EntryDate DESC, Subscribe_Id DESC;
        END

        -- Priority 3: Match Service_ID overall
        IF @PlanID_Last IS NULL
        BEGIN
            SELECT TOP 1 
                @PlanID_Last = Plan_ID, 
                @PlanName_Last = PlanName, 
                @PlanMasterPeriod_Last = PlanMasterPeriod, 
                @PlanSalePeriod_Last = PlanSalePeriod, 
                @PlanMasterPrice_Last = PlanMasterPrice, 
                @PlanSalePrice_Last = PlanSalePrice,
                @IsActive_Last = IsActive,
                @IsDelete_Last = IsDelete,
                @IsAdminVerify_Last = IsAdminVerify,
                @TransType_Last = TransType
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Service_ID = @Service_ID
            ORDER BY EntryDate DESC, Subscribe_Id DESC;
        END

        -- Default fallback
        SET @PlanID_Last = ISNULL(@PlanID_Last, 'PLAN_DEFAULT');
        SET @PlanName_Last = ISNULL(@PlanName_Last, 'Track & Trace Subscription');
        SET @PlanMasterPeriod_Last = ISNULL(@PlanMasterPeriod_Last, 365);
        SET @PlanSalePeriod_Last = ISNULL(@PlanSalePeriod_Last, 365);
        SET @PlanMasterPrice_Last = ISNULL(@PlanMasterPrice_Last, 0);
        SET @PlanSalePrice_Last = ISNULL(@PlanSalePrice_Last, 0);
        SET @IsActive_Last = ISNULL(@IsActive_Last, 1);
        SET @IsDelete_Last = ISNULL(@IsDelete_Last, 0);
        SET @IsAdminVerify_Last = ISNULL(@IsAdminVerify_Last, 1);
        SET @TransType_Last = ISNULL(@TransType_Last, 'Service');

        -- ONE TIME PATTERN: Check if existing subscription already exists for this product
        IF @Subscribe_Id IS NULL
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID
            ORDER BY EntryDate DESC;
        END

        -- If still NULL, generate fresh Subscribe_Id for the first time
        IF @Subscribe_Id IS NULL
        BEGIN
            DECLARE @PrPrefix VARCHAR(50), @PrStart BIGINT;
            SELECT TOP 1 @PrPrefix = PrPrefix, @PrStart = PrStart 
            FROM Code_Gen WITH (UPDLOCK, HOLDLOCK) 
            WHERE Prfor = 'Subscription';
            
            IF @PrPrefix IS NULL
            BEGIN
                SET @Subscribe_Id = 'SSI' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
            END
            ELSE
            BEGIN
                SET @Subscribe_Id = @PrPrefix + CAST(@PrStart AS VARCHAR(50));
                UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'Subscription' AND PrPrefix = @PrPrefix;
            END

            INSERT INTO M_ServiceSubscription
            (
                Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName,
                PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice,
                DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify,
                TransType, start_order, start_series, end_order, end_series
            )
            VALUES
            (
                @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, @PlanID_Last, @PlanName_Last,
                @PlanMasterPeriod_Last, @PlanSalePeriod_Last, @PlanMasterPrice_Last, @PlanSalePrice_Last,
                ISNULL(TRY_CAST(@DateFrom AS DATETIME), GETDATE()), 
                ISNULL(TRY_CAST(@DateTo AS DATETIME), DATEADD(YEAR, 1, GETDATE())), 
                ISNULL(@EntryDate, GETDATE()), 
                @IsActive_Last, @IsDelete_Last, @IsAdminVerify_Last,
                @TransType_Last, @StartOrder, @StartSerial, @EndOrder, @EndSerial
            );
        END
        ELSE
        BEGIN
            -- ONE TIME REUSE: Update series range boundary on existing subscription
            UPDATE M_ServiceSubscription
            SET end_order = ISNULL(@EndOrder, end_order),
                end_series = ISNULL(@EndSerial, end_series)
            WHERE Subscribe_Id = @Subscribe_Id;
        END

        -- =========================================================================
        -- STEP 3: ONE TIME PATTERN - INSERT OR UPDATE M_ServiceSubscriptionTrans (Single record per product)
        -- =========================================================================
        DECLARE @NewSST_Id BIGINT;

        SELECT TOP 1 @NewSST_Id = SST_Id 
        FROM M_ServiceSubscriptionTrans WITH (NOLOCK)
        WHERE Subscribe_Id = @Subscribe_Id
        ORDER BY Entry_Date DESC;

        IF @NewSST_Id IS NULL
        BEGIN
            INSERT INTO M_ServiceSubscriptionTrans
            (
                Subscribe_Id, DateFrom, DateTo, Comments, Entry_Date,
                Points, IsCashConvert, IsCash, Frequency, IsActive, IsDelete,
                Minval, Maxval, totalamont
            )
            VALUES
            (
                @Subscribe_Id, 
                CASE WHEN ISDATE(@DateFrom) = 1 THEN CAST(@DateFrom AS DATETIME) ELSE GETDATE() END,
                CASE WHEN ISDATE(@DateTo) = 1 THEN CAST(@DateTo AS DATETIME) ELSE DATEADD(YEAR, 1, GETDATE()) END,
                @Comments, ISNULL(@EntryDate, GETDATE()), 0, 0, 0, 1, 1, 0, 0, 0, 0
            );
            SET @NewSST_Id = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE M_ServiceSubscriptionTrans
            SET Comments = ISNULL(@Comments, Comments),
                DateFrom = ISNULL(CASE WHEN ISDATE(@DateFrom) = 1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END, DateFrom),
                DateTo = ISNULL(CASE WHEN ISDATE(@DateTo) = 1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END, DateTo)
            WHERE SST_Id = @NewSST_Id;
        END

        -- =========================================================================
        -- STEP 4: UPDATE BATCH METADATA IN T_Pro IF EXISTS
        -- =========================================================================
        DECLARE @NewTPro_RowID BIGINT = @ExistingTPro_RowID;

        IF @NewTPro_RowID IS NOT NULL
        BEGIN
            UPDATE T_Pro
            SET MRP = ISNULL(@MRP, MRP),
                Mfd_Date = CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE Mfd_Date END,
                Exp_Date = CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE Exp_Date END,
                Comments = ISNULL(@Comments, Comments),
                Series_Limit = CASE WHEN ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> '' 
                                    THEN CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd) 
                                    ELSE ISNULL(Series_Limit, '') END
            WHERE Row_ID = @NewTPro_RowID;
        END

        -- =========================================================================
        -- STEP 5: DISPATCH & DEALER DETAILS IN codeassign_tractrac (UPSERT)
        -- =========================================================================
        IF @ExistingTracID IS NOT NULL
        BEGIN
            UPDATE codeassign_tractrac
            SET MRP = ISNULL(@MRP, MRP),
                Mfd_Date = CASE WHEN ISDATE(@Mfd_Date) = 1 THEN CAST(@Mfd_Date AS DATETIME) ELSE Mfd_Date END,
                Exp_Date = CASE WHEN ISDATE(@Exp_Date) = 1 THEN CAST(@Exp_Date AS DATETIME) ELSE Exp_Date END,
                Batch_No = ISNULL(@Batch_No, Batch_No),
                SeriesStart = ISNULL(@SeriesStart, SeriesStart),
                SeriesEnd = ISNULL(@SeriesEnd, SeriesEnd),
                Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                Mobile = ISNULL(@Mobile, Mobile),
                Email = ISNULL(@Email, Email),
                Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                Latitude = ISNULL(@Latitude, Latitude),
                Longitude = ISNULL(@Longitude, Longitude),
                SST_Id = ISNULL(@SST_Id, @NewSST_Id),
                Subscribe_Id = ISNULL(@Subscribe_Id, Subscribe_Id),
                BatchSize = ISNULL(@TotalBatchSize, BatchSize)
            WHERE ID = @ExistingTracID;
        END
        ELSE
        BEGIN
            INSERT INTO codeassign_tractrac 
            (
                mastercode, Pro_ID, MRP, Mfd_Date, Exp_Date, Batch_No, 
                SeriesStart, SeriesEnd, entry_date, 
                Dealer_Name, Dealer_Location, Mobile, Email, Dispatch_Date, 
                Invoice_Number, Latitude, Longitude, SST_Id, Subscribe_Id, BatchSize
            )
            VALUES
            (
                @MasterCode, @Pro_ID, @MRP, 
                CASE WHEN ISDATE(@Mfd_Date) = 1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, 
                CASE WHEN ISDATE(@Exp_Date) = 1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, 
                @Batch_No, @SeriesStart, @SeriesEnd, ISNULL(@EntryDate, GETDATE()), 
                @Dealer_Name, @Dealer_Location, @Mobile, @Email, ISNULL(@EntryDate, GETDATE()), 
                @Invoice_Number, @Latitude, @Longitude, 
                ISNULL(@SST_Id, @NewSST_Id), @Subscribe_Id, @TotalBatchSize
            );
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Track & Trace assignment completed successfully.' AS message, 
               @NewSST_Id AS NewSST_Id, @NewTPro_RowID AS NewTPro_RowID, 
               @SeriesStart AS SeriesStart, @SeriesEnd AS SeriesEnd, 
               @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO


-- ============================================================
-- 3. Stored Procedure: USP_InsertServiceSettingAnticounterfit_AI (SRV1018 - ONE TIME)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingAnticounterfit_AI]
    @Comp_ID        NVARCHAR(50),
    @Pro_ID         NVARCHAR(50),
    @Service_ID     NVARCHAR(50)   = 'SRV1018',
    @Subscribe_Id   NVARCHAR(50)   = NULL,
    @DateFrom       DATETIME       = NULL,
    @DateTo         DATETIME       = NULL,
    @Comments       NVARCHAR(1000) = NULL,
    @EntryDate      DATETIME       = NULL,

    -- Optional Points / Cash / Rewards settings
    @Points         NUMERIC(18, 0) = 0,
    @IsCashConvert  INT            = 0,
    @IsCash         NUMERIC(18, 0) = 0,
    @Frequency      INT            = 1,
    @AmtType        NVARCHAR(50)   = 'Fixed',
    @Minval         NUMERIC(18, 0) = 0,
    @Maxval         NUMERIC(18, 0) = 0,
    @totalamont     NUMERIC(18, 0) = 0,

    -- Batch-related fields
    @MRP            NUMERIC(18, 2) = 0,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    @Batch_No       NVARCHAR(100)  = NULL,
    @BatchSize      INT            = NULL,

    -- Optional explicit series range
    @SeriesStart    VARCHAR(100)   = NULL,
    @SeriesEnd      VARCHAR(100)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Service_ID IS NULL OR LTRIM(RTRIM(@Service_ID)) = ''
        SET @Service_ID = 'SRV1018';

    IF @MRP IS NULL
        SET @MRP = 0;

    -- Sanitize Subscribe_Id: treat empty / whitespace as NULL
    IF LTRIM(RTRIM(ISNULL(@Subscribe_Id, ''))) = ''
        SET @Subscribe_Id = NULL;

    IF @Mfd_Date IS NULL OR LTRIM(RTRIM(@Mfd_Date)) = ''
        SET @Mfd_Date = CONVERT(VARCHAR(50), GETDATE(), 120);

    IF @Exp_Date IS NULL OR LTRIM(RTRIM(@Exp_Date)) = ''
    BEGIN
        IF @DateTo IS NOT NULL
            SET @Exp_Date = CONVERT(VARCHAR(50), @DateTo, 120);
        ELSE
            SET @Exp_Date = CONVERT(VARCHAR(50), DATEADD(YEAR, 1, GETDATE()), 120);
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. ONE TIME PATTERN: Resolve or create Subscribe_Id directly
        IF @Subscribe_Id IS NULL
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID
            ORDER BY EntryDate DESC;
        END
            
        IF @Subscribe_Id IS NULL
        BEGIN
            DECLARE @PrPrefix VARCHAR(50), @PrStart BIGINT;
            SELECT TOP 1 @PrPrefix = PrPrefix, @PrStart = PrStart 
            FROM Code_Gen WITH (UPDLOCK, HOLDLOCK) 
            WHERE Prfor = 'Subscription' AND PrPrefix = 'SSI';

            IF @PrPrefix IS NULL
                SET @Subscribe_Id = 'SSI' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
            ELSE
            BEGIN
                SET @Subscribe_Id = @PrPrefix + CAST(@PrStart AS VARCHAR(50));
                UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'Subscription' AND PrPrefix = @PrPrefix;
            END
            
            INSERT INTO M_ServiceSubscription
            (
                Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName, 
                PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice, 
                DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify,
                TransType
            )
            VALUES
            (
                @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_DEFAULT', 'Manual Subscription', 
                12, 12, 0, 0, 
                ISNULL(@DateFrom, GETDATE()), ISNULL(@DateTo, DATEADD(YEAR, 1, GETDATE())), ISNULL(@EntryDate, GETDATE()), 1, 0, 1,
                'Service'
            );
        END

        DECLARE @NewSST_Id BIGINT;

        -- 2. ONE TIME PATTERN: Insert or update M_ServiceSubscriptionTrans (Single record per product)
        IF EXISTS (SELECT 1 FROM M_ServiceSubscriptionTrans WITH (NOLOCK) WHERE Subscribe_Id = @Subscribe_Id)
        BEGIN
            SELECT TOP 1 @NewSST_Id = SST_Id 
            FROM M_ServiceSubscriptionTrans WITH (NOLOCK)
            WHERE Subscribe_Id = @Subscribe_Id 
            ORDER BY Entry_Date DESC;

            UPDATE M_ServiceSubscriptionTrans
            SET DateFrom = ISNULL(@DateFrom, CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE DateFrom END),
                DateTo = ISNULL(@DateTo, CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE DateTo END),
                Comments = ISNULL(@Comments, Comments),
                IsCashConvert = ISNULL(@IsCashConvert, IsCashConvert)
            WHERE SST_Id = @NewSST_Id;
        END
        ELSE
        BEGIN
            INSERT INTO M_ServiceSubscriptionTrans
            (
                Subscribe_Id,
                Points, IsCashConvert, IsCash,
                DateFrom, DateTo,
                Comments, Entry_Date,
                Frequency, IsActive, IsDelete,
                AmtType, Minval, Maxval, totalamont
            )
            VALUES
            (
                @Subscribe_Id,
                @Points, @IsCashConvert, @IsCash,
                ISNULL(@DateFrom, CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END),
                ISNULL(@DateTo, CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END),
                @Comments, ISNULL(@EntryDate, GETDATE()),
                @Frequency, 1, 0,
                @AmtType, @Minval, @Maxval, @totalamont
            );

            SET @NewSST_Id = SCOPE_IDENTITY();
        END

        -- 2.1 Check if this Batch already exists in T_Pro (e.g. created via AddAssignLabelToProduct)
        DECLARE @ExistingTPro_RowID BIGINT = NULL;
        IF @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            SELECT TOP 1 @ExistingTPro_RowID = Row_ID 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;
        END

        -- 3. Parse and Validate Series Range if provided
        DECLARE @StartOrder INT = NULL, @StartSerial INT = NULL;
        DECLARE @EndOrder INT = NULL, @EndSerial INT = NULL;

        IF ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> ''
        BEGIN
            -- Parse SeriesStart
            IF @SeriesStart LIKE '%-%-%'
            BEGIN
                DECLARE @StartPrefix VARCHAR(50) = LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1);
                IF UPPER(LTRIM(RTRIM(@StartPrefix))) <> UPPER(LTRIM(RTRIM(@Pro_ID)))
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Enter series proid not match Selected product' AS message;
                    RETURN;
                END
                DECLARE @StartP2 VARCHAR(50) = SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart));
                SET @StartOrder = TRY_CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
            END
            ELSE IF @SeriesStart LIKE '%-%'
            BEGIN
                SET @StartOrder = TRY_CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
            END

            -- Parse SeriesEnd
            IF @SeriesEnd LIKE '%-%-%'
            BEGIN
                DECLARE @EndPrefix VARCHAR(50) = LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1);
                IF UPPER(LTRIM(RTRIM(@EndPrefix))) <> UPPER(LTRIM(RTRIM(@Pro_ID)))
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Enter series proid not match Selected product' AS message;
                    RETURN;
                END
                DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
                SET @EndOrder = TRY_CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
                SET @EndSerial = TRY_CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
            END
            ELSE IF @SeriesEnd LIKE '%-%'
            BEGIN
                SET @EndOrder = TRY_CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
                SET @EndSerial = TRY_CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
            END

            IF @StartOrder IS NULL OR @StartSerial IS NULL OR @EndOrder IS NULL OR @EndSerial IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid series format in SeriesStart/SeriesEnd. Expected format: 0000-0400 or Prefix-0000-0400.' AS message;
                RETURN;
            END

            IF @StartOrder > @EndOrder OR (@StartOrder = @EndOrder AND @StartSerial > @EndSerial)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'SeriesStart (' + @SeriesStart + ') cannot be greater than SeriesEnd (' + @SeriesEnd + ').' AS message;
                RETURN;
            END

            -- Validate that both Start code and End code exist in M_Code
            DECLARE @StartCodeExists BIT = 0, @EndCodeExists BIT = 0;

            IF @Comp_ID = 'Comp-1693'
            BEGIN
                IF EXISTS (SELECT 1 FROM M_Code_PFL WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @StartOrder AND Series_Serial = @StartSerial)
                    SET @StartCodeExists = 1;
                IF EXISTS (SELECT 1 FROM M_Code_PFL WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @EndOrder AND Series_Serial = @EndSerial)
                    SET @EndCodeExists = 1;
            END
            ELSE
            BEGIN
                IF EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @StartOrder AND Series_Serial = @StartSerial)
                    SET @StartCodeExists = 1;
                IF EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @EndOrder AND Series_Serial = @EndSerial)
                    SET @EndCodeExists = 1;
            END

            IF @StartCodeExists = 0 OR @EndCodeExists = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                RETURN;
            END

            -- Check code existence and batch status in M_Code
            DECLARE @TotalSeriesCount INT = 0;
            DECLARE @UnassignedBatchCount INT = 0;
            DECLARE @DistinctBatchCount INT = 0;
            DECLARE @AssignedBatchNo NVARCHAR(50) = NULL;

            IF @Comp_ID = 'Comp-1693'
            BEGIN
                SELECT 
                    @TotalSeriesCount = COUNT(1),
                    @UnassignedBatchCount = SUM(CASE WHEN Batch_No IS NULL OR LTRIM(RTRIM(Batch_No)) = '' THEN 1 ELSE 0 END),
                    @DistinctBatchCount = COUNT(DISTINCT CASE WHEN Batch_No IS NOT NULL AND LTRIM(RTRIM(Batch_No)) <> '' THEN Batch_No END),
                    @AssignedBatchNo = MAX(Batch_No)
                FROM M_Code_PFL WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID 
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END
            ELSE
            BEGIN
                SELECT 
                    @TotalSeriesCount = COUNT(1),
                    @UnassignedBatchCount = SUM(CASE WHEN Batch_No IS NULL OR LTRIM(RTRIM(Batch_No)) = '' THEN 1 ELSE 0 END),
                    @DistinctBatchCount = COUNT(DISTINCT CASE WHEN Batch_No IS NOT NULL AND LTRIM(RTRIM(Batch_No)) <> '' THEN Batch_No END),
                    @AssignedBatchNo = MAX(Batch_No)
                FROM M_Code WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID 
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END

            IF @StartOrder = @EndOrder
            BEGIN
                DECLARE @ExpectedCount INT = (@EndSerial - @StartSerial) + 1;
                IF @TotalSeriesCount < @ExpectedCount
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                    RETURN;
                END
            END

            IF ISNULL(@TotalSeriesCount, 0) = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                RETURN;
            END

            IF ISNULL(@UnassignedBatchCount, 0) > 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'As per given series, label assignment is pending. Please assign labels to product first via Assign Label to Product.' AS message;
                RETURN;
            END

            IF @DistinctBatchCount > 1
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'The specified series range spans multiple batches. Please configure services for one batch range at a time.' AS message;
                RETURN;
            END

            IF @ExistingTPro_RowID IS NULL AND @AssignedBatchNo IS NOT NULL
            BEGIN
                SET @ExistingTPro_RowID = TRY_CAST(@AssignedBatchNo AS BIGINT);
            END
        END
        ELSE IF @ExistingTPro_RowID IS NULL AND @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            SELECT TOP 1 @ExistingTPro_RowID = Row_ID 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = @Pro_ID AND (Batch_No = @Batch_No OR Row_ID = TRY_CAST(@Batch_No AS BIGINT));
        END

        -- 4. Update T_Pro metadata only if Batch exists
        IF @ExistingTPro_RowID IS NOT NULL
        BEGIN
            UPDATE T_Pro
            SET MRP = ISNULL(@MRP, MRP),
                Mfd_Date = CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE Mfd_Date END,
                Exp_Date = CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE Exp_Date END,
                Comments = ISNULL(@Comments, Comments),
                Series_Limit = CASE WHEN ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> '' 
                                    THEN CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd) 
                                    ELSE ISNULL(Series_Limit, '') END
            WHERE Row_ID = @ExistingTPro_RowID;
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Anticounterfeiting service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id, @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
