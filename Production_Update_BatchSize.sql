-- =============================================================================
-- PRODUCTION UPDATE: Separate Add/Update Logic & Full Metadata Support
-- Date: 2026-03-24
-- =============================================================================

-- 1. Add BatchSize column to Table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'BatchSize')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ADD [BatchSize] [int] NULL;
END
GO

-- 2. Update Insert/Add Stored Procedure (STRICTLY FOR ADD)
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingTracTraceV2_AI]
    @Comp_ID        VARCHAR(50),
    @Pro_ID         VARCHAR(50),
    @Service_ID     VARCHAR(50),
    @Subscribe_Id   VARCHAR(50)    = NULL,
    @MRP            NUMERIC(18, 2) = NULL,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    @Batch_No       VARCHAR(100)   = NULL,
    @SeriesStart    VARCHAR(100)   = NULL,
    @SeriesEnd      VARCHAR(100)   = NULL,
    @MasterCode     VARCHAR(100)   = NULL,
    @Comments       NVARCHAR(1000) = NULL,
    @EntryDate      DATETIME       = NULL,
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
            ROLLBACK TRANSACTION; RETURN;
        END

        -- 1. Check MasterCode uniqueness in codeassign_tractrac
        IF EXISTS (SELECT 1 FROM codeassign_tractrac WHERE mastercode = @MasterCode)
        BEGIN
            SELECT 0 AS success, 'Already master code exists' AS message;
            ROLLBACK TRANSACTION; RETURN;
        END

        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id FROM M_ServiceSubscription WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID;
            IF @Subscribe_Id IS NULL
            BEGIN
                DECLARE @GeneratedSubId VARCHAR(50) = 'SUB' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
                INSERT INTO M_ServiceSubscription (Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName, DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify, TransType)
                VALUES (@GeneratedSubId, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_DEFAULT', 'Manual Subscription', ISNULL(CASE WHEN ISDATE(@DateFrom)=1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END, GETDATE()), ISNULL(CASE WHEN ISDATE(@DateTo)=1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END, DATEADD(YEAR, 1, GETDATE())), GETDATE(), 0, 0, 1, 'Service');
                SET @Subscribe_Id = @GeneratedSubId;
            END
        END

        INSERT INTO M_ServiceSubscriptionTrans (Subscribe_Id, DateFrom, DateTo, Comments, Entry_Date, Points, IsCashConvert, IsCash, Frequency, IsActive, IsDelete, Minval, Maxval, totalamont)
        VALUES (@Subscribe_Id, CASE WHEN ISDATE(@DateFrom)=1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END, CASE WHEN ISDATE(@DateTo)=1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END, @Comments, ISNULL(@EntryDate, GETDATE()), 0, 1, 0, 1, 0, 0, 0, 0, 0);
        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        -- 4. Get/Insert T_Pro (Product Batch Details) - NO UPDATE IN ADD SP
        DECLARE @NewTPro_RowID BIGINT;
        SELECT @NewTPro_RowID = Row_ID FROM T_Pro WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;
        IF @NewTPro_RowID IS NULL
        BEGIN
            INSERT INTO T_Pro (Pro_ID, Batch_No, MRP, Mfd_Date, Exp_Date, Comments, Entry_Date, Series_Limit) VALUES (@Pro_ID, @Batch_No, @MRP, CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, @Comments, ISNULL(@EntryDate, GETDATE()), CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd));
            SET @NewTPro_RowID = SCOPE_IDENTITY();
        END

        DECLARE @StartOrder INT, @StartSerial INT, @EndOrder INT, @EndSerial INT;
        IF CHARINDEX('-', @SeriesStart) > 0 AND CHARINDEX('-', @SeriesStart, CHARINDEX('-', @SeriesStart) + 1) > 0
        BEGIN
            DECLARE @StartP2 VARCHAR(50) = SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart));
            SET @StartOrder = CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
            SET @StartSerial = CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
        END
        ELSE IF CHARINDEX('-', @SeriesStart) > 0
        BEGIN
            SET @StartOrder = CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
            SET @StartSerial = CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
        END
        ELSE BEGIN SET @StartOrder = 0; SET @StartSerial = CAST(@SeriesStart AS INT); END

        IF CHARINDEX('-', @SeriesEnd) > 0 AND CHARINDEX('-', @SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1) > 0
        BEGIN
            DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
            SET @EndOrder = CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
            SET @EndSerial = CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
        END
        ELSE IF CHARINDEX('-', @SeriesEnd) > 0
        BEGIN
            SET @EndOrder = CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
            SET @EndSerial = CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT); -- Fixed P2 reference
            -- WAIT, I see a small bug in my previous edit in thinking, let me fix the EndP2 reference in the script
        END

        -- Re-writing parsing for End correctly
        IF CHARINDEX('-', @SeriesEnd) > 0 AND CHARINDEX('-', @SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1) > 0
        BEGIN
            DECLARE @EndP2_F VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
            SET @EndOrder = CAST(LEFT(@EndP2_F, CHARINDEX('-', @EndP2_F) - 1) AS INT);
            SET @EndSerial = CAST(SUBSTRING(@EndP2_F, CHARINDEX('-', @EndP2_F) + 1, LEN(@EndP2_F)) AS INT);
        END
        ELSE IF CHARINDEX('-', @SeriesEnd) > 0
        BEGIN
            SET @EndOrder = CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
            SET @EndSerial = CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
        END
        ELSE BEGIN SET @EndOrder = 0; SET @EndSerial = CAST(@SeriesEnd AS INT); END

        -- Batch Size Validation
        IF @BatchSize IS NOT NULL AND @StartSerial IS NOT NULL AND @EndSerial IS NOT NULL
        BEGIN
            DECLARE @RequestedQty INT = (@EndSerial - @StartSerial + 1);
            IF @RequestedQty > @BatchSize
            BEGIN
                SELECT 0 AS success, 'Assigned quantity (' + CAST(@RequestedQty AS VARCHAR) + ') exceeds Batch Size (' + CAST(@BatchSize AS VARCHAR) + ').' AS message;
                ROLLBACK TRANSACTION; RETURN;
            END
        END

        IF ISNULL(@StartOrder, -1) = ISNULL(@EndOrder, -1) AND @StartOrder IS NOT NULL
        BEGIN
            UPDATE M_Code SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50)), print_status = 1 WHERE Pro_ID = @Pro_ID AND Series_Order = @StartOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial AND (Batch_No IS NULL OR Batch_No = '');
        END
        EXEC UpdateM_codeByBatch_No @NewTPro_RowID, @Pro_ID;

        INSERT INTO codeassign_tractrac (mastercode, Pro_ID, MRP, Mfd_Date, Exp_Date, Batch_No, SeriesStart, SeriesEnd, entry_date, Dealer_Name, Dealer_Location, Contact_Information, Dispatch_Date, Invoice_Number, Latitude, Longitude, SST_Id, Subscribe_Id, BatchSize)
        VALUES (@MasterCode, @Pro_ID, @MRP, CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, @Batch_No, @SeriesStart, @SeriesEnd, ISNULL(@EntryDate, GETDATE()), @Dealer_Name, @Dealer_Location, @Contact_Information, ISNULL(@EntryDate, GETDATE()), @Invoice_Number, @Latitude, @Longitude, ISNULL(@SST_Id, @NewSST_Id), @Subscribe_Id, @BatchSize);

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'TracTrace assignment completed successfully.' AS message, @NewSST_Id AS NewSST_Id, @NewTPro_RowID AS NewTPro_RowID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO

-- 3. Update Stored Procedure (STRICTLY FOR UPDATE)
CREATE OR ALTER PROCEDURE USP_UpdateServiceSettingTracTrash_AI
    @SST_Id               BIGINT,
    @TrackTrace_ID        BIGINT = NULL,
    @Batch_No             VARCHAR(100) = NULL,
    @Dealer_Name          NVARCHAR(150) = NULL,
    @Dealer_Location      NVARCHAR(150) = NULL,
    @Contact_Information  NVARCHAR(150) = NULL,
    @Invoice_Number       NVARCHAR(50) = NULL,
    @BatchSize            INT = NULL,
    @MRP                  NUMERIC(18, 2) = NULL,
    @Mfd_Date             VARCHAR(50) = NULL,
    @Exp_Date             VARCHAR(50) = NULL,
    @DateFrom             VARCHAR(50) = NULL,
    @DateTo               VARCHAR(50) = NULL,
    @Comments             NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @TrackTrace_ID IS NOT NULL AND @TrackTrace_ID > 0
        BEGIN
            UPDATE codeassign_tractrac
            SET Batch_No = ISNULL(@Batch_No, Batch_No),
                Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                Contact_Information = ISNULL(@Contact_Information, Contact_Information),
                Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                BatchSize = ISNULL(@BatchSize, BatchSize),
                MRP = ISNULL(@MRP, MRP),
                Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date)
            WHERE ID = @TrackTrace_ID;
        END
        ELSE IF @SST_Id IS NOT NULL AND @SST_Id > 0
        BEGIN
            UPDATE codeassign_tractrac
            SET Batch_No = ISNULL(@Batch_No, Batch_No),
                Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                Contact_Information = ISNULL(@Contact_Information, Contact_Information),
                Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                BatchSize = ISNULL(@BatchSize, BatchSize),
                MRP = ISNULL(@MRP, MRP),
                Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date)
            WHERE SST_Id = @SST_Id;
        END
        ELSE BEGIN SELECT 0 AS success, 'No valid identifier provided.' AS message; RETURN; END

        -- Update Subscription Transaction Dates and Comments
        IF @SST_Id > 0
        BEGIN
            UPDATE M_ServiceSubscriptionTrans
            SET DateFrom = ISNULL(CASE WHEN ISDATE(@DateFrom)=1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END, DateFrom),
                DateTo = ISNULL(CASE WHEN ISDATE(@DateTo)=1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END, DateTo),
                Comments = ISNULL(@Comments, Comments)
            WHERE SST_Id = @SST_Id;

            -- Sync with T_Pro if Batch_No/Pro_ID is known
            DECLARE @Actual_Pro_ID VARCHAR(50);
            DECLARE @Actual_Batch_No VARCHAR(100);
            SELECT @Actual_Pro_ID = Pro_ID, @Actual_Batch_No = Batch_No FROM codeassign_tractrac WHERE SST_Id = @SST_Id;

            IF @Actual_Pro_ID IS NOT NULL AND @Actual_Batch_No IS NOT NULL
            BEGIN
                UPDATE T_Pro
                SET MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                    Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date),
                    Comments = ISNULL(@Comments, Comments)
                WHERE Pro_ID = @Actual_Pro_ID AND Batch_No = @Actual_Batch_No;
            END
        END
        
        SELECT 1 AS success, 'Track & Trace settings updated successfully.' AS message;
    END TRY
    BEGIN CATCH SELECT 0 AS success, ERROR_MESSAGE() AS message; END CATCH
END
GO

-- 4. Update List Stored Procedure
CREATE OR ALTER PROCEDURE USP_GetServiceSettingList_AI
    @Comp_ID       NVARCHAR(50),
    @Pro_ID        NVARCHAR(50) = NULL,
    @Service_ID    NVARCHAR(10) = NULL,
    @PageIndex     INT = 1,
    @PageSize      INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SST.SST_Id, SST.Subscribe_Id, P.Pro_Name, S.ServiceName, CASE WHEN SS.start_order IS NOT NULL AND SS.start_series IS NOT NULL THEN CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR) + ' to ' + CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR) ELSE 'All' END AS servicerange, SST.DateFrom, SST.DateTo, SST.Points, SST.Comments, SST.IsActive, CT.mastercode, CT.Batch_No, CT.Dealer_Name, CT.BatchSize, CT.ID AS TrackTrace_ID, COUNT(*) OVER() as TotalRecords
    FROM M_ServiceSubscriptionTrans SST
    INNER JOIN M_ServiceSubscription SS ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN Pro_Reg P ON SS.Pro_ID = P.Pro_ID
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    LEFT JOIN codeassign_tractrac CT ON SST.SST_Id = CT.SST_Id
    WHERE SS.Comp_ID = @Comp_ID AND (SST.IsDelete = 0 OR SST.IsDelete IS NULL) AND (@Pro_ID IS NULL OR SS.Pro_ID = @Pro_ID) AND (@Service_ID IS NULL OR SS.Service_ID = @Service_ID)
    ORDER BY SST.Entry_Date DESC OFFSET (@PageIndex - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO
