SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Drop Stored Procedure first if it exists, as it depends on the UDTT
IF OBJECT_ID('dbo.USP_AssignBulkUpload_PFL_AI', 'P') IS NOT NULL
    DROP PROCEDURE dbo.USP_AssignBulkUpload_PFL_AI
GO

-- Drop User-Defined Table Type if it exists
IF EXISTS (SELECT * FROM sys.types WHERE name = 'UDTT_AssignBulkUploadPFL' AND is_table_type = 1)
    DROP TYPE [dbo].[UDTT_AssignBulkUploadPFL]
GO

-- 2. Create User-Defined Table Type
CREATE TYPE [dbo].[UDTT_AssignBulkUploadPFL] AS TABLE(
    [Product] NVARCHAR(100) NULL,
    [SerialFrom] NVARCHAR(50) NULL,
    [SerialTo] NVARCHAR(50) NULL,
    [TotalUse] INT NULL,
    [ActualSpoolQty] NVARCHAR(50) NULL,
    [BatchNumber] NVARCHAR(100) NULL,
    [MfgDate] DATE NULL,
    [ExpDate] DATE NULL,
    [RequestDate] DATETIME NULL,
    [Remark] NVARCHAR(250) NULL
)
GO

-- =============================================
-- Author:      AI
-- Create date: 2026-07-30
-- Description: Bulk assign PFL Batch range mapping using User-Defined Table Type
-- =============================================
CREATE PROCEDURE [dbo].[USP_AssignBulkUpload_PFL_AI]
    @CompanyId      NVARCHAR(50),
    @BulkData       [dbo].[UDTT_AssignBulkUploadPFL] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Product NVARCHAR(100),
            @SerialFrom NVARCHAR(50),
            @SerialTo NVARCHAR(50),
            @TotalUse INT,
            @ActualSpoolQty NVARCHAR(50),
            @BatchNumber NVARCHAR(100),
            @MfgDate DATE,
            @ExpDate DATE,
            @RequestDate DATETIME,
            @Remark NVARCHAR(250);

    DECLARE @RowNumber INT = 0;
    DECLARE @SuccessCount INT = 0;
    DECLARE @FailedRows NVARCHAR(MAX) = '';

    DECLARE @CompEmail NVARCHAR(100);
    SELECT TOP 1 @CompEmail = Comp_Email FROM Comp_Reg WHERE Comp_ID = @CompanyId;

    BEGIN TRY
        -- We will NOT wrap the entire loop in one transaction, but we can do it so that successful rows are saved even if some fail.
        -- Or we can run them individually. Running them individually is safer for row-by-row success/failure report.

        DECLARE assign_cursor CURSOR LOCAL FAST_FORWARD FOR 
        SELECT 
            [Product], [SerialFrom], [SerialTo], 
            [TotalUse], [ActualSpoolQty], [BatchNumber], 
            [MfgDate], [ExpDate], [RequestDate], [Remark]
        FROM @BulkData;

        OPEN assign_cursor;
        FETCH NEXT FROM assign_cursor INTO 
            @Product, @SerialFrom, @SerialTo, 
            @TotalUse, @ActualSpoolQty, @BatchNumber, 
            @MfgDate, @ExpDate, @RequestDate, @Remark;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @RowNumber = @RowNumber + 1;

            BEGIN TRY
                -- 1. Validation: check required fields
                IF @Product IS NULL OR @Product = '' OR 
                   @SerialFrom IS NULL OR @SerialFrom = '' OR 
                   @SerialTo IS NULL OR @SerialTo = '' OR 
                   @TotalUse IS NULL OR @TotalUse <= 0 OR
                   @BatchNumber IS NULL OR @BatchNumber = '' OR
                   @MfgDate IS NULL OR @ExpDate IS NULL
                BEGIN
                    SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Missing required fields)';
                    GOTO NEXT_ROW;
                END

                -- 2. Parsing and calculation
                DECLARE @NewFromValue INT, @NewToValue INT;
                DECLARE @FromMiddle INT, @FromLast INT, @ToMiddle INT, @ToLast INT;
                DECLARE @BalanceQty FLOAT;

                -- Extract values from SerialFrom and SerialTo
                SET @FromMiddle = TRY_CAST(PARSENAME(REPLACE(@SerialFrom, '-', '.'), 2) AS INT);
                SET @FromLast = TRY_CAST(PARSENAME(REPLACE(@SerialFrom, '-', '.'), 1) AS INT);
                SET @ToMiddle = TRY_CAST(PARSENAME(REPLACE(@SerialTo, '-', '.'), 2) AS INT);
                SET @ToLast = TRY_CAST(PARSENAME(REPLACE(@SerialTo, '-', '.'), 1) AS INT);

                IF @FromMiddle IS NULL OR @FromLast IS NULL OR @ToMiddle IS NULL OR @ToLast IS NULL
                BEGIN
                    SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Invalid format for SerialFrom or SerialTo)';
                    GOTO NEXT_ROW;
                END

                SET @NewFromValue = @FromMiddle * 10000 + @FromLast;
                SET @NewToValue = @ToMiddle * 10000 + @ToLast;

                DECLARE @SpoolQtyFloat FLOAT = TRY_CAST(@ActualSpoolQty AS FLOAT);
                IF @SpoolQtyFloat IS NULL
                    SET @SpoolQtyFloat = 0;

                SET @BalanceQty = @TotalUse - @SpoolQtyFloat;

                -- 3. Insert record into PFL_Batchlist
                INSERT INTO PFL_Batchlist
                    ([Date Of Mfg], [Expire Date], [SKU], [Batch No], [FROM], [TO],
                     [Total Use ], [Actual Spool Qty], [Bal Qty], [Diff QR V Prd],
                     [Remarks], [RequestDate], [Assigned By])
                VALUES
                    (@MfgDate, @ExpDate, @Product, @BatchNumber, @SerialFrom, @SerialTo,
                     @TotalUse, @ActualSpoolQty, @BalanceQty, NULL,
                     @Remark, ISNULL(@RequestDate, GETDATE()), @CompEmail);

                SET @SuccessCount = @SuccessCount + 1;
            END TRY
            BEGIN CATCH
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (' + ERROR_MESSAGE() + ')';
            END CATCH

        NEXT_ROW:
            FETCH NEXT FROM assign_cursor INTO 
                @Product, @SerialFrom, @SerialTo, 
                @TotalUse, @ActualSpoolQty, @BatchNumber, 
                @MfgDate, @ExpDate, @RequestDate, @Remark;
        END

        CLOSE assign_cursor;
        DEALLOCATE assign_cursor;

        IF @SuccessCount > 0
        BEGIN
            IF ISNULL(@FailedRows, '') = ''
                SELECT 1 AS success, 'Bulk code assignment completed successfully. ' + CAST(@SuccessCount AS VARCHAR(10)) + ' ranges assigned.' AS message;
            ELSE
                SELECT 1 AS success, 'Bulk code assignment completed. ' + CAST(@SuccessCount AS VARCHAR(10)) + ' ranges assigned. Skipped rows with issues: ' + @FailedRows AS message;
        END
        ELSE
        BEGIN
            SELECT 0 AS success, 'Bulk code assignment failed. All rows had issues: ' + @FailedRows AS message;
        END

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'assign_cursor') >= 0
        BEGIN
            CLOSE assign_cursor;
            DEALLOCATE assign_cursor;
        END

        SELECT 0 AS success, 'Database Error: ' + ERROR_MESSAGE() AS message;
    END CATCH
END
GO
