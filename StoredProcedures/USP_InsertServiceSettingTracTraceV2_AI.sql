SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingTracTraceV2_AI]
    @Comp_ID        VARCHAR(50),
    @Pro_ID         VARCHAR(50),
    @Service_ID     VARCHAR(50),
    @Subscribe_Id   VARCHAR(50)    = NULL,
    @MRP            NUMERIC(18, 2) = NULL,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    @Batch_No       VARCHAR(100)   = NULL,
    @SeriesStart    VARCHAR(100)   = NULL, -- Format: "Order-SerialFrom"
    @SeriesEnd      VARCHAR(100)   = NULL, -- Format: "Order-SerialTo"
    @MasterCode     VARCHAR(100)   = NULL,
    @Comments       NVARCHAR(1000) = NULL,
    @EntryDate      DATETIME       = NULL,
    
    -- New Fields
    @Dealer_Name         NVARCHAR(150) = NULL,
    @Dealer_Location     NVARCHAR(150) = NULL,
    @Mobile              NVARCHAR(150) = NULL, -- Replaces @Contact_Information
    @Email               NVARCHAR(150) = NULL,
    @Invoice_Number      NVARCHAR(50)  = NULL,
    @Latitude            NVARCHAR(50)  = NULL,
    @Longitude           NVARCHAR(50)  = NULL,
    @SST_Id              BIGINT        = NULL,
    @BatchSize           INT           = NULL,
    @DateFrom            VARCHAR(50)   = NULL,
    @DateTo              VARCHAR(50)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 0. Validate Compulsory Manufacturing Date
        IF @Mfd_Date IS NULL OR @Mfd_Date = '' OR @Mfd_Date = 'string'
        BEGIN
            SELECT 0 AS success, 'Manufacturing Date is compulsory.' AS message;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 1. Check MasterCode uniqueness in codeassign_tractrac
        IF EXISTS (SELECT 1 FROM codeassign_tractrac WHERE mastercode = @MasterCode)
        BEGIN
            SELECT 0 AS success, 'Already master code exists' AS message;
            ROLLBACK TRANSACTION;
            RETURN;
        END

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

            SET @SeriesStart = CONCAT(@StartOrder, '-', FORMAT(@StartSerial, '0000')); -- Fallback simple
            -- Better formatting for 4-4
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
            
            DECLARE @ExpectedRangeCount INT = 0;
            IF @StartOrder = @EndOrder SET @ExpectedRangeCount = (@EndSerial - @StartSerial) + 1;
            -- (Note: Accurate cross-order expected count requires more logic, relying on @ExistingCount for now)

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
                    SELECT 0 AS success, CONCAT('number of codes will be equel not lesstehn or greator then (Expected: ', @BatchSize, ', Found: ', @CalculatedCount, ')') AS message;
                    ROLLBACK TRANSACTION; RETURN;
                END
            END

            -- 1.2 MasterCode Presence Check & Parsing
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

            -- 1.3 M_Code Assignment Validation (Check if any code is already assigned)
            IF EXISTS (
                SELECT 1 FROM M_Code 
                WHERE Pro_ID = @Pro_ID 
                  AND (
                      ((Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSerial))
                       AND (Series_Order < @EndOrder OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial)))
                      OR (master_code = @MasterCode 
                          OR (Series_Order = @MasterOrd AND Series_Serial = @MasterSer))
                  )
                  AND (Batch_No IS NOT NULL AND Batch_No <> '')
            )
            BEGIN
                SELECT 0 AS success, 'these codes (or master code) are already assigned to other sst id' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- 1.4 MasterCode Presence Check in Database
            IF NOT EXISTS (
                SELECT 1 FROM M_Code 
                WHERE Pro_ID = @Pro_ID 
                  AND (master_code = @MasterCode 
                       OR (Series_Order = @MasterOrd AND Series_Serial = @MasterSer))
            )
            BEGIN
                SELECT 0 AS success, 'MasterCode does not exist for the selected product.' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END

            -- 1.4 MasterCode Count Logic
            DECLARE @IsMasterInBatch BIT = 0;
            IF @MasterOrd IS NOT NULL AND @MasterSer IS NOT NULL
            BEGIN
                IF (@MasterOrd > @StartOrder OR (@MasterOrd = @StartOrder AND @MasterSer >= @StartSerial))
                   AND (@MasterOrd < @EndOrder OR (@MasterOrd = @EndOrder AND @MasterSer <= @EndSerial))
                BEGIN
                    SET @IsMasterInBatch = 1;
                END
            END

            -- Conditional Validation: If MasterCode prefix matches Pro_ID prefix, it MUST be in range
            -- Note: Using LEFT(@Pro_ID, 4) etc. as per user requirement "match with pro_id ... first four leter"
            IF LEFT(@Pro_ID, 4) = LEFT(@SeriesStart, 4) 
               AND LEFT(@Pro_ID, 4) = LEFT(@SeriesEnd, 4) 
               AND LEFT(@Pro_ID, 4) = LEFT(@MasterCode, 4)
            BEGIN
                IF @IsMasterInBatch = 0
                BEGIN
                    SELECT 0 AS success, 'MasterCode must be between SeriesStart and SeriesEnd for matching product prefixes.' AS message;
                    ROLLBACK TRANSACTION; RETURN;
                END
            END

            -- If MasterCode is outside the range, it's an extra code
            DECLARE @TotalBatchSize INT = @BatchSize;
            IF @IsMasterInBatch = 0
            BEGIN
                SET @TotalBatchSize = ISNULL(@BatchSize, 0) + 1;
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
            -- Fallback if Code_Gen is missing specific entry
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

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        -- 4. Get/Insert T_Pro (Product Batch Details)
        DECLARE @NewTPro_RowID BIGINT;
        SELECT @NewTPro_RowID = Row_ID FROM T_Pro WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;

        IF @NewTPro_RowID IS NULL
        BEGIN
            INSERT INTO T_Pro
            (
                Pro_ID, Batch_No, MRP, Mfd_Date, Exp_Date, Comments, Entry_Date, Series_Limit
            )
            VALUES
            (
                @Pro_ID, @Batch_No, @MRP, 
                CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
                CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
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

        -- 5.1 If MasterCode is outside the range, update its Batch_No separately
        IF @IsMasterInBatch = 0
        BEGIN
            UPDATE M_Code
            SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50)),
                print_status = 1
            WHERE Pro_ID = @Pro_ID 
              AND (master_code = @MasterCode 
                   OR (Series_Order = @MasterOrd AND Series_Serial = @MasterSer));
        END

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

        -- 6. Insert into codeassign_tractrac (Master Code Assignment)
        INSERT INTO codeassign_tractrac (
            mastercode, Pro_ID, MRP, Mfd_Date, Exp_Date, Batch_No, SeriesStart, SeriesEnd, entry_date, 
            Dealer_Name, Dealer_Location, Mobile, Email, Contact_Information, Dispatch_Date, Invoice_Number, Latitude, Longitude,
            SST_Id, Subscribe_Id, BatchSize
        )
        VALUES
        (
            @MasterCode, @Pro_ID, @MRP, 
            CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
            CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
            @Batch_No, @SeriesStart, @SeriesEnd, ISNULL(@EntryDate, GETDATE()), 
            @Dealer_Name, @Dealer_Location, @Mobile, @Email, @Mobile, ISNULL(@EntryDate, GETDATE()), @Invoice_Number, @Latitude, @Longitude,
            ISNULL(@SST_Id, @NewSST_Id), @Subscribe_Id, @TotalBatchSize
        );

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'TracTrace assignment completed successfully.' AS message, @NewSST_Id AS NewSST_Id, @NewTPro_RowID AS NewTPro_RowID, @SeriesStart AS SeriesStart, @SeriesEnd AS SeriesEnd, @Subscribe_Id AS Subscribe_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
