-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingWarranty_AI
-- Purpose        : Insert Warranty (SRV1023) service setting.
--                  Handles M_ServiceSubscription, M_ServiceSubscriptionTrans,
--                  T_Pro batch details, and batch code allocation in M_Code/M_Code_PFL.
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

        -- 1. Resolve or create Subscribe_Id for SRV1023
        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID
            ORDER BY EntryDate DESC;

            IF @Subscribe_Id IS NULL
            BEGIN
                DECLARE @PrPrefix VARCHAR(50), @PrStart BIGINT;
                SELECT TOP 1 @PrPrefix = PrPrefix, @PrStart = PrStart 
                FROM Code_Gen 
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
                    @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_WARRANTY', 'Warranty Subscription',
                    ISNULL(@WarrantyPeriod, 12), ISNULL(@WarrantyPeriod, 12), 0, 0,
                    ISNULL(@DateFrom, GETDATE()), 
                    ISNULL(@DateTo, DATEADD(MONTH, ISNULL(@WarrantyPeriod, 12), GETDATE())), 
                    ISNULL(@EntryDate, GETDATE()), 1, 0, 1,
                    'Service'
                );
            END
            ELSE
            BEGIN
                -- Update PlanMasterPeriod if provided
                UPDATE M_ServiceSubscription
                SET PlanMasterPeriod = ISNULL(@WarrantyPeriod, PlanMasterPeriod),
                    PlanSalePeriod = ISNULL(@WarrantyPeriod, PlanSalePeriod)
                WHERE Subscribe_Id = @Subscribe_Id;
            END
        END

        DECLARE @NewSST_Id BIGINT;

        -- 2. Insert or update M_ServiceSubscriptionTrans (keep single record if already exists)
        IF EXISTS (SELECT 1 FROM M_ServiceSubscriptionTrans WITH (NOLOCK) WHERE Subscribe_Id = @Subscribe_Id)
        BEGIN
            SELECT TOP 1 @NewSST_Id = SST_Id 
            FROM M_ServiceSubscriptionTrans WITH (NOLOCK)
            WHERE Subscribe_Id = @Subscribe_Id 
            ORDER BY Entry_Date DESC;

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
        ELSE
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

        -- 4. Update T_Pro metadata only if Batch exists (never create a new batch here)
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
        SELECT 1 AS success, 'Warranty service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
