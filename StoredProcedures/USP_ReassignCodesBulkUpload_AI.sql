USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Drop Stored Procedure first because it references the type
IF OBJECT_ID('USP_ReassignCodesBulkUpload_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_ReassignCodesBulkUpload_AI
GO

-- Drop User-Defined Table Type if it exists
IF EXISTS (SELECT * FROM sys.types WHERE name = 'UDTT_ReassignCodesBulk_AI' AND is_table_type = 1)
    DROP TYPE [dbo].[UDTT_ReassignCodesBulk_AI]
GO

-- 2. Create User-Defined Table Type
CREATE TYPE [dbo].[UDTT_ReassignCodesBulk_AI] AS TABLE(
    [AssignFromSeries] NVARCHAR(100),
    [AssignToSeries] NVARCHAR(100),
    [AssignToProID] NVARCHAR(100),
    [BatchNumber] NVARCHAR(50),
    [ManufacturingDate] DATETIME NULL,
    [ExpiryDate] DATETIME NULL
)
GO

-- =============================================
-- Author:      AI
-- Create date: 2026-06-26
-- Description: Bulk reassign assigned serial codes to a different product and batch
-- =============================================
CREATE PROCEDURE [dbo].[USP_ReassignCodesBulkUpload_AI]
    @Comp_ID        NVARCHAR(50),
    @ReassignTable  [dbo].[UDTT_ReassignCodesBulk_AI] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure T_ReassignCode table exists and has Comments column
    IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND type in (N'U'))
    BEGIN
        CREATE TABLE [dbo].[T_ReassignCode] (
            [ReassignCodeId] BIGINT IDENTITY(1,1) PRIMARY KEY,
            [Comp_ID] NVARCHAR(50),
            [OldProductId] NVARCHAR(50),
            [ReassignCodeProId] NVARCHAR(50),
            [Points] DECIMAL(18,2),
            [BatchNumber] NVARCHAR(50),
            [AssignDate] DATETIME NULL,
            [ExpiryDate] DATETIME NULL,
            [ServiceId] NVARCHAR(50),
            [Entry_Date] DATETIME,
            [T_Pro_Row_ID] BIGINT,
            [FromSeries] NVARCHAR(100),
            [ToSeries] NVARCHAR(100),
            [Comments] NVARCHAR(250) NULL,
            [Series_Order_From] INT NULL,
            [Series_Order_To] INT NULL,
            [Series_Serial_From] INT NULL,
            [Series_Serial_To] INT NULL
        );
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Comments')
            ALTER TABLE [dbo].[T_ReassignCode] ADD [Comments] NVARCHAR(250) NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Order_From')
            ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Order_From] INT NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Order_To')
            ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Order_To] INT NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Serial_From')
            ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Serial_From] INT NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Serial_To')
            ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Serial_To] INT NULL;
    END

    -- Cursor variables
    DECLARE @AssignFromSeries NVARCHAR(100),
            @AssignToSeries NVARCHAR(100),
            @AssignToProID NVARCHAR(100),
            @BatchNumber NVARCHAR(50),
            @ManufacturingDate DATETIME,
            @ExpiryDate DATETIME;

    -- Processing variables
    DECLARE @OrigProId NVARCHAR(50),
            @SeriesOrderFrom INT,
            @SerialFrom INT,
            @OrigProIdTo NVARCHAR(50),
            @SeriesOrderTo INT,
            @SerialTo INT,
            @TargetProId NVARCHAR(50),
            @TotalExpected INT,
            @ActualCount INT,
            @UsedCount INT,
            @AlreadyReassignedCount INT,
            @BatchNoStr NVARCHAR(50),
            @TProRowId BIGINT,
            @ServiceId NVARCHAR(50);

    DECLARE @RowNumber INT = 0;
    DECLARE @SuccessCount INT = 0;
    DECLARE @FailedRows NVARCHAR(MAX) = '';

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE reassign_cursor CURSOR LOCAL FAST_FORWARD FOR 
        SELECT 
            [AssignFromSeries], [AssignToSeries], [AssignToProID], 
            [BatchNumber], [ManufacturingDate], [ExpiryDate] 
        FROM @ReassignTable;

        OPEN reassign_cursor;
        FETCH NEXT FROM reassign_cursor INTO 
            @AssignFromSeries, @AssignToSeries, @AssignToProID, 
            @BatchNumber, @ManufacturingDate, @ExpiryDate;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @RowNumber = @RowNumber + 1;

            -- Reset variables for each iteration
            SET @SerialFrom = NULL;
            SET @SeriesOrderFrom = NULL;
            SET @OrigProId = NULL;
            SET @SerialTo = NULL;
            SET @SeriesOrderTo = NULL;
            SET @OrigProIdTo = NULL;
            SET @TargetProId = NULL;
            SET @TotalExpected = NULL;
            SET @ActualCount = NULL;
            SET @UsedCount = NULL;
            SET @AlreadyReassignedCount = NULL;
            SET @BatchNoStr = NULL;
            SET @TProRowId = NULL;
            SET @ServiceId = NULL;

            -- 1. Parse AssignFromSeries (Expected format: PROID-ORDER-SERIAL, e.g., BJ02-0012-5436)
            DECLARE @LastHyphenFrom INT = CHARINDEX('-', REVERSE(@AssignFromSeries));
            DECLARE @SecondLastHyphenFrom INT = CHARINDEX('-', REVERSE(@AssignFromSeries), @LastHyphenFrom + 1);
            
            IF @LastHyphenFrom = 0 OR @SecondLastHyphenFrom = 0
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Invalid AssignFromSeries format)';
                GOTO NEXT_ROW;
            END

            SET @SerialFrom = TRY_CAST(REVERSE(SUBSTRING(REVERSE(@AssignFromSeries), 1, @LastHyphenFrom - 1)) AS INT);
            SET @SeriesOrderFrom = TRY_CAST(REVERSE(SUBSTRING(REVERSE(@AssignFromSeries), @LastHyphenFrom + 1, @SecondLastHyphenFrom - @LastHyphenFrom - 1)) AS INT);
            SET @OrigProId = SUBSTRING(@AssignFromSeries, 1, LEN(@AssignFromSeries) - @SecondLastHyphenFrom);

            IF @SerialFrom IS NULL OR @SeriesOrderFrom IS NULL OR @OrigProId IS NULL OR @OrigProId = ''
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Parse error in AssignFromSeries)';
                GOTO NEXT_ROW;
            END

            -- 2. Parse AssignToSeries (Expected format: PROID-ORDER-SERIAL, e.g., BJ02-0012-5440)
            DECLARE @LastHyphenTo INT = CHARINDEX('-', REVERSE(@AssignToSeries));
            DECLARE @SecondLastHyphenTo INT = CHARINDEX('-', REVERSE(@AssignToSeries), @LastHyphenTo + 1);

            IF @LastHyphenTo = 0 OR @SecondLastHyphenTo = 0
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Invalid AssignToSeries format)';
                GOTO NEXT_ROW;
            END

            SET @SerialTo = TRY_CAST(REVERSE(SUBSTRING(REVERSE(@AssignToSeries), 1, @LastHyphenTo - 1)) AS INT);
            SET @SeriesOrderTo = TRY_CAST(REVERSE(SUBSTRING(REVERSE(@AssignToSeries), @LastHyphenTo + 1, @SecondLastHyphenTo - @LastHyphenTo - 1)) AS INT);
            SET @OrigProIdTo = SUBSTRING(@AssignToSeries, 1, LEN(@AssignToSeries) - @SecondLastHyphenTo);

            IF @SerialTo IS NULL OR @SeriesOrderTo IS NULL OR @OrigProIdTo IS NULL OR @OrigProIdTo = ''
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Parse error in AssignToSeries)';
                GOTO NEXT_ROW;
            END

            -- Validation: Must belong to same original product
            IF @OrigProId <> @OrigProIdTo
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (From and To products mismatch)';
                GOTO NEXT_ROW;
            END

            -- Validation: From should not be greater than To
            IF @SeriesOrderFrom > @SeriesOrderTo OR (@SeriesOrderFrom = @SeriesOrderTo AND @SerialFrom > @SerialTo)
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (From series greater than To series)';
                GOTO NEXT_ROW;
            END

            -- 3. Set TargetProId from AssignToProID
            SET @TargetProId = @AssignToProID;

            IF @TargetProId IS NULL OR @TargetProId = ''
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Target product empty)';
                GOTO NEXT_ROW;
            END

            -- Validation: Original and Target cannot be the same
            IF @OrigProId = @TargetProId
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Target same as original product)';
                GOTO NEXT_ROW;
            END

            -- 4. Check company ownership of products in Pro_Reg
            IF NOT EXISTS (SELECT 1 FROM Pro_Reg WITH(NOLOCK) WHERE Pro_ID = @OrigProId AND Comp_ID = @Comp_ID)
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Original product not owned by company)';
                GOTO NEXT_ROW;
            END

            IF NOT EXISTS (SELECT 1 FROM Pro_Reg WITH(NOLOCK) WHERE Pro_ID = @TargetProId AND Comp_ID = @Comp_ID)
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Target product not owned by company)';
                GOTO NEXT_ROW;
            END

            -- 5. Validate that codes exist in the specified range and are not used (Use_Count is 0 or NULL) and not already reassigned
            IF @SeriesOrderFrom = @SeriesOrderTo
                SET @TotalExpected = @SerialTo - @SerialFrom + 1;
            ELSE
                SET @TotalExpected = (10000 - @SerialFrom) + ((@SeriesOrderTo - @SeriesOrderFrom - 1) * 10000) + (@SerialTo + 1);

            SELECT 
                @ActualCount = COUNT(*),
                @UsedCount = SUM(CASE WHEN Use_Count > 0 THEN 1 ELSE 0 END),
                @AlreadyReassignedCount = SUM(CASE WHEN reassignProid IS NOT NULL THEN 1 ELSE 0 END)
            FROM M_Code WITH(NOLOCK)
            WHERE Pro_ID = @OrigProId 
              AND (
                  (@SeriesOrderFrom = @SeriesOrderTo AND Series_Order = @SeriesOrderFrom AND Series_Serial >= @SerialFrom AND Series_Serial <= @SerialTo)
                  OR
                  (@SeriesOrderFrom < @SeriesOrderTo AND (
                      (Series_Order = @SeriesOrderFrom AND Series_Serial >= @SerialFrom)
                      OR (Series_Order > @SeriesOrderFrom AND Series_Order < @SeriesOrderTo)
                      OR (Series_Order = @SeriesOrderTo AND Series_Serial <= @SerialTo)
                  ))
              );

            IF ISNULL(@ActualCount, 0) < @TotalExpected
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Missing codes in M_Code)';
                GOTO NEXT_ROW;
            END

            IF ISNULL(@UsedCount, 0) > 0
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Contains already used codes)';
                GOTO NEXT_ROW;
            END

            IF ISNULL(@AlreadyReassignedCount, 0) > 0
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Contains already reassigned codes)';
                GOTO NEXT_ROW;
            END

            -- 6. Validate ExpiryDate is not in the past
            IF @ExpiryDate IS NOT NULL AND CAST(@ExpiryDate AS DATE) < CAST(GETDATE() AS DATE)
            BEGIN
                SET @FailedRows = @FailedRows + CASE WHEN @FailedRows = '' THEN '' ELSE ', ' END + CAST(@RowNumber AS VARCHAR(10)) + ' (Expiry date in the past)';
                GOTO NEXT_ROW;
            END

            -- 7. Get Batch ID (T_Pro_Row_ID) from M_Code for first code in the range

            SELECT TOP 1 @BatchNoStr = Batch_No
            FROM M_Code WITH(NOLOCK)
            WHERE Pro_ID = @OrigProId 
              AND Series_Order = @SeriesOrderFrom
              AND Series_Serial = @SerialFrom
              AND Batch_No IS NOT NULL;

            IF @BatchNoStr IS NOT NULL AND ISNUMERIC(@BatchNoStr) = 1 AND @BatchNoStr NOT LIKE '%[^0-9]%'
            BEGIN
                SET @TProRowId = CAST(@BatchNoStr AS BIGINT);
            END

            -- 8. Get active ServiceId from M_ServiceSubscription for the original product
            SET @ServiceId = '';
            SELECT TOP 1 @ServiceId = Service_ID 
            FROM M_ServiceSubscription WITH (NOLOCK)
            WHERE Pro_ID = @OrigProId AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0
            ORDER BY EntryDate DESC, Subscribe_Id DESC;

            -- 9. Update M_Code: set reassignProid = @TargetProId
            UPDATE M_Code
            SET reassignProid = @TargetProId
            WHERE Pro_ID = @OrigProId 
              AND (
                  (@SeriesOrderFrom = @SeriesOrderTo AND Series_Order = @SeriesOrderFrom AND Series_Serial >= @SerialFrom AND Series_Serial <= @SerialTo)
                  OR
                  (@SeriesOrderFrom < @SeriesOrderTo AND (
                      (Series_Order = @SeriesOrderFrom AND Series_Serial >= @SerialFrom)
                      OR (Series_Order > @SeriesOrderFrom AND Series_Order < @SeriesOrderTo)
                      OR (Series_Order = @SeriesOrderTo AND Series_Serial <= @SerialTo)
                  ))
              );

            -- 10. Insert record into T_ReassignCode for tracking
            INSERT INTO [dbo].[T_ReassignCode] (
                [Comp_ID],
                [OldProductId],
                [ReassignCodeProId],
                [Points],
                [BatchNumber],
                [AssignDate],
                [ExpiryDate],
                [ServiceId],
                [Entry_Date],
                [T_Pro_Row_ID],
                [FromSeries],
                [ToSeries],
                [Comments],
                [Series_Order_From],
                [Series_Order_To],
                [Series_Serial_From],
                [Series_Serial_To]
            )
            VALUES (
                @Comp_ID,
                @OrigProId,
                @TargetProId,
                0.00,
                @BatchNumber,
                @ManufacturingDate,
                @ExpiryDate,
                @ServiceId,
                GETDATE(),
                @TProRowId,
                @AssignFromSeries,
                @AssignToSeries,
                'Reassigned from ' + @OrigProId,
                @SeriesOrderFrom,
                @SeriesOrderTo,
                @SerialFrom,
                @SerialTo
            );

            SET @SuccessCount = @SuccessCount + 1;

        NEXT_ROW:
            FETCH NEXT FROM reassign_cursor INTO 
                @AssignFromSeries, @AssignToSeries, @AssignToProID, 
                @BatchNumber, @ManufacturingDate, @ExpiryDate;
        END

        CLOSE reassign_cursor;
        DEALLOCATE reassign_cursor;

        COMMIT TRANSACTION;

        IF @SuccessCount > 0
        BEGIN
            IF ISNULL(@FailedRows, '') = ''
                SELECT 1 AS success, 'Bulk reassignment completed successfully. ' + CAST(@SuccessCount AS VARCHAR(10)) + ' ranges reassigned.' AS message;
            ELSE
                SELECT 1 AS success, 'Bulk reassignment completed. ' + CAST(@SuccessCount AS VARCHAR(10)) + ' ranges reassigned. Skipped rows with issues: ' + @FailedRows AS message;
        END
        ELSE
        BEGIN
            SELECT 0 AS success, 'Bulk reassignment failed. All rows had issues: ' + @FailedRows AS message;
        END

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Clean cursor if left open
        IF CURSOR_STATUS('local', 'reassign_cursor') >= 0
        BEGIN
            CLOSE reassign_cursor;
            DEALLOCATE reassign_cursor;
        END

        SELECT 0 AS success, 'Database Error: ' + ERROR_MESSAGE() AS message;
    END CATCH
END
GO
