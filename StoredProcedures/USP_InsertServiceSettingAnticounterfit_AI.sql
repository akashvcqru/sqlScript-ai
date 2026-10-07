-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingAnticounterfit_AI
-- Purpose        : Insert Anti-counterfeiting service setting.
--                  Prevents duplicate settings and overlapping series ranges.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingAnticounterfit_AI]
    @Comp_ID      VARCHAR(50),
    @Pro_ID       VARCHAR(50),
    @Service_ID   VARCHAR(50)    = 'SRV1018',
    @Subscribe_Id VARCHAR(50)    = NULL,

    @DateFrom     DATETIME       = NULL,
    @DateTo       DATETIME       = NULL,
    @Comments     NVARCHAR(1000) = NULL,
    @EntryDate    DATETIME       = NULL,

    @Points          NUMERIC(18,0) = 0,
    @IsCashConvert   INT           = 0,
    @IsCash          NUMERIC(18,0) = 0,
    @Frequency       INT           = 1,
    @IsActive        INT           = 0,
    @IsDelete        INT           = 0,
    @AmtType         VARCHAR(12)   = 'Fixed',
    @Minval          NUMERIC(18,0) = 0,
    @Maxval          NUMERIC(18,0) = 0,
    @totalamont      NUMERIC(18,0) = 0,

    @MRP            NUMERIC(18, 2) = 0,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    @Batch_No       NVARCHAR(100)  = NULL,
    @BatchSize      INT            = NULL,
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

        -- 1. Parse and Validate Series Range if provided
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
                SET @StartOrder = TRY_CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
            END
            ELSE IF @SeriesStart LIKE '%-%'
            BEGIN
                SET @StartOrder = TRY_CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
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

        -- 2. Resolve or create Subscribe_Id
        IF LTRIM(RTRIM(ISNULL(@Subscribe_Id, ''))) = ''
            SET @Subscribe_Id = NULL;

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
                TransType, start_order, start_series, end_order, end_series
            )
            VALUES
            (
                @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_DEFAULT', 'Manual Subscription', 
                12, 12, 0, 0, 
                ISNULL(@DateFrom, GETDATE()), ISNULL(@DateTo, DATEADD(YEAR, 1, GETDATE())), ISNULL(@EntryDate, GETDATE()), 1, 0, 1,
                'Service', @StartOrder, @StartSerial, @EndOrder, @EndSerial
            );
        END

        DECLARE @NewSST_Id BIGINT;

        -- 3. Insert into M_ServiceSubscriptionTrans
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

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Anti-counterfeiting service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id, @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
