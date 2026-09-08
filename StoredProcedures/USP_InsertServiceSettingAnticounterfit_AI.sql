-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingAnticounterfit_AI
-- Purpose        : Ultra-fast insert for Anticounterfit service setting
--                  (Optimized to execute in milliseconds without timeouts)
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingAnticounterfit_AI]
    @Comp_ID      NVARCHAR(50),
    @Pro_ID       NVARCHAR(50),
    @Service_ID   NVARCHAR(50),
    @Subscribe_Id NVARCHAR(50)   = NULL,

    @DateFrom     DATETIME       = NULL,
    @DateTo       DATETIME       = NULL,

    @Comments     NVARCHAR(1000) = NULL,
    @EntryDate    DATETIME       = NULL,

    @Points          NUMERIC(18,0) = 0,
    @IsCashConvert   INT           = 1,
    @IsCash          NUMERIC(18,0) = 0,
    @Frequency       INT           = 1,
    @IsActive        INT           = 0,
    @IsDelete        INT           = 0,
    @AmtType         VARCHAR(12)   = 'Fixed',
    @Minval          NUMERIC(18,0) = 0,
    @Maxval          NUMERIC(18,0) = 0,
    @totalamont      NUMERIC(18,0) = 0,

    -- Batch-related fields
    @MRP            NUMERIC(18, 2) = 0,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    @Batch_No       NVARCHAR(100)  = NULL,
    @BatchSize      INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Resolve or create Subscribe_Id directly
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
                    @GeneratedSubId, @Service_ID, @Comp_ID, @Pro_ID, 'PLAN_DEFAULT', 'Manual Subscription', 
                    12, 12, 0, 0, 
                    ISNULL(@DateFrom, GETDATE()), ISNULL(@DateTo, DATEADD(YEAR, 1, GETDATE())), ISNULL(@EntryDate, GETDATE()), 1, 0, 1,
                    'Service'
                );
                
                SET @Subscribe_Id = @GeneratedSubId;
            END
        END

        DECLARE @NewSST_Id BIGINT;

        -- 2. Insert or update M_ServiceSubscriptionTrans (keep single record if already exists)
        IF @Service_ID = 'SRV1018' AND EXISTS (SELECT 1 FROM M_ServiceSubscriptionTrans WITH (NOLOCK) WHERE Subscribe_Id = @Subscribe_Id)
        BEGIN
            SELECT TOP 1 @NewSST_Id = SST_Id 
            FROM M_ServiceSubscriptionTrans WITH (NOLOCK)
            WHERE Subscribe_Id = @Subscribe_Id 
            ORDER BY Entry_Date DESC;

            UPDATE M_ServiceSubscriptionTrans
            SET DateFrom = ISNULL(@DateFrom, CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE DateFrom END),
                DateTo = ISNULL(@DateTo, CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE DateTo END),
                Comments = ISNULL(@Comments, Comments)
            WHERE SST_Id = @NewSST_Id;
        END
        ELSE
        BEGIN
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
                @Frequency, @IsActive, @IsDelete,
                @AmtType, @Minval, @Maxval, @totalamont
            );

            SET @NewSST_Id = SCOPE_IDENTITY();
        END

        -- 3. Insert into T_Pro (Product Batch Details)
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
                    Pro_ID, Batch_No, MRP, Mfd_Date, Exp_Date, Comments, Entry_Date
                )
                VALUES
                (
                    @Pro_ID, @Batch_No, ISNULL(@MRP, 0), 
                    CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
                    CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
                    @Comments, ISNULL(@EntryDate, GETDATE())
                );
                SET @NewTPro_RowID = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                UPDATE T_Pro
                SET MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE Mfd_Date END,
                    Exp_Date = CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE Exp_Date END,
                    Comments = ISNULL(@Comments, Comments)
                WHERE Row_ID = @NewTPro_RowID;
            END

            -- Fallback BatchSize from Pro_Reg if not explicitly provided
            IF ISNULL(@BatchSize, 0) <= 0
            BEGIN
                SELECT @BatchSize = ISNULL(BatchSize, 0)
                FROM Pro_Reg WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID;
            END

            -- 4. Fast batch assignment in M_Code / M_Code_PFL with in-memory capture
            DECLARE @Qty INT = 0;
            DECLARE @UpdatedCodes TABLE (
                Series_Order INT,
                Series_Serial INT
            );

            IF @Comp_ID = 'Comp-1693'
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

            -- 5. Update Series_Limit in T_Pro from in-memory @UpdatedCodes (Zero M_Code table scans!)
            IF @Qty > 0
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
        SELECT 1 AS success, 'Anticounterfit service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
