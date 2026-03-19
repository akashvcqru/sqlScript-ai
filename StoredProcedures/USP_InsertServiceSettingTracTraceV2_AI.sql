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
    @EntryDate      DATETIME       = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

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
                (@GeneratedSubId, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_DEFAULT', 'Manual Subscription', ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, GETDATE()), ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, DATEADD(YEAR, 1, GETDATE())), GETDATE(), 0, 0, 1, 'Service');
                
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
            CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
            CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
            @Comments, ISNULL(@EntryDate, GETDATE()), 0, 1, 0, 1, 0, 0, 0, 0, 0
        );

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        -- 4. Insert into T_Pro (Product Batch Details)
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
            CONCAT('From ', @Pro_ID, '-00-', @SeriesStart, ' To ', @Pro_ID, '-00-', @SeriesEnd)
        );

        DECLARE @NewTPro_RowID BIGINT = SCOPE_IDENTITY();

        -- 5. Update M_Code (Batch assignment for code range)
        -- Parsing SeriesStart/End (Format: "Order-Serial" or just "Serial")
        DECLARE @StartOrder INT, @StartSerial INT;
        DECLARE @EndOrder   INT, @EndSerial   INT;

        IF CHARINDEX('-', @SeriesStart) > 0
        BEGIN
            SET @StartOrder = CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
            SET @StartSerial = CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
        END
        ELSE IF @SeriesStart IS NOT NULL AND @SeriesStart <> ''
        BEGIN
            SET @StartOrder = 0;
            SET @StartSerial = CAST(@SeriesStart AS INT);
        END

        IF CHARINDEX('-', @SeriesEnd) > 0
        BEGIN
            SET @EndOrder = CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
            SET @EndSerial = CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
        END
        ELSE IF @SeriesEnd IS NOT NULL AND @SeriesEnd <> ''
        BEGIN
            SET @EndOrder = 0;
            SET @EndSerial = CAST(@SeriesEnd AS INT);
        END

        -- If orders are the same, update the range
        IF ISNULL(@StartOrder, -1) = ISNULL(@EndOrder, -1) AND @StartOrder IS NOT NULL
        BEGIN
            UPDATE M_Code
            SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50)) -- Batch_No in M_Code usually stores T_Pro.Row_ID
            WHERE Pro_ID = @Pro_ID 
              AND Series_Order = @StartOrder 
              AND Series_Serial BETWEEN @StartSerial AND @EndSerial;
        END

        -- 6. Insert into codeassign_tractrac (Master Code Assignment)
        INSERT INTO codeassign_tractrac
        (mastercode, Pro_ID, MRP, Mfd_Date, Exp_Date, Batch_No, SeriesStart, SeriesEnd, entry_date, Dealer_Name, Dealer_Location, Contact_Information, Dispatch_Date, Invoice_Number)
        VALUES
        (
            @MasterCode, @Pro_ID, @MRP, 
            CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
            CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
            @Batch_No, @SeriesStart, @SeriesEnd, ISNULL(@EntryDate, GETDATE()), '', '', '', ISNULL(@EntryDate, GETDATE()), ''
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
