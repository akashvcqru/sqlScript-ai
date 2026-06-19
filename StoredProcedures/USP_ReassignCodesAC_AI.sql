SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-06-19
-- Description: Reassign assigned serial codes tracking (AC version - only tracking)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ReassignCodesAC_AI]
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

    BEGIN TRY
        -- Ensure T_ReassignCode table exists and has necessary columns
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

        -- Validate if target product already has an active entry relevant to given series range
        DECLARE @ReqStart BIGINT = CAST(@SeriesOrderFrom AS BIGINT) * 10000 + @SerialFrom;
        DECLARE @ReqEnd BIGINT = CAST(@SeriesOrderTo AS BIGINT) * 10000 + @SerialTo;

        IF EXISTS (
            SELECT 1 
            FROM M_ServiceSubscription sub WITH (NOLOCK)
            INNER JOIN M_ServiceSubscriptionTrans trans WITH (NOLOCK)
                ON sub.Subscribe_Id = trans.Subscribe_Id
            WHERE sub.Pro_ID = @TargetProId
              AND sub.IsActive = 1 
              AND ISNULL(sub.IsDelete, 0) = 0
              AND trans.IsActive = 1 
              AND ISNULL(trans.IsDelete, 0) = 0
              AND sub.start_order IS NOT NULL
              AND sub.start_series IS NOT NULL
              AND sub.end_order IS NOT NULL
              AND sub.end_series IS NOT NULL
              AND (CAST(sub.start_order AS BIGINT) * 10000 + sub.start_series) <= @ReqEnd
              AND @ReqStart <= (CAST(sub.end_order AS BIGINT) * 10000 + sub.end_series)
        )
        BEGIN
            SELECT 0 AS success, 'already assign to another active seriease' AS message;
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

        -- Validate TargetExpDate against Subscription DateTo and current date
        IF @TargetExpDate IS NOT NULL
        BEGIN
            IF CAST(@TargetExpDate AS DATE) < CAST(GETDATE() AS DATE)
            BEGIN
                SELECT 0 AS success, 'TargetExpDate cannot be less than current date.' AS message;
                RETURN;
            END
        END

        -- Get Batch ID from M_Code to use as T_Pro_Row_ID (attempt cast to BIGINT)
        DECLARE @BatchNoStr NVARCHAR(50);
        DECLARE @TProRowId BIGINT = NULL;
        
        SELECT TOP 1 @BatchNoStr = Batch_No
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
          AND Batch_No IS NOT NULL;
          
        IF @BatchNoStr IS NOT NULL AND ISNUMERIC(@BatchNoStr) = 1 AND @BatchNoStr NOT LIKE '%[^0-9]%'
        BEGIN
            SET @TProRowId = CAST(@BatchNoStr AS BIGINT);
        END

        -- Get ServiceId
        DECLARE @ServiceId NVARCHAR(50) = '';
        SELECT TOP 1 @ServiceId = Service_ID 
        FROM M_ServiceSubscription WITH (NOLOCK)
        WHERE Pro_ID = @TargetProId AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0;

        BEGIN TRANSACTION;

        -- Insert record into T_ReassignCode for tracking only (no M_Code updates)
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
            @TargetBatchNo,
            @TargetMfdDate,
            @TargetExpDate,
            @ServiceId,
            GETDATE(),
            @TProRowId,
            @FromSerialCode,
            @ToSerialCode,
            'Reassigned from ' + @OrigProId,
            @SeriesOrderFrom,
            @SeriesOrderTo,
            @SerialFrom,
            @SerialTo
        );

        COMMIT TRANSACTION;

        SELECT 1 AS success, 'Codes reassigned successfully (tracking only).' AS message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, 'Error: ' + ERROR_MESSAGE() AS message;
    END CATCH
END
GO
