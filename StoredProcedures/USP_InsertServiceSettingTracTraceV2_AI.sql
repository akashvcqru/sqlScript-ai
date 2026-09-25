SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Procedure: USP_InsertServiceSettingTracTraceV2_AI
-- Description: Assign Track & Trace service settings, handle 1-time subscription & settings (UPSERT),
--              batch creation in T_Pro, series locking in M_Code, and dealer tracking in codeassign_tractrac.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingTracTraceV2_AI]
    @Comp_ID             VARCHAR(50),
    @Pro_ID              VARCHAR(50),
    @Service_ID          VARCHAR(50)    = 'SRV1021',
    @Subscribe_Id        VARCHAR(50)    = NULL,
    @Batch_No            VARCHAR(100)   = NULL,
    @SeriesStart         VARCHAR(100)   = NULL, -- Format: "Order-SerialFrom" or "Prefix-Order-Serial"
    @SeriesEnd           VARCHAR(100)   = NULL, -- Format: "Order-SerialTo" or "Prefix-Order-Serial"
    @MasterCode          VARCHAR(100)   = NULL, -- Any code from same product (first, middle, last, or in-range)
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

    IF @MRP IS NULL
        SET @MRP = 0;

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

        -- 0.1 Parse SeriesStart / SeriesEnd
        DECLARE @StartOrder INT, @StartSerial INT;
        DECLARE @EndOrder   INT, @EndSerial   INT;

        -- 0.2 Automated Range Calculation (if series not provided)
        IF ISNULL(@SeriesStart, '') = '' OR ISNULL(@SeriesEnd, '') = ''
        BEGIN
            IF @BatchSize IS NULL OR @BatchSize <= 0
            BEGIN
                SELECT 0 AS success, 'BatchSize is required for automated range calculation.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- Find the last assigned range from M_ServiceSubscription / codeassign_tractrac
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
                WHERE Pro_ID = @Pro_ID AND (Batch_No IS NULL OR Batch_No = '')
                ORDER BY Series_Order, Series_Serial;
            END
            ELSE
            BEGIN
                SELECT TOP 1 @StartOrder = Series_Order, @StartSerial = Series_Serial
                FROM M_Code 
                WHERE Pro_ID = @Pro_ID 
                  AND (Batch_No IS NULL OR Batch_No = '')
                  AND (Series_Order > @LastEndOrder OR (Series_Order = @LastEndOrder AND Series_Serial > @LastEndSerial))
                ORDER BY Series_Order, Series_Serial;
            END

            IF @StartOrder IS NULL
            BEGIN
                SELECT 0 AS success, 'No available unassigned codes found in M_Code for this product.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- Calculate End series based on BatchSize
            ;WITH NextBatch AS (
                SELECT TOP (@BatchSize) Series_Order, Series_Serial
                FROM M_Code
                WHERE Pro_ID = @Pro_ID
                  AND (Batch_No IS NULL OR Batch_No = '')
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
                DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
                SET @EndOrder = CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
                SET @EndSerial = CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
            END
            ELSE IF @SeriesEnd LIKE '%-%'
            BEGIN
                SET @EndOrder = CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
                SET @EndSerial = CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
            END

            -- Existence validation
            DECLARE @ExistingCount INT;
            SELECT @ExistingCount = COUNT(*) FROM M_Code 
            WHERE Pro_ID = @Pro_ID 
              AND (Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
              AND (Series_Order < @EndOrder OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial));

            IF @ExistingCount = 0
            BEGIN
                SELECT 0 AS success, 'The specified code range does not exist in the system.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- BatchSize Validation
            IF @BatchSize IS NOT NULL AND @BatchSize > 0
            BEGIN
                DECLARE @CalculatedCount INT;
                IF @StartOrder = @EndOrder
                BEGIN
                    SET @CalculatedCount = (@EndSerial - @StartSerial) + 1;
                END
                ELSE
                BEGIN
                    SELECT @CalculatedCount = COUNT(*) 
                    FROM M_Code 
                    WHERE Pro_ID = @Pro_ID 
                      AND (Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
                      AND (Series_Order < @EndOrder OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial));
                END

                IF @CalculatedCount <> @BatchSize
                BEGIN
                    SELECT 0 AS success, CONCAT('Number of codes mismatch. Expected: ', @BatchSize, ', Found: ', @CalculatedCount) AS message;
                    ROLLBACK TRANSACTION; RETURN;
                END
            END
        END

        -- 1. MasterCode Resolution & Validation
        -- If MasterCode is not provided, default to the SeriesStart code
        IF ISNULL(@MasterCode, '') = ''
        BEGIN
            SET @MasterCode = @SeriesStart;
        END

        -- Check MasterCode uniqueness in codeassign_tractrac
        IF EXISTS (SELECT 1 FROM codeassign_tractrac WHERE mastercode = @MasterCode)
        BEGIN
            SELECT 0 AS success, CONCAT('Master code ', @MasterCode, ' already exists.') AS message;
            ROLLBACK TRANSACTION; RETURN;
        END

        -- Parse MasterCode parts
        DECLARE @MasterOrd INT, @MasterSer INT;
        IF @MasterCode LIKE '%-%-%'
        BEGIN
            DECLARE @MP2 VARCHAR(50) = SUBSTRING(@MasterCode, CHARINDEX('-', @MasterCode) + 1, LEN(@MasterCode));
            SET @MasterOrd = TRY_CAST(LEFT(@MP2, CHARINDEX('-', @MP2) - 1) AS INT);
            SET @MasterSer = TRY_CAST(SUBSTRING(@MP2, CHARINDEX('-', @MP2) + 1, LEN(@MP2)) AS INT);
        END
        ELSE IF @MasterCode LIKE '%-%'
        BEGIN
            SET @MasterOrd = TRY_CAST(LEFT(@MasterCode, CHARINDEX('-', @MasterCode) - 1) AS INT);
            SET @MasterSer = TRY_CAST(SUBSTRING(@MasterCode, CHARINDEX('-', @MasterCode) + 1, LEN(@MasterCode)) AS INT);
        END

        -- Validate that codes in range are not already assigned to another batch
        IF EXISTS (
            SELECT 1 FROM M_Code 
            WHERE Pro_ID = @Pro_ID 
              AND (
                  ((Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
                   AND (Series_Order < @EndOrder OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial)))
                  OR (
                      @MasterOrd IS NOT NULL AND @MasterSer IS NOT NULL
                      AND Series_Order = @MasterOrd AND Series_Serial = @MasterSer
                  )
              )
              AND (Batch_No IS NOT NULL AND Batch_No <> '')
        )
        BEGIN
            SELECT 0 AS success, 'These codes (or master code) are already assigned to another batch.' AS message;
            ROLLBACK TRANSACTION; RETURN;
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
        -- STEP 2: ONE-TIME / REUSE M_ServiceSubscription (UPSERT Pattern)
        -- =========================================================================
        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID
            ORDER BY EntryDate DESC;

            IF @Subscribe_Id IS NULL
            BEGIN
                DECLARE @PrPrefix VARCHAR(50), @PrStart BIGINT;
                SELECT @PrPrefix = PrPrefix, @PrStart = PrStart FROM Code_Gen WHERE Prfor = 'Subscription' AND PrPrefix = 'SSI';
                
                IF @PrPrefix IS NULL
                BEGIN
                    SET @Subscribe_Id = 'SSI' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
                END
                ELSE
                BEGIN
                    SET @Subscribe_Id = @PrPrefix + CAST(@PrStart AS VARCHAR(50));
                    UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'Subscription' AND PrPrefix = 'SSI';
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
                    @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_DEFAULT', 'Track & Trace Subscription',
                    365, 365, 0, 0,
                    ISNULL(TRY_CAST(@DateFrom AS DATETIME), GETDATE()), 
                    ISNULL(TRY_CAST(@DateTo AS DATETIME), DATEADD(YEAR, 1, GETDATE())), 
                    GETDATE(), 1, 0, 1, 'Service',
                    @StartOrder, @StartSerial, @EndOrder, @EndSerial
                );
            END
            ELSE
            BEGIN
                -- Update existing subscription range boundary if needed
                UPDATE M_ServiceSubscription
                SET end_order = @EndOrder,
                    end_series = @EndSerial
                WHERE Subscribe_Id = @Subscribe_Id;
            END
        END

        -- =========================================================================
        -- STEP 3: ONE-TIME / REUSE M_ServiceSubscriptionTrans (UPSERT Pattern)
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
                @Comments, ISNULL(@EntryDate, GETDATE()), 0, 1, 0, 1, 1, 0, 0, 0, 0
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
        -- STEP 4: BATCH MASTER IN T_Pro (Create or Fetch)
        -- =========================================================================
        DECLARE @NewTPro_RowID BIGINT;
        SELECT @NewTPro_RowID = Row_ID FROM T_Pro WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;

        IF @NewTPro_RowID IS NULL
        BEGIN
            INSERT INTO T_Pro
            (
                Pro_ID, Batch_No, Comments, Entry_Date, Series_Limit,
                MRP, Mfd_Date, Exp_Date
            )
            VALUES
            (
                @Pro_ID, @Batch_No, 
                @Comments, ISNULL(@EntryDate, GETDATE()),
                CASE WHEN ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> '' 
                     THEN CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd) 
                     ELSE '' END,
                @MRP,
                CASE WHEN ISDATE(@Mfd_Date) = 1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
                CASE WHEN ISDATE(@Exp_Date) = 1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END
            );
            SET @NewTPro_RowID = SCOPE_IDENTITY();
        END

        -- =========================================================================
        -- STEP 5: LOCK CODES IN M_Code
        -- =========================================================================
        UPDATE M_Code
        SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50)),
            print_status = 1 
        WHERE Pro_ID = @Pro_ID 
          AND (Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
          AND (Series_Order < @EndOrder OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial))
          AND (Series_Order BETWEEN @StartOrder AND @EndOrder)
          AND (Batch_No IS NULL OR Batch_No = '');

        -- If MasterCode is outside the series, update its Batch_No separately
        IF @IsMasterInBatch = 0 AND @MasterOrd IS NOT NULL AND @MasterSer IS NOT NULL
        BEGIN
            UPDATE M_Code
            SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50)),
                print_status = 1
            WHERE Pro_ID = @Pro_ID 
              AND Series_Order = @MasterOrd 
              AND Series_Serial = @MasterSer;
        END

        -- Set Series_Limit helper procedure if available
        IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UpdateM_codeByBatch_No' AND type = 'P')
        BEGIN
            EXEC UpdateM_codeByBatch_No @NewTPro_RowID, @Pro_ID;
        END

        -- =========================================================================
        -- STEP 6: DISPATCH & DEALER DETAILS IN codeassign_tractrac
        -- =========================================================================
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
