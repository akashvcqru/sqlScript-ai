-- =============================================
-- Author:      AI
-- Create date: 2026-03-16
-- Updated:     2026-09-22
-- Description: Add product label assignment and update codes
--              Supports SeriesStart/SeriesEnd with availability pre-validation
--              as well as legacy SeriesData JSON.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_AddAssignLabelToProduct_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50),
    @Batch_No_Text NVARCHAR(50),
    @MRP NUMERIC(10, 2) = NULL,
    @Mfd_Date DATETIME = NULL,
    @Exp_Date DATETIME = NULL,
    @Comments NVARCHAR(100) = NULL,
    @Warranty INT = NULL,
    @SeriesStart VARCHAR(100) = NULL,
    @SeriesEnd VARCHAR(100) = NULL,
    @SeriesData NVARCHAR(MAX) = NULL -- JSON Data (Legacy fallback)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @NewRowID NUMERIC(10, 0);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Parse and Validate Series Range if SeriesStart & SeriesEnd are provided
        DECLARE @StartOrder INT = NULL, @StartSerial INT = NULL;
        DECLARE @EndOrder INT = NULL, @EndSerial INT = NULL;

        IF ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> ''
        BEGIN
            -- Parse SeriesStart (handles "0000-0400" or "BP17-0000-0400")
            IF @SeriesStart LIKE '%-%-%'
            BEGIN
                DECLARE @StartP2 VARCHAR(50) = SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart));
                SET @StartOrder = TRY_CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
            END
            ELSE IF @SeriesStart LIKE '%-%'
            BEGIN
                SET @StartOrder = TRY_CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
                SET @StartSerial = TRY_CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
            END

            -- Parse SeriesEnd (handles "0000-0450" or "BP17-0000-0450")
            IF @SeriesEnd LIKE '%-%-%'
            BEGIN
                DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
                SET @EndOrder = TRY_CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
                SET @EndSerial = TRY_CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
            END
            ELSE IF @SeriesEnd LIKE '%-%'
            BEGIN
                SET @EndOrder = TRY_CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
                SET @EndSerial = TRY_CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
            END

            IF @StartOrder IS NULL OR @StartSerial IS NULL OR @EndOrder IS NULL OR @EndSerial IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Invalid series format in SeriesStart/SeriesEnd. Expected format: 0000-0400 or Prefix-0000-0400.' AS message;
                RETURN;
            END

            IF @StartOrder > @EndOrder OR (@StartOrder = @EndOrder AND @StartSerial > @EndSerial)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'SeriesStart (' + @SeriesStart + ') cannot be greater than SeriesEnd (' + @SeriesEnd + ').' AS message;
                RETURN;
            END

            -- Check availability in M_Code (or M_Code_PFL)
            DECLARE @ExistingCount INT = 0, @AvailableCount INT = 0;

            IF @Comp_ID = 'Comp-1693'
            BEGIN
                SELECT 
                    @ExistingCount = COUNT(1),
                    @AvailableCount = SUM(CASE WHEN Batch_No IS NULL OR Batch_No = '' THEN 1 ELSE 0 END)
                FROM M_Code_PFL WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END
            ELSE
            BEGIN
                SELECT 
                    @ExistingCount = COUNT(1),
                    @AvailableCount = SUM(CASE WHEN Batch_No IS NULL OR Batch_No = '' THEN 1 ELSE 0 END)
                FROM M_Code WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))));
            END

            IF ISNULL(@ExistingCount, 0) = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'The specified series range ' + @SeriesStart + ' to ' + @SeriesEnd + ' does not exist for product ' + @Pro_ID + '.' AS message;
                RETURN;
            END

            IF ISNULL(@AvailableCount, 0) = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'No available codes in range ' + @SeriesStart + ' to ' + @SeriesEnd + ' for product ' + @Pro_ID + '. All ' + CAST(@ExistingCount AS VARCHAR(10)) + ' codes are already assigned to another batch.' AS message;
                RETURN;
            END

            IF @AvailableCount < @ExistingCount
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, 'Only ' + CAST(ISNULL(@AvailableCount, 0) AS VARCHAR(10)) + ' of ' + CAST(@ExistingCount AS VARCHAR(10)) + ' codes are available in range ' + @SeriesStart + ' to ' + @SeriesEnd + ' for product ' + @Pro_ID + '. Some codes are already assigned to another batch.' AS message;
                RETURN;
            END
        END

        -- 2. Insert into T_Pro
        INSERT INTO [dbo].[T_Pro] (
            [Pro_ID], 
            [MRP], 
            [Mfd_Date], 
            [Exp_Date], 
            [Batch_No], 
            [Entry_Date], 
            [Comments], 
            [IsWarranty],
            [Series_Limit]
        )
        VALUES (
            @Pro_ID, 
            @MRP, 
            @Mfd_Date, 
            @Exp_Date, 
            @Batch_No_Text, 
            GETDATE(), 
            @Comments, 
            CASE WHEN @Warranty > 0 THEN 1 ELSE 0 END,
            CASE WHEN ISNULL(@SeriesStart, '') <> '' AND ISNULL(@SeriesEnd, '') <> '' 
                 THEN CONCAT('From ', @SeriesStart, ' To ', @SeriesEnd) 
                 ELSE NULL END
        );

        SET @NewRowID = SCOPE_IDENTITY();

        -- 3. Update M_Code / M_Code_PFL for the allocated codes
        DECLARE @UpdatedCodes TABLE (
            Series_Order INT,
            Series_Serial INT
        );

        IF @StartOrder IS NOT NULL AND @EndOrder IS NOT NULL
        BEGIN
            IF @Comp_ID = 'Comp-1693'
            BEGIN
                UPDATE M_Code_PFL WITH (ROWLOCK)
                SET Batch_No = CAST(@NewRowID AS NVARCHAR(50))
                OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))))
                  AND (Batch_No IS NULL OR Batch_No = '');
            END
            ELSE
            BEGIN
                UPDATE M_Code WITH (ROWLOCK)
                SET Batch_No = CAST(@NewRowID AS NVARCHAR(50))
                OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes
                WHERE Pro_ID = @Pro_ID
                  AND ((Series_Order = @StartOrder AND Series_Order = @EndOrder AND Series_Serial BETWEEN @StartSerial AND @EndSerial)
                       OR (@StartOrder < @EndOrder AND ((Series_Order = @StartOrder AND Series_Serial >= @StartSerial) OR (Series_Order = @EndOrder AND Series_Serial <= @EndSerial) OR (Series_Order > @StartOrder AND Series_Order < @EndOrder))))
                  AND (Batch_No IS NULL OR Batch_No = '');
            END
        END
        ELSE IF @SeriesData IS NOT NULL AND @SeriesData <> '' AND @SeriesData <> '[]'
        BEGIN
            IF @Comp_ID = 'Comp-1693'
            BEGIN
                UPDATE mc
                SET mc.Batch_No = CAST(@NewRowID AS NVARCHAR(50))
                OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes
                FROM M_Code_PFL mc WITH (ROWLOCK)
                JOIN OPENJSON(@SeriesData)
                WITH (
                    SeriesInitial INT '$.SeriesInitial',
                    SeriesFrom INT '$.SeriesFrom',
                    SeriesTo INT '$.SeriesTo'
                ) json ON mc.Pro_ID = @Pro_ID 
                      AND mc.Series_Order = json.SeriesInitial
                      AND mc.Series_Serial >= json.SeriesFrom
                      AND mc.Series_Serial <= json.SeriesTo
                WHERE mc.Batch_No IS NULL OR mc.Batch_No = '';
            END
            ELSE
            BEGIN
                UPDATE mc
                SET mc.Batch_No = CAST(@NewRowID AS NVARCHAR(50))
                OUTPUT inserted.Series_Order, inserted.Series_Serial INTO @UpdatedCodes
                FROM M_Code mc WITH (ROWLOCK)
                JOIN OPENJSON(@SeriesData)
                WITH (
                    SeriesInitial INT '$.SeriesInitial',
                    SeriesFrom INT '$.SeriesFrom',
                    SeriesTo INT '$.SeriesTo'
                ) json ON mc.Pro_ID = @Pro_ID 
                      AND mc.Series_Order = json.SeriesInitial
                      AND mc.Series_Serial >= json.SeriesFrom
                      AND mc.Series_Serial <= json.SeriesTo
                WHERE mc.Batch_No IS NULL OR mc.Batch_No = '';
            END
        END

        -- 4. Update Series_Limit in T_Pro from in-memory @UpdatedCodes if not explicitly set
        IF (ISNULL(@SeriesStart, '') = '' OR ISNULL(@SeriesEnd, '') = '') AND EXISTS (SELECT 1 FROM @UpdatedCodes)
        BEGIN
            DECLARE @MinOrder INT, @MaxOrder INT, @MinSerial INT, @MaxSerial INT, @Qty INT;
            
            SELECT 
                @MinOrder = MIN(Series_Order),
                @MaxOrder = MAX(Series_Order),
                @MinSerial = MIN(Series_Serial),
                @MaxSerial = MAX(Series_Serial),
                @Qty = COUNT(1)
            FROM @UpdatedCodes;

            IF @MinOrder IS NOT NULL
            BEGIN
                DECLARE @SeriesLimitStr NVARCHAR(500) = 
                    'From ' + @Pro_ID + '-' + RIGHT('00' + CAST(@MinOrder AS VARCHAR(10)), 2) + '-' + RIGHT('0000' + CAST(@MinSerial AS VARCHAR(10)), 4) +
                    ' To ' + @Pro_ID + '-' + RIGHT('00' + CAST(@MaxOrder AS VARCHAR(10)), 2) + '-' + RIGHT('0000' + CAST(@MaxSerial AS VARCHAR(10)), 4) +
                    ' (qty ' + CAST(@Qty AS VARCHAR(20)) + ')';

                UPDATE T_Pro
                SET Series_Limit = @SeriesLimitStr
                WHERE Row_ID = @NewRowID;
            END
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Label assignment successful.' AS message, @NewRowID AS NewRowID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
