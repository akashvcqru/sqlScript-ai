SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_AddServiceSettingMasterCodeTrackAndTrace_AI]
    @Comp_ID        VARCHAR(50),
    @Pro_ID         VARCHAR(50),
    @Service_ID     VARCHAR(50),
    @Subscribe_Id   VARCHAR(50)    = NULL,
    @Batch_No       VARCHAR(100)   = NULL,
    @SeriesStart    VARCHAR(100)   = NULL, -- Format: "Order-SerialFrom"
    @SeriesEnd      VARCHAR(100)   = NULL, -- Format: "Order-SerialTo"
    -- @MasterCode removed as per requirement
    @Comments       NVARCHAR(1000) = NULL,
    @EntryDate      DATETIME       = NULL,
    
    -- Metadata Fields
    @SST_Id              BIGINT        = NULL,
    @BatchSize           INT           = NULL,
    @DateFrom            VARCHAR(50)   = NULL,
    @DateTo              VARCHAR(50)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;


        -- 0.1 Parsing SeriesStart/End (Expect Format: "Prefix-Order-Serial" or "Order-Serial")
        DECLARE @StartOrder INT, @StartSerial INT;
        DECLARE @EndOrder   INT, @EndSerial   INT;

        -- 0.2 Automated Range Calculation (Next Available Range)
        IF ISNULL(@SeriesStart, '') = '' OR ISNULL(@SeriesEnd, '') = ''
        BEGIN
            IF @BatchSize IS NULL OR @BatchSize <= 0
            BEGIN
                SELECT 0 AS success, 'BatchSize is required for automated range calculation.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- Find the last assigned range from M_ServiceSubscription
            DECLARE @LastEndOrder INT, @LastEndSerial INT;
            SELECT TOP 1 @LastEndOrder = end_order, @LastEndSerial = end_series
            FROM M_ServiceSubscription
            WHERE Pro_ID = @Pro_ID AND end_order IS NOT NULL
            ORDER BY EntryDate DESC, Subscribe_Id DESC;

            IF @LastEndOrder IS NULL
            BEGIN
                -- First time: Get the first available code for this product
                SELECT TOP 1 @StartOrder = Series_Order, @StartSerial = Series_Serial
                FROM M_Code WHERE Pro_ID = @Pro_ID ORDER BY Series_Order, Series_Serial;
            END
            ELSE
            BEGIN
                -- Next available code after the last end
                SELECT TOP 1 @StartOrder = Series_Order, @StartSerial = Series_Serial
                FROM M_Code 
                WHERE Pro_ID = @Pro_ID 
                  AND (Series_Order > @LastEndOrder OR (Series_Order = @LastEndOrder AND Series_Serial > @LastEndSerial))
                ORDER BY Series_Order, Series_Serial;
            END

            IF @StartOrder IS NULL
            BEGIN
                SELECT 0 AS success, 'No available codes found in M_Code for this product.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- Get the end based on BatchSize
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
            
            -- Fallback for EndSerial if only one order
            IF @EndSerial IS NULL SELECT @EndSerial = MAX(Series_Serial) FROM (SELECT TOP (@BatchSize) * FROM NextBatch) t WHERE Series_Order = @EndOrder;

            -- Formatting for 4-4
            SET @SeriesStart = CONCAT(FORMAT(@StartOrder, '0000'), '-', FORMAT(@StartSerial, '0000'));
            SET @SeriesEnd = CONCAT(FORMAT(@EndOrder, '0000'), '-', FORMAT(@EndSerial, '0000'));
        END
        ELSE
        BEGIN
            -- Manual Parsing Logic (Skip BM58- part if present)
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

            -- BatchSize Validation (IF Batch Size IS provided)
            IF @BatchSize IS NOT NULL AND @BatchSize > 0
            BEGIN
                DECLARE @CalculatedCount INT;
                IF @StartOrder = @EndOrder
                BEGIN
                    SET @CalculatedCount = (@EndSerial - @StartSerial) + 1;
                END
                ELSE
                BEGIN
                    -- Count across orders
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

            -- 1.2 M_Code Assignment Validation (Check if any code is already assigned)
            IF EXISTS (
                SELECT 1 FROM M_Code 
                WHERE Pro_ID = @Pro_ID 
                  AND (Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
                  AND (Series_Order < @EndOrder OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial))
                  AND (Batch_No IS NOT NULL AND Batch_No <> '')
            )
            BEGIN
                SELECT 0 AS success, 'These codes are already assigned to another batch.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END
        END

        -- 2. Fetch latest plan details for the given Pro_ID and create a new Subscribe_Id
        DECLARE @PlanID_Last NVARCHAR(50), @PlanName_Last NVARCHAR(150), @PlanMasterPeriod_Last NUMERIC(18,0), @PlanSalePeriod_Last NUMERIC(18,0), @PlanMasterPrice_Last NUMERIC(18,0), @PlanSalePrice_Last NUMERIC(18,0);
        
        SELECT TOP 1 
            @PlanID_Last = Plan_ID, 
            @PlanName_Last = PlanName, 
            @PlanMasterPeriod_Last = PlanMasterPeriod, 
            @PlanSalePeriod_Last = PlanSalePeriod, 
            @PlanMasterPrice_Last = PlanMasterPrice, 
            @PlanSalePrice_Last = PlanSalePrice
        FROM M_ServiceSubscription
        WHERE Pro_ID = @Pro_ID
        ORDER BY EntryDate DESC, Subscribe_Id DESC;

        -- Fallback to defaults if no previous record exists
        SET @PlanID_Last = ISNULL(@PlanID_Last, 'PLAN_DEFAULT');
        SET @PlanName_Last = ISNULL(@PlanName_Last, 'Manual Subscription');
        SET @PlanMasterPeriod_Last = ISNULL(@PlanMasterPeriod_Last, 0);
        SET @PlanSalePeriod_Last = ISNULL(@PlanSalePeriod_Last, 0);
        SET @PlanMasterPrice_Last = ISNULL(@PlanMasterPrice_Last, 0);
        SET @PlanSalePrice_Last = ISNULL(@PlanSalePrice_Last, 0);

        DECLARE @PrPrefix VARCHAR(50), @PrStart BIGINT;
        SELECT @PrPrefix = PrPrefix, @PrStart = PrStart FROM Code_Gen WHERE Prfor = 'Subscription' AND PrPrefix = 'SSI';
        
        IF @PrPrefix IS NULL
        BEGIN
            -- Fallback if Code_Gen is missing entry
            SET @Subscribe_Id = 'SSI' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
        END
        ELSE
        BEGIN
            SET @Subscribe_Id = @PrPrefix + CAST(@PrStart AS VARCHAR(50));
            -- Increment the counter
            UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'Subscription' AND PrPrefix = 'SSI';
        END

        INSERT INTO M_ServiceSubscription
        (Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName, PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice, DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify, TransType, start_order, start_series, end_order, end_series)
        VALUES
        (@Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, @PlanID_Last, @PlanName_Last, @PlanMasterPeriod_Last, @PlanSalePeriod_Last, @PlanMasterPrice_Last, @PlanSalePrice_Last, 
         ISNULL(TRY_CAST(@DateFrom AS DATETIME), GETDATE()), 
         ISNULL(TRY_CAST(@DateTo AS DATETIME), DATEADD(YEAR, 1, GETDATE())), 
         GETDATE(), 0, 0, 1, 'Service', @StartOrder, @StartSerial, @EndOrder, @EndSerial);

        -- 3. Insert into M_ServiceSubscriptionTrans (Settings Transaction)
        INSERT INTO M_ServiceSubscriptionTrans
        (
            Subscribe_Id, DateFrom, DateTo, Comments, Entry_Date, Points, IsCashConvert, IsCash, Frequency, IsActive, IsDelete, Minval, Maxval, totalamont
        )
        VALUES
        (
            @Subscribe_Id, 
            CASE WHEN ISDATE(@DateFrom)=1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END,
            CASE WHEN ISDATE(@DateTo)=1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END,
            @Comments, ISNULL(@EntryDate, GETDATE()), 0, 1, 0, 1, 0, 0, 0, 0, 0
        );

        DECLARE @GeneratedSST_Id BIGINT = SCOPE_IDENTITY();

        -- 4. Get/Insert T_Pro (Product Batch Details)
        DECLARE @NewTPro_RowID BIGINT;
        SELECT @NewTPro_RowID = Row_ID FROM T_Pro WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;

        IF @NewTPro_RowID IS NULL
        BEGIN
            INSERT INTO T_Pro
            (
                Pro_ID, Batch_No, Comments, Entry_Date, Series_Limit
            )
            VALUES
            (
                @Pro_ID, @Batch_No, 
                @Comments, ISNULL(@EntryDate, GETDATE()),
                CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd)
            );
            SET @NewTPro_RowID = SCOPE_IDENTITY();
        END

        -- 5. Update M_Code (Batch assignment for code range)
        UPDATE M_Code
        SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50)),
            print_status = 1 
        WHERE Pro_ID = @Pro_ID 
          AND (Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
          AND (Series_Order < @EndOrder OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial))
          AND (Series_Order BETWEEN @StartOrder AND @EndOrder)
          AND (Batch_No IS NULL OR Batch_No = '');

        -- 5.4 Ensure M_ServiceSubscription record contains the range (ALREADY INSERTED WITH RANGE, BUT UPDATING AGAIN TO BE SURE/COMPATIBLE WITH FLOW)
        UPDATE M_ServiceSubscription
        SET start_order = @StartOrder,
            start_series = @StartSerial,
            end_order = @EndOrder,
            end_series = @EndSerial
        WHERE Subscribe_Id = @Subscribe_Id;

        -- 5.5 Call UpdateM_codeByBatch_No to set correctly formatted Series_Limit in T_Pro
        IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UpdateM_codeByBatch_No' AND type = 'P')
        BEGIN
            EXEC UpdateM_codeByBatch_No @NewTPro_RowID, @Pro_ID;
        END

        -- 6. Insert into M_ServiceSubscriptionTracTrace_MasterCodeLess (Metadata Storage)
        INSERT INTO M_ServiceSubscriptionTracTrace_MasterCodeLess
        (
            SST_Id, Pro_ID, Service_ID, Subscribe_Id, BatchSize, Batch_No, SeriesStart, SeriesEnd, EntryDate
        )
        VALUES
        (
            @GeneratedSST_Id, @Pro_ID, @Service_ID, @Subscribe_Id, @BatchSize, @Batch_No, @SeriesStart, @SeriesEnd, 
            GETDATE()
        );

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'TracTrace assignment completed successfully.' AS message, @GeneratedSST_Id AS NewSST_Id, @NewTPro_RowID AS NewTPro_RowID, @SeriesStart AS SeriesStart, @SeriesEnd AS SeriesEnd, @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
        BEGIN
            ROLLBACK TRANSACTION;
        END
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
