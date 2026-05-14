-- ============================================================================
-- Author:      AI Assistant
-- Create date: 2026-05-13
-- Description: Business Logic (BL) Reassign Codes procedure with validation check
--              Counts already assigned serial numbers to prevent double assignment.
-- ============================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_BL_ReassignCodes_AI]
    @Comp_ID NVARCHAR(50),
    @TargetProId NVARCHAR(50),
    @TargetBatchNo NVARCHAR(50),
    @TargetMfdDate DATETIME = NULL,
    @TargetExpDate DATETIME = NULL,
    @FromSeriesSerial NVARCHAR(100),
    @ToSeriesSerial NVARCHAR(100),
    @Point INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Ensure T_ReassignCode table exists
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
            [ToSeries] NVARCHAR(100)
        );
    END

    DECLARE @OrigProId NVARCHAR(50);
    DECLARE @SeriesOrder INT;
    DECLARE @SerialFrom INT;
    DECLARE @SerialTo INT;
    DECLARE @NewBatchRowId NUMERIC(20, 0);
    DECLARE @NewBatchKey VARCHAR(50);

    BEGIN TRY
        -- 1. Parse Serial Codes
        -- Expected format: PROID-ORDER-SERIAL (e.g., BO56-0000-0000)
        
        -- From code parsing
        DECLARE @LastHyphenFrom INT = CHARINDEX('-', REVERSE(@FromSeriesSerial));
        DECLARE @SecondLastHyphenFrom INT = CHARINDEX('-', REVERSE(@FromSeriesSerial), @LastHyphenFrom + 1);
        
        IF @LastHyphenFrom = 0 OR @SecondLastHyphenFrom = 0
        BEGIN
            SELECT 0 AS success, 'Invalid From Series Serial format. Expected PROID-ORDER-SERIAL.' AS message;
            RETURN;
        END

        SET @SerialFrom = CAST(REVERSE(SUBSTRING(REVERSE(@FromSeriesSerial), 1, @LastHyphenFrom - 1)) AS INT);
        SET @SeriesOrder = CAST(REVERSE(SUBSTRING(REVERSE(@FromSeriesSerial), @LastHyphenFrom + 1, @SecondLastHyphenFrom - @LastHyphenFrom - 1)) AS INT);
        SET @OrigProId = SUBSTRING(@FromSeriesSerial, 1, LEN(@FromSeriesSerial) - @SecondLastHyphenFrom);

        -- To code parsing
        DECLARE @LastHyphenTo INT = CHARINDEX('-', REVERSE(@ToSeriesSerial));
        DECLARE @SecondLastHyphenTo INT = CHARINDEX('-', REVERSE(@ToSeriesSerial), @LastHyphenTo + 1);

        IF @LastHyphenTo = 0 OR @SecondLastHyphenTo = 0
        BEGIN
            SELECT 0 AS success, 'Invalid To Series Serial format. Expected PROID-ORDER-SERIAL.' AS message;
            RETURN;
        END

        SET @SerialTo = CAST(REVERSE(SUBSTRING(REVERSE(@ToSeriesSerial), 1, @LastHyphenTo - 1)) AS INT);
        
        -- Validation: Must be same original product and series order
        DECLARE @OrigProIdTo NVARCHAR(50) = SUBSTRING(@ToSeriesSerial, 1, LEN(@ToSeriesSerial) - @SecondLastHyphenTo);
        DECLARE @SeriesOrderTo INT = CAST(REVERSE(SUBSTRING(REVERSE(@ToSeriesSerial), @LastHyphenTo + 1, @SecondLastHyphenTo - @LastHyphenTo - 1)) AS INT);

        IF @OrigProId <> @OrigProIdTo OR @SeriesOrder <> @SeriesOrderTo
        BEGIN
            SELECT 0 AS success, 'From and To serial codes must belong to the same original product and series.' AS message;
            RETURN;
        END

        IF @SerialFrom > @SerialTo
        BEGIN
            SELECT 0 AS success, 'From serial number cannot be greater than To serial number.' AS message;
            RETURN;
        END

        -- Company validation: Ensure products belong to the company
        IF NOT EXISTS (SELECT 1 FROM Pro_Reg WITH (NOLOCK) WHERE Pro_ID = @OrigProId AND Comp_ID = @Comp_ID)
        BEGIN
            SELECT 0 AS success, 'Original product does not belong to this company.' AS message;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Pro_Reg WITH (NOLOCK) WHERE Pro_ID = @TargetProId AND Comp_ID = @Comp_ID)
        BEGIN
            SELECT 0 AS success, 'Target product does not belong to this company.' AS message;
            RETURN;
        END

        -- 2. Validate Already Assigned Codes (User Requested Check)
        DECLARE @TotalRequested INT = @SerialTo - @SerialFrom + 1;
        DECLARE @AvailableCount INT = 0;

        SELECT @AvailableCount = COUNT(*) 
        FROM M_Code WITH (NOLOCK) 
        WHERE Pro_ID = @OrigProId 
          AND Series_Order = @SeriesOrder 
          AND Series_Serial >= @SerialFrom 
          AND Series_Serial <= @SerialTo;

        DECLARE @AlreadyAssignedCount INT = @TotalRequested - @AvailableCount;

        IF @AlreadyAssignedCount > 0
        BEGIN
            SELECT 0 AS success, 
                   CAST(@AlreadyAssignedCount AS NVARCHAR(20)) + ' codes are already assigned to other Serial Number. Please enter valid From, To Series' AS message;
            RETURN;
        END

        -- Lookup active ServiceId for the target product
        DECLARE @ServiceId NVARCHAR(50) = '';
        SELECT TOP 1 @ServiceId = Service_ID 
        FROM M_ServiceSubscription WITH (NOLOCK)
        WHERE Pro_ID = @TargetProId AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0;

        BEGIN TRANSACTION;

        -- 3. Create New Batch in T_Pro
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
            'BL Reassigned from ' + @OrigProId
        );

        SET @NewBatchRowId = SCOPE_IDENTITY();
        SET @NewBatchKey = CAST(@NewBatchRowId AS VARCHAR(50));

        -- 4. Update M_Code records
        DECLARE @OldBatchIDs TABLE (Batch_No NVARCHAR(50));

        -- Single pass: update codes and capture former Batch_No values (avoids a duplicate scan of M_Code).
        UPDATE M_Code
        SET Pro_ID = @TargetProId,
            Batch_No = CAST(@NewBatchRowId AS NVARCHAR(50))
        OUTPUT deleted.Batch_No INTO @OldBatchIDs (Batch_No)
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

        -- 5. Insert record into T_ReassignCode for BL tracking
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
            [ToSeries]
        )
        VALUES (
            @Comp_ID,
            @OrigProId,
            @TargetProId,
            @Point,
            @TargetBatchNo,
            @TargetMfdDate,
            @TargetExpDate,
            @ServiceId,
            GETDATE(),
            @NewBatchRowId,
            @FromSeriesSerial,
            @ToSeriesSerial
        );

        -- 6. Refresh Series_Limit (same rules as UpdateM_codeByBatch_No, inlined to avoid N+1 proc calls and repeated full scans).
        UPDATE [dbo].[T_Pro]
        SET [Series_Limit] = (
            (SELECT TOP 1 'From  ' + pro_id + '-' + 
                (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' +
                (CASE 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                    ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                END)
             FROM [M_Code] 
             WHERE print_status = 1 AND pro_id = @TargetProId AND Batch_no = @NewBatchKey
             ORDER BY [Series_Order], [Series_Serial]) 
            + '   ' +
            (SELECT TOP 1 'To  ' + pro_id + '-' + 
                (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' +
                (CASE 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                    ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                END)
             FROM [M_Code] 
             WHERE print_status = 1 AND pro_id = @TargetProId AND Batch_no = @NewBatchKey
             ORDER BY [Series_Order] DESC, [Series_Serial] DESC)
        )
        WHERE Row_ID = @NewBatchRowId;

        UPDATE tp
        SET tp.[Series_Limit] = (fr.from_part + '   ' + fr.to_part)
        FROM [dbo].[T_Pro] AS tp
        INNER JOIN (
            SELECT DISTINCT ob.Batch_No AS bn
            FROM @OldBatchIDs AS ob
            WHERE ob.Batch_No IS NOT NULL
        ) AS batches ON CAST(tp.Row_ID AS NVARCHAR(50)) = batches.bn
        CROSS APPLY (
            SELECT 
                (SELECT TOP 1 'From  ' + c.pro_id + '-' + 
                    (CASE WHEN LEN(CONVERT(NVARCHAR, c.[Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, c.[Series_Order]) ELSE CONVERT(NVARCHAR, c.[Series_Order]) END) + '-' +
                    (CASE 
                        WHEN LEN(CONVERT(NVARCHAR, c.[Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, c.[Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, c.[Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, c.[Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, c.[Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, c.[Series_Serial]) 
                        ELSE CONVERT(NVARCHAR, c.[Series_Serial]) 
                    END)
                 FROM [M_Code] AS c
                 WHERE c.print_status = 1 AND c.pro_id = @OrigProId AND c.Batch_no = batches.bn
                 ORDER BY c.[Series_Order], c.[Series_Serial]) AS from_part,
                (SELECT TOP 1 'To  ' + c.pro_id + '-' + 
                    (CASE WHEN LEN(CONVERT(NVARCHAR, c.[Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, c.[Series_Order]) ELSE CONVERT(NVARCHAR, c.[Series_Order]) END) + '-' +
                    (CASE 
                        WHEN LEN(CONVERT(NVARCHAR, c.[Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, c.[Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, c.[Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, c.[Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, c.[Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, c.[Series_Serial]) 
                        ELSE CONVERT(NVARCHAR, c.[Series_Serial]) 
                    END)
                 FROM [M_Code] AS c
                 WHERE c.print_status = 1 AND c.pro_id = @OrigProId AND c.Batch_no = batches.bn
                 ORDER BY c.[Series_Order] DESC, c.[Series_Serial] DESC) AS to_part
        ) AS fr;

        COMMIT TRANSACTION;

        SELECT 1 AS success, 'BL Codes reassigned successfully to new batch ID: ' + CAST(@NewBatchRowId AS NVARCHAR(50)) AS message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, 'Error: ' + ERROR_MESSAGE() AS message;
    END CATCH
END
GO
