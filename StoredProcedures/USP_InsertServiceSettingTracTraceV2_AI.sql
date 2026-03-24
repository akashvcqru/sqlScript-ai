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
    @Contact_Information NVARCHAR(150) = NULL,
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

        -- 2. Ensure Subscribe_Id exists or create one if missing (as requested)
        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID;
            
            -- If still missing, create a new subscription entry (Legacy style)
            IF @Subscribe_Id IS NULL
            BEGIN
                -- This is a simplified creation. Usually ID is generated.
                -- For now, let's assume we need to return an error if subscription is missing,
                -- OR we can try to find an existign one across the company if it's a generic service.
                -- The user said "add entry in m_servicesubscription", so I'll insert a default one if needed.
                
                -- GENERATE ID (Mocking Utility.GetMyGenID logic)
                DECLARE @GeneratedSubId VARCHAR(50) = 'SUB' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
                
                INSERT INTO M_ServiceSubscription
                (Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName, DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify, TransType)
                VALUES
                (@GeneratedSubId, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_DEFAULT', 'Manual Subscription', ISNULL(CASE WHEN ISDATE(@DateFrom)=1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END, GETDATE()), ISNULL(CASE WHEN ISDATE(@DateTo)=1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END, DATEADD(YEAR, 1, GETDATE())), GETDATE(), 0, 0, 1, 'Service');
                
                SET @Subscribe_Id = @GeneratedSubId;
            END
        END

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
        -- Parsing SeriesStart/End (Expect Format: "Prefix-Order-Serial")
        DECLARE @StartOrder INT, @StartSerial INT;
        DECLARE @EndOrder   INT, @EndSerial   INT;

        -- Helper Logic: Parse 3-part format (e.g., BM58-00-0011)
        IF CHARINDEX('-', @SeriesStart) > 0 AND CHARINDEX('-', @SeriesStart, CHARINDEX('-', @SeriesStart) + 1) > 0
        BEGIN
            -- 3 parts detected
            DECLARE @StartP2 VARCHAR(50) = SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart));
            SET @StartOrder = CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
            SET @StartSerial = CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
        END
        ELSE IF CHARINDEX('-', @SeriesStart) > 0
        BEGIN
            -- 2 parts fallback (Order-Serial)
            SET @StartOrder = CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
            SET @StartSerial = CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
        END
        ELSE
        BEGIN
            SET @StartOrder = 0; SET @StartSerial = CAST(@SeriesStart AS INT);
        END

        IF CHARINDEX('-', @SeriesEnd) > 0 AND CHARINDEX('-', @SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1) > 0
        BEGIN
            DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
            SET @EndOrder = CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
            SET @EndSerial = CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
        END
        ELSE IF CHARINDEX('-', @SeriesEnd) > 0
        BEGIN
            SET @EndOrder = CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
            SET @EndSerial = CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
        END
        ELSE
        BEGIN
            SET @EndOrder = 0; SET @EndSerial = CAST(@SeriesEnd AS INT);
        END

        -- 5.3 Batch Size Validation
        IF @BatchSize IS NOT NULL AND @StartSerial IS NOT NULL AND @EndSerial IS NOT NULL
        BEGIN
            DECLARE @RequestedQty INT = (@EndSerial - @StartSerial + 1);
            IF @RequestedQty > @BatchSize
            BEGIN
                SELECT 0 AS success, 'Assigned quantity (' + CAST(@RequestedQty AS VARCHAR) + ') exceeds Batch Size (' + CAST(@BatchSize AS VARCHAR) + ').' AS message;
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- If orders are the same, update the range
        IF ISNULL(@StartOrder, -1) = ISNULL(@EndOrder, -1) AND @StartOrder IS NOT NULL
        BEGIN
            UPDATE M_Code
            SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50)),
                print_status = 1 -- Ensure codes are marked as assigned/printed for the update SP
            WHERE Pro_ID = @Pro_ID 
              AND Series_Order = @StartOrder 
              AND Series_Serial BETWEEN @StartSerial AND @EndSerial
              AND (Batch_No IS NULL OR Batch_No = '');
        END

        -- 5.5 Call UpdateM_codeByBatch_No to set correctly formatted Series_Limit
        EXEC UpdateM_codeByBatch_No @NewTPro_RowID, @Pro_ID;

        -- 6. Insert into codeassign_tractrac (Master Code Assignment)
            mastercode, Pro_ID, MRP, Mfd_Date, Exp_Date, Batch_No, SeriesStart, SeriesEnd, entry_date, 
            Dealer_Name, Dealer_Location, Contact_Information, Dispatch_Date, Invoice_Number, Latitude, Longitude,
            SST_Id, Subscribe_Id, BatchSize
        )
        VALUES
        (
            @MasterCode, @Pro_ID, @MRP, 
            CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
            CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
            @Batch_No, @SeriesStart, @SeriesEnd, ISNULL(@EntryDate, GETDATE()), 
            @Dealer_Name, @Dealer_Location, @Contact_Information, ISNULL(@EntryDate, GETDATE()), @Invoice_Number, @Latitude, @Longitude,
            ISNULL(@SST_Id, @NewSST_Id), @Subscribe_Id, @BatchSize
        );

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'TracTrace assignment completed successfully.' AS message, @NewSST_Id AS NewSST_Id, @NewTPro_RowID AS NewTPro_RowID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
