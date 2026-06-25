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
    @MRP            NUMERIC(18, 2) = 0,
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

        DECLARE @NewSST_Id BIGINT;

        -- 2. Insert into M_ServiceSubscriptionTrans (keep only a single record for service SRV1018)
        IF @Service_ID = 'SRV1018' AND EXISTS (SELECT 1 FROM M_ServiceSubscriptionTrans WHERE Subscribe_Id = @Subscribe_Id)
        BEGIN
            SELECT TOP 1 @NewSST_Id = SST_Id 
            FROM M_ServiceSubscriptionTrans 
            WHERE Subscribe_Id = @Subscribe_Id 
            ORDER BY Entry_Date DESC;
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

        -- 3. Always Insert into T_Pro (Product Batch Details) for each setting request
        IF @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            DECLARE @NewTPro_RowID BIGINT;

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

            -- Update in M_Code table Batch_No where Batch_No is NULL (series-wise using BatchSize)
            DECLARE @Qty INT = 0;
            IF ISNULL(@BatchSize, 0) > 0
            BEGIN
                WITH CTE AS (
                    SELECT TOP (@BatchSize) Batch_No
                    FROM M_Code
                    WHERE Pro_ID = @Pro_ID AND Batch_No IS NULL
                    ORDER BY Series_Order, Series_Serial
                )
                UPDATE CTE
                SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50));
            END
            ELSE
            BEGIN
                UPDATE M_Code
                SET Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50))
                WHERE Pro_ID = @Pro_ID AND Batch_No IS NULL;
            END

            SET @Qty = @@ROWCOUNT;

            -- Update Series_Limit in T_Pro table if codes were updated
            IF @Qty > 0
            BEGIN
                DECLARE @SeriesLimitStr NVARCHAR(500);
                SELECT 
                    @SeriesLimitStr = 
                        (SELECT TOP 1 'From  ' + Pro_ID + '-' + 
                            (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' +
                            (CASE 
                                WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                                WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                                WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                                ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                            END)
                         FROM [M_Code] 
                         WHERE Pro_ID = @Pro_ID AND Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50))
                         ORDER BY [Series_Order], [Series_Serial]) 
                        + '   ' +
                        (SELECT TOP 1 'To  ' + Pro_ID + '-' + 
                            (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' +
                            (CASE 
                                WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                                WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                                WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                                ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                            END)
                         FROM [M_Code] 
                         WHERE Pro_ID = @Pro_ID AND Batch_No = CAST(@NewTPro_RowID AS VARCHAR(50))
                         ORDER BY [Series_Order] DESC, [Series_Serial] DESC)
                        + ' (qty ' + CAST(@Qty AS VARCHAR(20)) + ')';

                UPDATE T_Pro
                SET Series_Limit = @SeriesLimitStr
                WHERE Row_ID = @NewTPro_RowID;
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
