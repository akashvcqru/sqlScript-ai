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
    DECLARE @SeriesOrderFrom INT;
    DECLARE @SerialFrom INT;
    DECLARE @OrigProIdTo NVARCHAR(50);
    DECLARE @SeriesOrderTo INT;
    DECLARE @SerialTo INT;
    DECLARE @NewBatchRowId NUMERIC(20, 0) = NULL;

    BEGIN TRY
        -- 1. Parse Serial Codes
        -- Expected format: PROID-ORDER-SERIAL (e.g., BJ46-0000-0000)
        
        -- From code parsing
        DECLARE @LastHyphenFrom INT = CHARINDEX('-', REVERSE(@FromSerialCode));
        DECLARE @SecondLastHyphenFrom INT = CHARINDEX('-', REVERSE(@FromSerialCode), @LastHyphenFrom + 1);
        
        IF @LastHyphenFrom = 0 OR @SecondLastHyphenFrom = 0
        BEGIN
            SELECT 0 AS success, 'Invalid From Serial Code format. Expected PROID-ORDER-SERIAL.' AS message;
            RETURN;
        END

        SET @SerialFrom = CAST(REVERSE(SUBSTRING(REVERSE(@FromSerialCode), 1, @LastHyphenFrom - 1)) AS INT);
        SET @SeriesOrderFrom = CAST(REVERSE(SUBSTRING(REVERSE(@FromSerialCode), @LastHyphenFrom + 1, @SecondLastHyphenFrom - @LastHyphenFrom - 1)) AS INT);
        SET @OrigProId = SUBSTRING(@FromSerialCode, 1, LEN(@FromSerialCode) - @SecondLastHyphenFrom);

        -- Point 1 Check: TargetProId and OrigProId will not be same
        IF @OrigProId = @TargetProId
        BEGIN
            SELECT 0 AS success, 'TargetProId and OrigProId cannot be the same.' AS message;
            RETURN;
        END

        -- To code parsing
        DECLARE @LastHyphenTo INT = CHARINDEX('-', REVERSE(@ToSerialCode));
        DECLARE @SecondLastHyphenTo INT = CHARINDEX('-', REVERSE(@ToSerialCode), @LastHyphenTo + 1);

        IF @LastHyphenTo = 0 OR @SecondLastHyphenTo = 0
        BEGIN
            SELECT 0 AS success, 'Invalid To Serial Code format. Expected PROID-ORDER-SERIAL.' AS message;
            RETURN;
        END

        SET @SerialTo = CAST(REVERSE(SUBSTRING(REVERSE(@ToSerialCode), 1, @LastHyphenTo - 1)) AS INT);
        SET @SeriesOrderTo = CAST(REVERSE(SUBSTRING(REVERSE(@ToSerialCode), @LastHyphenTo + 1, @SecondLastHyphenTo - @LastHyphenTo - 1)) AS INT);
        SET @OrigProIdTo = SUBSTRING(@ToSerialCode, 1, LEN(@ToSerialCode) - @SecondLastHyphenTo);

        -- Validation: Must be same original product
        IF @OrigProId <> @OrigProIdTo
        BEGIN
            SELECT 0 AS success, 'From and To serial codes must belong to the same original product.' AS message;
            RETURN;
        END

        -- Point 2 Check: From should not be greater than To
        IF @SeriesOrderFrom > @SeriesOrderTo
        BEGIN
            SELECT 0 AS success, 'FromSeriesOrder cannot be greater than ToSeriesOrder.' AS message;
            RETURN;
        END

        IF @SeriesOrderFrom = @SeriesOrderTo AND @SerialFrom > @SerialTo
        BEGIN
            SELECT 0 AS success, 'FromSerialCode cannot be greater than ToSerialCode.' AS message;
            RETURN;
        END

        -- Company validation: Ensure products belong to the company
        IF NOT EXISTS (SELECT 1 FROM Pro_Reg WITH(NOLOCK) WHERE Pro_ID = @OrigProId AND Comp_ID = @Comp_ID)
        BEGIN
            SELECT 0 AS success, 'Original product does not belong to this company.' AS message;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Pro_Reg WITH(NOLOCK) WHERE Pro_ID = @TargetProId AND Comp_ID = @Comp_ID)
        BEGIN
            SELECT 0 AS success, 'Target product does not belong to this company.' AS message;
            RETURN;
        END

        -- Validate if any code in the range is missing, already used, or assigned to a different product
        DECLARE @TotalExpected INT;
        IF @SeriesOrderFrom = @SeriesOrderTo
            SET @TotalExpected = @SerialTo - @SerialFrom + 1;
        ELSE
            SET @TotalExpected = (10000 - @SerialFrom) + ((@SeriesOrderTo - @SeriesOrderFrom - 1) * 10000) + (@SerialTo + 1);

        DECLARE @ActualUnusedCount INT;
        SELECT @ActualUnusedCount = COUNT(*)
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
          )
          AND (Use_Count IS NULL OR Use_Count = 0);

        IF @ActualUnusedCount < @TotalExpected
        BEGIN
            SELECT 0 AS success, 'One or more codes in the specified range are already used or assigned to a different product.' AS message;
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Store the old batch IDs before updating to update their series limits later
        DECLARE @OldBatchIDs TABLE (Batch_No NVARCHAR(50));
        
        INSERT INTO @OldBatchIDs
        SELECT DISTINCT Batch_No 
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

        -- Point 5 logic: if Batch_No is null in OrigProId then create new T_Pro
        IF EXISTS (SELECT 1 FROM @OldBatchIDs WHERE Batch_No IS NULL)
        BEGIN
            -- Create New Batch in T_Pro
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
        END

        -- Point 4: Update M_Code records with cross-series logic
        UPDATE M_Code
        SET Pro_ID = @TargetProId,
            Batch_No = ISNULL(CAST(@NewBatchRowId AS NVARCHAR(50)), Batch_No)
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

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'No codes found in the specified range or codes are not assigned.' AS message;
            RETURN;
        END

        -- Update Series_Limit for the New Batch if created
        IF @NewBatchRowId IS NOT NULL
        BEGIN
            EXEC [dbo].[UpdateM_codeByBatch_No] @Row_ID = @NewBatchRowId, @pro_id = @TargetProId;
        END

        -- Update Series_Limit for the Old Batches (as they now have fewer codes)
        DECLARE @BatchID NVARCHAR(50);
        
        DECLARE batch_cursor CURSOR FOR SELECT Batch_No FROM @OldBatchIDs WHERE Batch_No IS NOT NULL;
        OPEN batch_cursor;
        FETCH NEXT FROM batch_cursor INTO @BatchID;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC [dbo].[UpdateM_codeByBatch_No] @Row_ID = @BatchID, @pro_id = @OrigProId;
            FETCH NEXT FROM batch_cursor INTO @BatchID;
        END
        CLOSE batch_cursor;
        DEALLOCATE batch_cursor;

        -- Point 3 & 6: M_ServiceSubscription Handling
        -- Check if TargetProId exists in M_ServiceSubscription
        IF NOT EXISTS (SELECT 1 FROM M_ServiceSubscription WITH(NOLOCK) WHERE Pro_ID = @TargetProId AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0)
        BEGIN
            -- If it doesn't exist, check if OrigProId has one
            DECLARE @OldSubscribeId NVARCHAR(50) = NULL;
            SELECT TOP 1 @OldSubscribeId = Subscribe_Id
            FROM M_ServiceSubscription WITH(NOLOCK)
            WHERE Pro_ID = @OrigProId AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0
            ORDER BY EntryDate DESC, Subscribe_Id DESC;

            IF @OldSubscribeId IS NOT NULL
            BEGIN
                -- Generate new Subscribe_Id
                DECLARE @NewSubscribeId NVARCHAR(50);
                DECLARE @Prefix NVARCHAR(10);
                DECLARE @StartVal BIGINT;

                WHILE 1 = 1
                BEGIN
                    SELECT TOP 1 @Prefix = PrPrefix, @StartVal = CAST(PrStart AS BIGINT)
                    FROM Code_Gen WITH (UPDLOCK, HOLDLOCK)
                    WHERE PrPrefix = 'SSI';

                    SET @NewSubscribeId = CONCAT(@Prefix, CAST(@StartVal AS NVARCHAR(50)));

                    -- Check if Subscribe_Id already exists
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

                -- Insert into M_ServiceSubscription replicating the last record of original product
                INSERT INTO [dbo].[M_ServiceSubscription] (
                    [Subscribe_Id], [Service_ID], [Comp_ID], [Pro_ID], [Plan_ID], [PlanName],
                    [PlanMasterPeriod], [PlanSalePeriod], [PlanMasterPrice], [PlanSalePrice],
                    [DateFrom], [DateTo], [EntryDate], [IsActive], [IsDelete], [IsAdminVerify],
                    [TransType], [start_order], [start_series], [end_order], [end_series]
                )
                SELECT TOP 1
                    @NewSubscribeId, [Service_ID], [Comp_ID], @TargetProId, [Plan_ID], [PlanName],
                    [PlanMasterPeriod], [PlanSalePeriod], [PlanMasterPrice], [PlanSalePrice],
                    [DateFrom], [DateTo], GETDATE(), [IsActive], [IsDelete], [IsAdminVerify],
                    [TransType], @SeriesOrderFrom, @SerialFrom, @SeriesOrderTo, @SerialTo
                FROM [dbo].[M_ServiceSubscription] WITH (NOLOCK)
                WHERE Subscribe_Id = @OldSubscribeId;

                -- Insert into M_ServiceSubscriptiontrans
                INSERT INTO [dbo].[M_ServiceSubscriptionTrans] (
                    [Subscribe_Id], [Points], [IsCashConvert], [IsCash], [DateFrom], [DateTo],
                    [Entry_Date], [Update_Flag_H], [Update_Flag_E], [Comments], [Frequency],
                    [IsActive], [IsDelete], [IsDraw], [IsReferral], [DrawDate], [WarrantyPeriod],
                    [AmtType], [Minval], [Maxval], [totalamont]
                )
                SELECT 
                    @NewSubscribeId, [Points], [IsCashConvert], [IsCash], [DateFrom], [DateTo],
                    GETDATE(), [Update_Flag_H], [Update_Flag_E], [Comments], [Frequency],
                    [IsActive], [IsDelete], [IsDraw], [IsReferral], [DrawDate], [WarrantyPeriod],
                    [AmtType], [Minval], [Maxval], [totalamont]
                FROM [dbo].[M_ServiceSubscriptionTrans] WITH (NOLOCK)
                WHERE Subscribe_Id = @OldSubscribeId;

                -- Update Code_Gen PrStart
                UPDATE Code_Gen
                SET PrStart = CAST((CAST(PrStart AS BIGINT) + 1) AS NVARCHAR(50))
                WHERE PrPrefix = 'SSI';
            END
        END

        COMMIT TRANSACTION;

        IF @NewBatchRowId IS NOT NULL
            SELECT 1 AS success, 'Codes reassigned successfully to new batch ID: ' + CAST(@NewBatchRowId AS NVARCHAR(50)) AS message;
        ELSE
            SELECT 1 AS success, 'Codes reassigned successfully.' AS message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, 'Error: ' + ERROR_MESSAGE() AS message;
    END CATCH
END
GO
