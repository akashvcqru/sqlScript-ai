-- =============================================
-- Author:      AI
-- Create date: 2026-05-04
-- Description: Reassign assigned serial codes to a different product and batch
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ReassignCodes_AI]
    @Comp_ID NVARCHAR(50),
    @TargetProId NVARCHAR(50),
    @TargetBatchNo NVARCHAR(50),
    @TargetMfdDate DATETIME = NULL,
    @TargetExpDate DATETIME = NULL,
    @FromSerialCode NVARCHAR(100),
    @ToSerialCode NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @OrigProId NVARCHAR(50);
    DECLARE @SeriesOrder INT;
    DECLARE @SerialFrom INT;
    DECLARE @SerialTo INT;
    DECLARE @NewBatchRowId NUMERIC(20, 0);

    BEGIN TRY
        -- 1. Parse Serial Codes
        -- Expected format: PROID-ORDER-SERIAL (e.g., P01-01-0001)
        -- We extract the last two parts
        
        -- From code parsing
        DECLARE @LastHyphenFrom INT = CHARINDEX('-', REVERSE(@FromSerialCode));
        DECLARE @SecondLastHyphenFrom INT = CHARINDEX('-', REVERSE(@FromSerialCode), @LastHyphenFrom + 1);
        
        IF @LastHyphenFrom = 0 OR @SecondLastHyphenFrom = 0
        BEGIN
            SELECT 0 AS success, 'Invalid From Serial Code format. Expected PROID-ORDER-SERIAL.' AS message;
            RETURN;
        END

        SET @SerialFrom = CAST(REVERSE(SUBSTRING(REVERSE(@FromSerialCode), 1, @LastHyphenFrom - 1)) AS INT);
        SET @SeriesOrder = CAST(REVERSE(SUBSTRING(REVERSE(@FromSerialCode), @LastHyphenFrom + 1, @SecondLastHyphenFrom - @LastHyphenFrom - 1)) AS INT);
        SET @OrigProId = SUBSTRING(@FromSerialCode, 1, LEN(@FromSerialCode) - @SecondLastHyphenFrom);

        -- To code parsing
        DECLARE @LastHyphenTo INT = CHARINDEX('-', REVERSE(@ToSerialCode));
        DECLARE @SecondLastHyphenTo INT = CHARINDEX('-', REVERSE(@ToSerialCode), @LastHyphenTo + 1);

        IF @LastHyphenTo = 0 OR @SecondLastHyphenTo = 0
        BEGIN
            SELECT 0 AS success, 'Invalid To Serial Code format. Expected PROID-ORDER-SERIAL.' AS message;
            RETURN;
        END

        SET @SerialTo = CAST(REVERSE(SUBSTRING(REVERSE(@ToSerialCode), 1, @LastHyphenTo - 1)) AS INT);
        
        -- Validation: Must be same original product and series order
        DECLARE @OrigProIdTo NVARCHAR(50) = SUBSTRING(@ToSerialCode, 1, LEN(@ToSerialCode) - @SecondLastHyphenTo);
        DECLARE @SeriesOrderTo INT = CAST(REVERSE(SUBSTRING(REVERSE(@ToSerialCode), @LastHyphenTo + 1, @SecondLastHyphenTo - @LastHyphenTo - 1)) AS INT);

        IF @OrigProId <> @OrigProIdTo OR @SeriesOrder <> @SeriesOrderTo
        BEGIN
            SELECT 0 AS success, 'From and To serial codes must belong to the same original product and series.' AS message;
            RETURN;
        END

        -- Company validation: Ensure products belong to the company
        IF NOT EXISTS (SELECT 1 FROM Pro_Reg WHERE Pro_ID = @OrigProId AND Comp_ID = @Comp_ID)
        BEGIN
            SELECT 0 AS success, 'Original product does not belong to this company.' AS message;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Pro_Reg WHERE Pro_ID = @TargetProId AND Comp_ID = @Comp_ID)
        BEGIN
            SELECT 0 AS success, 'Target product does not belong to this company.' AS message;
            RETURN;
        END

        BEGIN TRANSACTION;

        -- 2. Create New Batch in T_Pro
        INSERT INTO [dbo].[T_Pro] (
            [Pro_ID], 
            [Batch_No], 
            [Mfd_Date], 
            [Exp_Date], 
            [Entry_Date], 
            [Comments]
        )
        VALUES (
            @TargetProId, 
            @TargetBatchNo, 
            @TargetMfdDate, 
            @TargetExpDate, 
            GETDATE(), 
            'Reassigned from ' + @OrigProId
        );

        SET @NewBatchRowId = SCOPE_IDENTITY();

        -- 3. Update M_Code records
        -- We update codes that were assigned to the original product/series in the given range
        -- Note: We update both Pro_ID and Batch_No
        
        -- Store the old batch IDs before updating to update their series limits later
        DECLARE @OldBatchIDs TABLE (Batch_No NVARCHAR(50));
        INSERT INTO @OldBatchIDs
        SELECT DISTINCT Batch_No 
        FROM M_Code 
        WHERE Pro_ID = @OrigProId 
          AND Series_Order = @SeriesOrder 
          AND Series_Serial >= @SerialFrom 
          AND Series_Serial <= @SerialTo;

        UPDATE M_Code
        SET Pro_ID = @TargetProId,
            Batch_No = CAST(@NewBatchRowId AS NVARCHAR(50))
        WHERE Pro_ID = @OrigProId 
          AND Series_Order = @SeriesOrder 
          AND Series_Serial >= @SerialFrom 
          AND Series_Serial <= @SerialTo;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'No codes found in the specified range or codes are not assigned.' AS message;
            RETURN;
        END

        -- 4. Update Series_Limit for the New Batch
        EXEC [dbo].[UpdateM_codeByBatch_No] @Row_ID = @NewBatchRowId, @pro_id = @TargetProId;

        -- 5. Update Series_Limit for the Old Batches (as they now have fewer codes)
        DECLARE @BatchID NVARCHAR(50);
        DECLARE @BatchProId NVARCHAR(50) = @OrigProId; -- Assuming all belonged to OrigProId
        
        DECLARE batch_cursor CURSOR FOR SELECT Batch_No FROM @OldBatchIDs WHERE Batch_No IS NOT NULL;
        OPEN batch_cursor;
        FETCH NEXT FROM batch_cursor INTO @BatchID;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC [dbo].[UpdateM_codeByBatch_No] @Row_ID = @BatchID, @pro_id = @BatchProId;
            FETCH NEXT FROM batch_cursor INTO @BatchID;
        END
        CLOSE batch_cursor;
        DEALLOCATE batch_cursor;

        COMMIT TRANSACTION;

        SELECT 1 AS success, 'Codes reassigned successfully to new batch ID: ' + CAST(@NewBatchRowId AS NVARCHAR(50)) AS message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, 'Error: ' + ERROR_MESSAGE() AS message;
    END CATCH
END
GO
