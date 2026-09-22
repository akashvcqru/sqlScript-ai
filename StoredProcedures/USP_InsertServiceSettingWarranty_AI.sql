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
                DECLARE @GeneratedSubId VARCHAR(50) = 'SUB' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));

                INSERT INTO M_ServiceSubscription
                (
                    Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName,
                    PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice,
                    DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify,
                    TransType
                )
                VALUES
                (
                    @GeneratedSubId, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_WARRANTY', 'Warranty Subscription',
                    ISNULL(@WarrantyPeriod, 12), ISNULL(@WarrantyPeriod, 12), 0, 0,
                    ISNULL(@DateFrom, GETDATE()), 
                    ISNULL(@DateTo, DATEADD(MONTH, ISNULL(@WarrantyPeriod, 12), GETDATE())), 
                    ISNULL(@EntryDate, GETDATE()), 1, 0, 1,
                    'Service'
                );

                SET @Subscribe_Id = @GeneratedSubId;
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

        -- 3. Parse and Validate Series Range if provided
        DECLARE @StartOrder INT = NULL, @StartSerial INT = NULL;
        DECLARE @EndOrder INT = NULL, @EndSerial INT = NULL;

        IF ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> ''
        BEGIN
            -- Parse SeriesStart (handles "0000-0400" or "BP17-0000-0400")
            IF @SeriesStart LIKE '%-%-%'
            BEGIN
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

            -- Check availability in M_Code (or M_Code_PFL)
            DECLARE @ExistingCount INT = 0, @AvailableCount INT = 0;

            IF @Comp_ID = 'Comp-1693'
            BEGIN
                SELECT 
                    @ExistingCount = COUNT(1),
                    @AvailableCount = SUM(CASE WHEN Batch_No IS NULL OR Batch_No = '' THEN 1 ELSE 0 END)
                FROM M_Code_PFL WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END
            ELSE
            BEGIN
                SELECT 
                    @ExistingCount = COUNT(1),
                    @AvailableCount = SUM(CASE WHEN Batch_No IS NULL OR Batch_No = '' THEN 1 ELSE 0 END)
                FROM M_Code WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END

            IF ISNULL(@ExistingCount, 0) = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'The specified series range ' + @SeriesStart + ' to ' + @SeriesEnd + ' does not exist for product ' + @Pro_ID + '.' AS message;
                RETURN;
            END

            IF ISNULL(@AvailableCount, 0) = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'No available codes in range ' + @SeriesStart + ' to ' + @SeriesEnd + ' for product ' + @Pro_ID + '. All ' + CAST(@ExistingCount AS VARCHAR(10)) + ' codes are already assigned to another batch.' AS message;
                RETURN;
            END

            IF @AvailableCount < @ExistingCount
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Only ' + CAST(ISNULL(@AvailableCount, 0) AS VARCHAR(10)) + ' of ' + CAST(@ExistingCount AS VARCHAR(10)) + ' codes are available in range ' + @SeriesStart + ' to ' + @SeriesEnd + ' for product ' + @Pro_ID + '. Some codes are already assigned to another batch.' AS message;
                RETURN;
            END
        END

        -- 4. Insert / Update T_Pro (Batch info)
        IF @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            DECLARE @NewTPro_RowID BIGINT;

            SELECT TOP 1 @NewTPro_RowID = Row_ID 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;

            IF @NewTPro_RowID IS NULL
            BEGIN
                INSERT INTO T_Pro
                (
                    Pro_ID, Batch_No, MRP, Mfd_Date, Exp_Date, Comments, Entry_Date, Series_Limit
                )
                VALUES
                (
                    @Pro_ID, @Batch_No, ISNULL(@MRP, 0), 
                    CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
                    CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
                    @Comments, ISNULL(@EntryDate, GETDATE()),
                    CASE WHEN ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> '' 
                         THEN CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd) 
                         ELSE NULL END
                );
                SET @NewTPro_RowID = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                UPDATE T_Pro
                SET MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE Mfd_Date END,
                    Exp_Date = CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE Exp_Date END,
                    Comments = ISNULL(@Comments, Comments),
                    Series_Limit = CASE WHEN ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> '' 
                                        THEN CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd) 
                                        ELSE Series_Limit END
                WHERE Row_ID = @NewTPro_RowID;
            END

            -- Fallback BatchSize from Pro_Reg if not explicitly provided
            IF ISNULL(@BatchSize, 0) <= 0
            BEGIN
                SELECT @BatchSize = ISNULL(BatchSize, 0)
                FROM Pro_Reg WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID;
            END

            -- 5. Batch assignment in M_Code / M_Code_PFL
            DECLARE @Qty INT = 0;
            DECLARE @UpdatedCodes TABLE (
                Series_Order INT,
                Series_Serial INT
            );

            IF @StartOrder IS NOT NULL AND @EndOrder IS NOT NULL
            BEGIN
                IF @Comp_ID = 'Comp-1693'
                BEGIN
                    UPDATE M_Code_PFL WITH (ROWLOCK)
                    SET Batch_No = CAST(@NewTPro_RowID AS NVARCHAR(50))
                    OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes
                    WHERE Pro_ID = @Pro_ID
                      AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                           OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))))
                      AND (Batch_No IS NULL OR Batch_No = '');

                    SET @Qty = @@ROWCOUNT;
                END
                ELSE
                BEGIN
                    UPDATE M_Code WITH (ROWLOCK)
                    SET Batch_No = CAST(@NewTPro_RowID AS NVARCHAR(50))
                    OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes
                    WHERE Pro_ID = @Pro_ID
                      AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                           OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))))
                      AND (Batch_No IS NULL OR Batch_No = '');

                    SET @Qty = @@ROWCOUNT;
                END
            END
            ELSE IF @Comp_ID = 'Comp-1693'
            BEGIN
                IF ISNULL(@BatchSize, 0) > 0
                BEGIN
                    ;WITH CTE AS (
                        SELECT TOP (@BatchSize) Batch_No, Series_Order, Series_Serial
                        FROM M_Code_PFL WITH (ROWLOCK)
                        WHERE Pro_ID = @Pro_ID AND (Batch_No IS NULL OR Batch_No = '')
                    )
                    UPDATE CTE
                    SET Batch_No = CAST(@NewTPro_RowID AS NVARCHAR(50))
                    OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes;

                    SET @Qty = @@ROWCOUNT;
                END
                ELSE
                BEGIN
                    ;WITH CTE AS (
                        SELECT TOP (50000) Batch_No, Series_Order, Series_Serial
                        FROM M_Code_PFL WITH (ROWLOCK)
                        WHERE Pro_ID = @Pro_ID AND (Batch_No IS NULL OR Batch_No = '')
                    )
                    UPDATE CTE
                    SET Batch_No = CAST(@NewTPro_RowID AS NVARCHAR(50))
                    OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes;

                    SET @Qty = @@ROWCOUNT;
                END
            END
            ELSE
            BEGIN
                IF ISNULL(@BatchSize, 0) > 0
                BEGIN
                    ;WITH CTE AS (
                        SELECT TOP (@BatchSize) Batch_No, Series_Order, Series_Serial
                        FROM M_Code WITH (ROWLOCK)
                        WHERE Pro_ID = @Pro_ID AND (Batch_No IS NULL OR Batch_No = '')
                    )
                    UPDATE CTE
                    SET Batch_No = CAST(@NewTPro_RowID AS NVARCHAR(50))
                    OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes;

                    SET @Qty = @@ROWCOUNT;
                END
                ELSE
                BEGIN
                    ;WITH CTE AS (
                        SELECT TOP (50000) Batch_No, Series_Order, Series_Serial
                        FROM M_Code WITH (ROWLOCK)
                        WHERE Pro_ID = @Pro_ID AND (Batch_No IS NULL OR Batch_No = '')
                    )
                    UPDATE CTE
                    SET Batch_No = CAST(@NewTPro_RowID AS NVARCHAR(50))
                    OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes;

                    SET @Qty = @@ROWCOUNT;
                END
            END

            -- 6. Update Series_Limit in T_Pro from in-memory @UpdatedCodes if not set
            IF (ISNULL(@SeriesStart, '') = '' OR ISNULL(@SeriesEnd, '') = '') AND @Qty > 0
            BEGIN
                DECLARE @MinOrder INT, @MaxOrder INT, @MinSerial INT, @MaxSerial INT;
                
                SELECT 
                    @MinOrder = MIN(Series_Order),
                    @MaxOrder = MAX(Series_Order),
                    @MinSerial = MIN(Series_Serial),
                    @MaxSerial = MAX(Series_Serial)
                FROM @UpdatedCodes;

                IF @MinOrder IS NOT NULL
                BEGIN
                    DECLARE @SeriesLimitStr NVARCHAR(500) = 
                        'From ' + @Pro_ID + '-' + RIGHT('00' + CAST(@MinOrder AS VARCHAR(10)), 2) + '-' + RIGHT('0000' + CAST(@MinSerial AS VARCHAR(10)), 4) +
                        ' To ' + @Pro_ID + '-' + RIGHT('00' + CAST(@MaxOrder AS VARCHAR(10)), 2) + '-' + RIGHT('0000' + CAST(@MaxSerial AS VARCHAR(10)), 4) +
                        ' (qty ' + CAST(@Qty AS VARCHAR(20)) + ')';

                    UPDATE T_Pro
                    SET Series_Limit = @SeriesLimitStr
                    WHERE Row_ID = @NewTPro_RowID;
                END
                ELSE
                BEGIN
                    UPDATE T_Pro
                    SET Series_Limit = 'Qty ' + CAST(@Qty AS VARCHAR(20))
                    WHERE Row_ID = @NewTPro_RowID;
                END
            END
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
