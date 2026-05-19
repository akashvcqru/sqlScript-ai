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

        -- Validation: Original product and Target product cannot be the same
        IF @OrigProId = @TargetProId
        BEGIN
            SELECT 0 AS success, 'Original product and Target product cannot be the same.' AS message;
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

        -- Check if any code in the requested range has already been reassigned to @OrigProId in T_ReassignCode
        DECLARE @ConflictingOldProId NVARCHAR(50) = NULL;
        DECLARE @ConflictingSerial INT = NULL;

        ;WITH ReassignedRanges AS (
            SELECT 
                OldProductId,
                ReassignCodeProId,
                -- Parse Series Order
                CAST(REVERSE(SUBSTRING(REVERSE(FromSeries), 
                    CHARINDEX('-', REVERSE(FromSeries)) + 1, 
                    CHARINDEX('-', REVERSE(FromSeries), CHARINDEX('-', REVERSE(FromSeries)) + 1) - CHARINDEX('-', REVERSE(FromSeries)) - 1
                )) AS INT) AS SeriesOrder,
                -- Parse Serial From
                CAST(REVERSE(SUBSTRING(REVERSE(FromSeries), 1, CHARINDEX('-', REVERSE(FromSeries)) - 1)) AS INT) AS SerialFrom,
                -- Parse Serial To
                CAST(REVERSE(SUBSTRING(REVERSE(ToSeries), 1, CHARINDEX('-', REVERSE(ToSeries)) - 1)) AS INT) AS SerialTo
            FROM T_ReassignCode WITH (NOLOCK)
            WHERE ReassignCodeProId = @OrigProId
              AND FromSeries LIKE '%-%-%%' -- Ensure it has the correct format
        )
        SELECT TOP 1
            @ConflictingOldProId = r.OldProductId,
            @ConflictingSerial = Seq.SerialNum
        FROM (
            -- Generate sequence of serial numbers in the requested range
            SELECT @SerialFrom + RowNum - 1 AS SerialNum
            FROM (
                SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RowNum
                FROM (
                    SELECT 1 AS c UNION ALL SELECT 1
                ) AS L0
                CROSS JOIN (SELECT 1 AS c UNION ALL SELECT 1) AS L1
                CROSS JOIN (SELECT 1 AS c UNION ALL SELECT 1) AS L2
                CROSS JOIN (SELECT 1 AS c UNION ALL SELECT 1) AS L3
                CROSS JOIN (SELECT 1 AS c UNION ALL SELECT 1) AS L4
                CROSS JOIN (SELECT 1 AS c UNION ALL SELECT 1) AS L5
            ) AS Nums
            WHERE RowNum <= @TotalRequested
        ) AS Seq
        INNER JOIN ReassignedRanges AS r
            ON r.SeriesOrder = @SeriesOrder
            AND r.SerialFrom <= Seq.SerialNum
            AND r.SerialTo >= Seq.SerialNum
        ORDER BY Seq.SerialNum ASC;

        IF @ConflictingSerial IS NOT NULL AND @ConflictingOldProId IS NOT NULL
        BEGIN
            DECLARE @ConflictingCodeSeries NVARCHAR(100);
            DECLARE @OrderPart NVARCHAR(20) = SUBSTRING(@FromSeriesSerial, LEN(@FromSeriesSerial) - @SecondLastHyphenFrom + 2, @SecondLastHyphenFrom - @LastHyphenFrom - 1);
            DECLARE @ConflictingPaddedSerial NVARCHAR(20) = RIGHT('0000000000' + CAST(@ConflictingSerial AS VARCHAR(10)), @LastHyphenFrom - 1);
            SET @ConflictingCodeSeries = @ConflictingOldProId + '-' + @OrderPart + '-' + @ConflictingPaddedSerial;

            SELECT 0 AS success, 'Code ' + @ConflictingCodeSeries + ' is already assigned to another product.' AS message;
            RETURN;
        END

        SELECT @AvailableCount = COUNT(*) 
        FROM M_Code WITH (NOLOCK) 
        WHERE Pro_ID = @OrigProId 
          AND Series_Order = @SeriesOrder 
          AND Series_Serial >= @SerialFrom 
          AND Series_Serial <= @SerialTo;

        IF @AvailableCount < @TotalRequested
        BEGIN
            -- Find the first serial number in the range that is not available or has different Pro_ID
            DECLARE @FailedSerial INT = NULL;
            
            ;WITH 
            L0 AS (SELECT 1 AS c UNION ALL SELECT 1),
            L1 AS (SELECT 1 AS c FROM L0 AS a CROSS JOIN L0 AS b),
            L2 AS (SELECT 1 AS c FROM L1 AS a CROSS JOIN L1 AS b),
            L3 AS (SELECT 1 AS c FROM L2 AS a CROSS JOIN L2 AS b),
            L4 AS (SELECT 1 AS c FROM L3 AS a CROSS JOIN L3 AS b),
            L5 AS (SELECT 1 AS c FROM L4 AS a CROSS JOIN L4 AS b),
            Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RowNum FROM L5),
            Seq AS (
                SELECT @SerialFrom + RowNum - 1 AS SerialNum 
                FROM Nums 
                WHERE RowNum <= @TotalRequested
            )
            SELECT TOP 1 @FailedSerial = Seq.SerialNum
            FROM Seq
            LEFT JOIN M_Code WITH (NOLOCK) 
                ON M_Code.Series_Serial = Seq.SerialNum 
                AND M_Code.Series_Order = @SeriesOrder 
                AND M_Code.Pro_ID = @OrigProId
            WHERE M_Code.Row_ID IS NULL
            ORDER BY Seq.SerialNum ASC;

            IF @FailedSerial IS NOT NULL
            BEGIN
                DECLARE @FailedCodeSeries NVARCHAR(100);
                DECLARE @SeriesPrefix NVARCHAR(100) = SUBSTRING(@FromSeriesSerial, 1, LEN(@FromSeriesSerial) - @LastHyphenFrom);
                DECLARE @PaddedSerial NVARCHAR(20) = RIGHT('0000000000' + CAST(@FailedSerial AS VARCHAR(10)), @LastHyphenFrom - 1);
                SET @FailedCodeSeries = @SeriesPrefix + '-' + @PaddedSerial;

                SELECT 0 AS success, 'Code ' + @FailedCodeSeries + ' is already assigned to another product/series. Reassignment stopped.' AS message;
                RETURN;
            END
            ELSE
            BEGIN
                -- Fallback in case of unexpected count mismatch
                DECLARE @AlreadyAssignedCount INT = @TotalRequested - @AvailableCount;
                SELECT 0 AS success, CAST(@AlreadyAssignedCount AS NVARCHAR(20)) + ' codes are already assigned to other Serial Number. Please enter valid From, To Series' AS message;
                RETURN;
            END
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

        -- 4. Update M_Code records
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

        -- 5b. Create entries in M_ServiceSubscription and M_ServiceSubscriptionTrans if target product has a subscription
        DECLARE @LastSubscribeId NVARCHAR(50);
        SELECT TOP 1 @LastSubscribeId = Subscribe_Id
        FROM M_ServiceSubscription WITH (NOLOCK)
        WHERE Pro_ID = @TargetProId
        ORDER BY EntryDate DESC, Subscribe_Id DESC;

        IF @LastSubscribeId IS NOT NULL
        BEGIN
            DECLARE @NewSubscribeId NVARCHAR(50);
            DECLARE @Prefix NVARCHAR(10);
            DECLARE @StartVal BIGINT;

            WHILE 1 = 1
            BEGIN
                SELECT TOP 1 @Prefix = PrPrefix, @StartVal = CAST(PrStart AS BIGINT)
                FROM Code_Gen WITH (UPDLOCK, HOLDLOCK)
                WHERE PrPrefix = 'SSI';

                SET @NewSubscribeId = CONCAT(@Prefix, CAST(@StartVal AS NVARCHAR(50)));

                -- Check if Subscribe_Id already exists in M_ServiceSubscriptiontrans or M_ServiceSubscription
                IF EXISTS (SELECT 1 FROM M_ServiceSubscriptiontrans WITH (NOLOCK) WHERE Subscribe_Id = @NewSubscribeId)
                   OR EXISTS (SELECT 1 FROM M_ServiceSubscription WITH (NOLOCK) WHERE Subscribe_Id = @NewSubscribeId)
                BEGIN
                    UPDATE Code_Gen
                    SET PrStart = CAST((@StartVal + 1) AS NVARCHAR(50))
                    WHERE PrPrefix = 'SSI';
                END
                ELSE
                BEGIN
                    BREAK;
                END
            END

            -- Insert into M_ServiceSubscription replicating the last record of target product
            INSERT INTO [dbo].[M_ServiceSubscription] (
                [Subscribe_Id], [Service_ID], [Comp_ID], [Pro_ID], [Plan_ID], [PlanName],
                [PlanMasterPeriod], [PlanSalePeriod], [PlanMasterPrice], [PlanSalePrice],
                [DateFrom], [DateTo], [EntryDate], [IsActive], [IsDelete], [IsAdminVerify],
                [TransType], [start_order], [start_series], [end_order], [end_series]
            )
            SELECT TOP 1
                @NewSubscribeId, [Service_ID], [Comp_ID], [Pro_ID], [Plan_ID], [PlanName],
                [PlanMasterPeriod], [PlanSalePeriod], [PlanMasterPrice], [PlanSalePrice],
                [DateFrom], [DateTo], GETDATE(), [IsActive], [IsDelete], [IsAdminVerify],
                [TransType], @SeriesOrder, @SerialFrom, @SeriesOrder, @SerialTo
            FROM [dbo].[M_ServiceSubscription] WITH (NOLOCK)
            WHERE Pro_ID = @TargetProId
            ORDER BY EntryDate DESC, Subscribe_Id DESC;

            -- Insert into M_ServiceSubscriptiontrans replicating the configuration of the last subscription
            INSERT INTO [dbo].[M_ServiceSubscriptionTrans] (
                [Subscribe_Id], [Points], [IsCashConvert], [IsCash], [DateFrom], [DateTo],
                [Entry_Date], [Update_Flag_H], [Update_Flag_E], [Comments], [Frequency],
                [IsActive], [IsDelete], [IsDraw], [IsReferral], [DrawDate], [WarrantyPeriod],
                [AmtType], [Minval], [Maxval], [totalamont]
            )
            SELECT TOP 1
                @NewSubscribeId, @Point, [IsCashConvert], [IsCash], [DateFrom], [DateTo],
                GETDATE(), [Update_Flag_H], [Update_Flag_E], [Comments], [Frequency],
                [IsActive], [IsDelete], [IsDraw], [IsReferral], [DrawDate], [WarrantyPeriod],
                [AmtType], [Minval], [Maxval], [totalamont]
            FROM [dbo].[M_ServiceSubscriptionTrans] WITH (NOLOCK)
            WHERE Subscribe_Id = @LastSubscribeId
            ORDER BY SST_Id DESC;

            -- After creating record in this table, then +1 increment PrStart value
            UPDATE Code_Gen
            SET PrStart = CAST((CAST(PrStart AS BIGINT) + 1) AS NVARCHAR(50))
            WHERE PrPrefix = 'SSI';
        END

        -- 6. Update Series_Limit summaries
        EXEC [dbo].[UpdateM_codeByBatch_No] @Row_ID = @NewBatchRowId, @pro_id = @TargetProId;

        DECLARE @BatchID NVARCHAR(50);
        DECLARE @BatchProId NVARCHAR(50) = @OrigProId;
        
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

        SELECT 1 AS success, 'BL Codes reassigned successfully to new batch ID: ' + CAST(@NewBatchRowId AS NVARCHAR(50)) AS message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, 'Error: ' + ERROR_MESSAGE() AS message;
    END CATCH
END
GO
