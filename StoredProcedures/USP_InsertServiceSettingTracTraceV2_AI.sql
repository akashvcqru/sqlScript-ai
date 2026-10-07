-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingTracTraceV2_AI
-- Purpose        : Insert Track & Trace service setting.
--                  Prevents duplicate settings and overlapping series ranges.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingTracTraceV2_AI]
    @Comp_ID        NVARCHAR(50),
    @Pro_ID         NVARCHAR(50),
    @Service_ID     NVARCHAR(50)   = 'SRV1021',
    @Subscribe_Id   NVARCHAR(50)   = NULL,

    @Batch_No       NVARCHAR(100)  = NULL,
    @SeriesStart    VARCHAR(100)   = NULL,
    @SeriesEnd      VARCHAR(100)   = NULL,
    @MasterCode     VARCHAR(100)   = NULL,
    @Comments       NVARCHAR(1000) = NULL,
    @EntryDate      DATETIME       = NULL,

    @Dealer_Name    NVARCHAR(200)  = NULL,
    @Dealer_Location NVARCHAR(200) = NULL,
    @Mobile         VARCHAR(20)    = NULL,
    @Email          VARCHAR(100)   = NULL,
    @Invoice_Number VARCHAR(100)   = NULL,
    @BatchSize      INT            = NULL,
    @DateFrom       DATETIME       = NULL,
    @DateTo         DATETIME       = NULL,
    @MRP            NUMERIC(18,2)  = 0,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Service_ID IS NULL OR LTRIM(RTRIM(@Service_ID)) = ''
        SET @Service_ID = 'SRV1021';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Parse and Validate Series Range
        DECLARE @StartOrder INT = NULL, @StartSerial INT = NULL;
        DECLARE @EndOrder INT = NULL, @EndSerial INT = NULL;

        IF ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> ''
        BEGIN
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

            IF NOT EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @StartOrder AND Series_Serial = @StartSerial)
               OR NOT EXISTS (SELECT 1 FROM M_Code WITH (NOLOCK) WHERE Pro_ID = @Pro_ID AND Series_Order = @EndOrder AND Series_Serial = @EndSerial)
            BEGIN
                SELECT 0 AS success, 'Invalid code series. Please verify the start and end series range.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END
        END

        -- 1.1 Check for duplicate/overlapping service settings on this product for the SAME Service_ID
        DECLARE @ConflictingSubId VARCHAR(50) = NULL;
        DECLARE @ConflictStart VARCHAR(50) = NULL, @ConflictEnd VARCHAR(50) = NULL;

        IF @StartOrder IS NOT NULL AND @StartSerial IS NOT NULL AND @EndOrder IS NOT NULL AND @EndSerial IS NOT NULL
        BEGIN
            SELECT TOP 1 
                @ConflictingSubId = Subscribe_Id,
                @ConflictStart = CONCAT(FORMAT(ISNULL(start_order, 0), '0000'), '-', FORMAT(ISNULL(start_series, 0), '0000')),
                @ConflictEnd = CONCAT(FORMAT(ISNULL(end_order, 0), '0000'), '-', FORMAT(ISNULL(end_series, 0), '0000'))
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Pro_ID = @Pro_ID
              AND Service_ID = @Service_ID
              AND (Comp_ID = @Comp_ID OR @Comp_ID IS NULL)
              AND Subscribe_Id <> ISNULL(@Subscribe_Id, '')
              AND (
                  (
                      start_order IS NOT NULL AND start_series IS NOT NULL 
                      AND end_order IS NOT NULL AND end_series IS NOT NULL
                      AND (@StartOrder < end_order OR (@StartOrder = end_order AND @StartSerial <= end_series))
                      AND (start_order < @EndOrder OR (start_order = @EndOrder AND start_series <= @EndSerial))
                  )
                  OR
                  (
                      start_order IS NULL
                      AND EXISTS (
                          SELECT 1 FROM M_ServiceSubscriptionTrans sst WITH (NOLOCK) 
                          WHERE sst.Subscribe_Id = M_ServiceSubscription.Subscribe_Id
                      )
                  )
              );

            IF @ConflictingSubId IS NOT NULL
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 
                       CONCAT('Service setting already done for service ', @Service_ID, ' on product ', @Pro_ID, 
                              CASE WHEN @ConflictStart IS NOT NULL AND @ConflictStart <> '0000-0000' 
                                   THEN CONCAT(' (overlaps with series ', @ConflictStart, ' to ', @ConflictEnd, ')') 
                                   ELSE '' END, '.') AS message;
                RETURN;
            END
        END

        -- 2. Fetch Plan Details
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
        WHERE Service_ID = @Service_ID AND Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID
        ORDER BY EntryDate DESC, Subscribe_Id DESC;

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

        -- 3. Insert into M_ServiceSubscriptionTrans
        DECLARE @NewSST_Id BIGINT;

        INSERT INTO M_ServiceSubscriptionTrans
        (
            Subscribe_Id,
            DateFrom, DateTo,
            IsCashConvert, Frequency, Points, AmtType,
            Minval, Maxval, IsCash,
            Comments, Entry_Date, IsActive, IsDelete
        )
        VALUES
        (
            @Subscribe_Id,
            ISNULL(TRY_CAST(@DateFrom AS DATETIME), GETDATE()),
            ISNULL(TRY_CAST(@DateTo AS DATETIME), DATEADD(YEAR, 1, GETDATE())),
            0, 1, 0, 'Fixed',
            0, 0, 0,
            @Comments, ISNULL(@EntryDate, GETDATE()), 1, 0
        );

        SET @NewSST_Id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Track & Trace service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id, @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
