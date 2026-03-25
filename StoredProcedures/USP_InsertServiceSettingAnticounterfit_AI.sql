-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingAnticounterfit_AI
-- Purpose        : Insert Anticounterfit service setting.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingAnticounterfit_AI]
    @Comp_ID      VARCHAR(50),
    @Pro_ID       VARCHAR(50),
    @Service_ID   VARCHAR(50),
    @Subscribe_Id VARCHAR(50)   = NULL,

    @DateFrom     DATETIME      = NULL,
    @DateTo       DATETIME      = NULL,

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

    -- Batch-related fields (Like TracTrace)
    @MRP            NUMERIC(18, 2) = NULL,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    -- Batch-related fields (Like TracTrace)
    @MRP            NUMERIC(18, 2) = NULL,
    @Mfd_Date       VARCHAR(50)    = NULL,
    @Exp_Date       VARCHAR(50)    = NULL,
    @Batch_No       VARCHAR(100)   = NULL,
    @BatchSize      INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Resolve/Create Subscribe_Id with automated sequencing
        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID
            ORDER BY EntryDate DESC;
            
            IF @Subscribe_Id IS NULL
            BEGIN
                DECLARE @GeneratedSubId VARCHAR(50) = 'SUB' + CAST(CAST(RAND() * 1000000 AS INT) AS VARCHAR(10));
                
                -- Call the centralized SP for new subscription creation with sequence logic
                EXEC USP_InsertUpdateServiceSubscription_AI 
                    @Subscribe_Id = @GeneratedSubId,
                    @Service_ID = @Service_ID,
                    @Comp_ID = @Comp_ID,
                    @Pro_ID = @Pro_ID,
                    @BatchSize = @BatchSize,
                    @DML = 'I';
                
                SET @Subscribe_Id = @GeneratedSubId;
            END
        END

        -- 2. Insert into M_ServiceSubscriptionTrans
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

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        -- 3. Upsert into T_Pro (Product Batch Details - Mirroring TracTrace logic)
        IF @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            DECLARE @NewTPro_RowID BIGINT;
            SELECT @NewTPro_RowID = Row_ID FROM T_Pro WHERE Pro_ID = @Pro_ID AND Batch_No = @Batch_No;

            IF @NewTPro_RowID IS NOT NULL
            BEGIN
                UPDATE T_Pro
                SET MRP = @MRP,
                    Mfd_Date = CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
                    Exp_Date = CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
                    Comments = @Comments,
                    Entry_Date = ISNULL(@EntryDate, GETDATE())
                WHERE Row_ID = @NewTPro_RowID;
            END
            ELSE
            BEGIN
                INSERT INTO T_Pro
                (
                    Pro_ID, Batch_No, MRP, Mfd_Date, Exp_Date, Comments, Entry_Date
                )
                VALUES
                (
                    @Pro_ID, @Batch_No, @MRP, 
                    CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
                    CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
                    @Comments, ISNULL(@EntryDate, GETDATE())
                );
                SET @NewTPro_RowID = SCOPE_IDENTITY();
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
