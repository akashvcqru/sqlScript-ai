-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingBloyalty_AI
-- Purpose        : Insert Brand Loyalty (Bloyalty) service setting.
--                  Always creates a new record in M_ServiceSubscription
--                  and M_ServiceSubscriptionTrans, copying plan values
--                  (Plan_ID, PlanName, PlanMasterPeriod, PlanSalePeriod,
--                  PlanMasterPrice, PlanSalePrice, IsActive, IsDelete,
--                  IsAdminVerify, TransType) from the last inserted
--                  record for the given Service_ID.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingBloyalty_AI]
    @Comp_ID        VARCHAR(50),
    @Pro_ID         VARCHAR(50),
    @Service_ID     VARCHAR(50),
    @Subscribe_Id   VARCHAR(50)   = NULL,

    @DateFrom       DATETIME      = NULL,
    @DateTo         DATETIME      = NULL,
    @SeriesStart    VARCHAR(100)  = NULL,
    @SeriesEnd      VARCHAR(100)  = NULL,
    @Frequency      INT           = NULL,

    @Mfd_Date       VARCHAR(50)   = NULL,
    @Exp_Date       VARCHAR(50)   = NULL,
    @Batch_No       VARCHAR(100)  = NULL,
    @MRP            NUMERIC(18,2) = 0,
    @BatchSize      INT           = NULL,

    @AmtType        VARCHAR(50)   = NULL,   -- 'Fixed' | 'Random'
    @Points         DECIMAL(18,2) = NULL,
    @IsCashConvert  INT           = NULL,

    @TotalLoyalty   BIGINT        = NULL,
    @Multiple       INT           = NULL,
    @Minval         INT           = NULL,
    @Maxval         INT           = NULL,
    @Comments       NVARCHAR(1000)= NULL,
    @EntryDate      DATETIME      = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

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

        -- Priority 2: If not found, match Comp_ID and Service_ID
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

        -- Priority 3: If still not found, match by Service_ID overall
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
        SET @PlanID_Last = ISNULL(@PlanID_Last, 'PLAN_DEFAULT');
        SET @PlanName_Last = ISNULL(@PlanName_Last, 'Manual Subscription');
        SET @PlanMasterPeriod_Last = ISNULL(@PlanMasterPeriod_Last, 12);
        SET @PlanSalePeriod_Last = ISNULL(@PlanSalePeriod_Last, 12);
        SET @PlanMasterPrice_Last = ISNULL(@PlanMasterPrice_Last, 0);
        SET @PlanSalePrice_Last = ISNULL(@PlanSalePrice_Last, 0);
        SET @IsActive_Last = ISNULL(@IsActive_Last, 1);
        SET @IsDelete_Last = ISNULL(@IsDelete_Last, 0);
        SET @IsAdminVerify_Last = ISNULL(@IsAdminVerify_Last, 1);
        SET @TransType_Last = ISNULL(@TransType_Last, 'Service');

        -- 2. Generate a new Subscribe_Id every time
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

        -- 3. Parse series range if provided
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

        -- 4. Insert new record in M_ServiceSubscription
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
            ISNULL(@DateTo, CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE DATEADD(YEAR, 1, GETDATE()) END),
            ISNULL(@EntryDate, GETDATE()), 
            @IsActive_Last, @IsDelete_Last, @IsAdminVerify_Last,
            @TransType_Last, @StartOrder, @StartSerial, @EndOrder, @EndSerial
        );

        -- 5. Insert new record in M_ServiceSubscriptionTrans
        INSERT INTO M_ServiceSubscriptionTrans
        (
            Subscribe_Id,
            DateFrom, DateTo,
            IsCashConvert, Frequency, Points, AmtType, totalamont,
            Minval, Maxval, IsCash,
            IsReferral,
            Comments, Entry_Date, IsActive, IsDelete
        )
        VALUES
        (
            @Subscribe_Id,
            ISNULL(@DateFrom, CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END),
            ISNULL(@DateTo, CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END),
            ISNULL(@IsCashConvert, 1), ISNULL(@Frequency, 1), @Points, ISNULL(@AmtType, 'Fixed'), @TotalLoyalty,
            @Minval, @Maxval, 0,
            0,
            @Comments, ISNULL(@EntryDate, GETDATE()), 1, 0
        );

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        -- 6. Insert into T_Pro (Product Batch Details) if Batch_No is provided
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

            -- 7. Batch assignment in M_Code / M_Code_PFL
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

            -- 8. Update Series_Limit in T_Pro if not already set by SeriesStart/SeriesEnd
            IF (ISNULL(@SeriesStart, '') = '' OR ISNULL(@SeriesEnd, '') = '') AND @Qty > 0
            BEGIN
                DECLARE @MinOrder INT, @MaxOrder INT, @MinSerial INT, @MaxSerial INT;
                
                SELECT 
                    @MinOrder = MIN(Series_Order),
                    @MaxOrder = MAX(Series_Order),
                    @MinSerial = MIN(Series_Serial),
                    @MaxSerial = MAX(Series_Serial)
                FROM M_Code WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID AND Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50));

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
        SELECT 1 AS success, 'Brand Loyalty service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id, @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
