-- =============================================
-- Procedure: USP_AddServiceSetting_AI
-- Description: Create or Update service settings in M_ServiceSubscriptionTrans
-- =============================================
IF OBJECT_ID('USP_AddServiceSetting_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_AddServiceSetting_AI
GO

CREATE PROCEDURE USP_AddServiceSetting_AI
    @SST_Id            BIGINT = NULL,
    @Subscribe_Id      NVARCHAR(50) = NULL,
    @Service_ID       NVARCHAR(10),
    @Comp_ID          NVARCHAR(50),
    @Pro_ID           NVARCHAR(50),
    @DateFrom         DATETIME = NULL,
    @DateTo           DATETIME = NULL,
    @Points           NUMERIC(18, 0) = 0,
    @IsCashConvert    INT = 1,
    @Frequency        INT = 1,
    @IsCash           NUMERIC(18, 0) = 0,
    @Comments         NVARCHAR(150) = NULL,
    @IsReferral       INT = 0,
    @ReferralLimit    INT = 0,
    @IsDraw           INT = 0,
    @DrawDate         DATETIME = NULL,
    @WarrantyPeriod   INT = 0,
    @AmtType          VARCHAR(12) = 'Fixed',
    @Minval           NUMERIC(18, 0) = 0,
    @Maxval           NUMERIC(18, 0) = 0,
    @TotalAmount      NUMERIC(18, 0) = 0,
    @SeriesStart      NVARCHAR(20) = NULL, -- Format "Order-Serial"
    @SeriesEnd        NVARCHAR(20) = NULL,  -- Format "Order-Serial"
    @DML              NCHAR(1) = 'I' -- 'I' = Insert, 'U' = Update
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ActualSubscribeId NVARCHAR(50) = @Subscribe_Id;
    DECLARE @StartOrder INT = 0, @StartSeries INT = 0;
    DECLARE @EndOrder INT = 0, @EndSeries INT = 0;

    -- Parse series if provided
    IF @SeriesStart IS NOT NULL AND CHARINDEX('-', @SeriesStart) > 0
    BEGIN
        SET @StartOrder = TRY_CAST(SUBSTRING(@SeriesStart, 1, CHARINDEX('-', @SeriesStart) - 1) AS INT);
        SET @StartSeries = TRY_CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
    END

    IF @SeriesEnd IS NOT NULL AND CHARINDEX('-', @SeriesEnd) > 0
    BEGIN
        SET @EndOrder = TRY_CAST(SUBSTRING(@SeriesEnd, 1, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
        SET @EndSeries = TRY_CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
    END

    -- 1. Find or Create Subscribe_Id if not provided
    IF @ActualSubscribeId IS NULL OR @ActualSubscribeId = ''
    BEGIN
        -- Try to find existing subscription
        IF @Service_ID IN ('SRV1029', 'SRV1005', 'SRV1001', 'SRV1024', 'SRV1027', 'SRV1028')
        BEGIN
            SELECT TOP 1 @ActualSubscribeId = Subscribe_Id 
            FROM M_ServiceSubscription 
            WHERE Pro_ID = @Pro_ID AND Comp_ID = @Comp_ID AND Service_ID = @Service_ID
              AND start_order = @StartOrder AND start_series = @StartSeries
              AND end_order = @EndOrder AND end_series = @EndSeries;
        END
        ELSE
        BEGIN
            SELECT TOP 1 @ActualSubscribeId = Subscribe_Id 
            FROM M_ServiceSubscription 
            WHERE Pro_ID = @Pro_ID AND Comp_ID = @Comp_ID AND Service_ID = @Service_ID;
        END

        -- If still not found, we assume the API has already handled GenID if needed, 
        -- but as a fallback, we can't easily create a full row here without more plan info.
        -- For this task, we assume Subscribe_Id is passed or exists.
    END

    IF @ActualSubscribeId IS NULL OR @ActualSubscribeId = ''
    BEGIN
        SELECT 0 AS success, 'SubscribeID not found and could not be determined.' AS message;
        RETURN;
    END

    BEGIN TRANSACTION;

    IF @DML = 'I'
    BEGIN
        INSERT INTO M_ServiceSubscriptionTrans
        (
            Subscribe_Id, Points, IsCashConvert, IsCash, DateFrom, DateTo, 
            Entry_Date, Comments, Frequency, IsActive, IsDelete, IsDraw, 
            IsReferral, DrawDate, WarrantyPeriod, AmtType, Minval, Maxval, totalamont
        )
        VALUES
        (
            @ActualSubscribeId, @Points, @IsCashConvert, @IsCash, @DateFrom, @DateTo, 
            GETDATE(), @Comments, @Frequency, 0, 0, @IsDraw, 
            @IsReferral, @DrawDate, @WarrantyPeriod, @AmtType, @Minval, @Maxval, @TotalAmount
        );

        SET @SST_Id = SCOPE_IDENTITY();

        -- Handle Referral Limit
        IF @IsReferral > 0 AND @ReferralLimit > 0
        BEGIN
            INSERT INTO ReferralLimit (Limit, Compid, M_SST_id, CreatedDate)
            VALUES (@ReferralLimit, @Comp_ID, @SST_Id, GETDATE());
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Service setting added successfully.' AS message, @SST_Id AS SST_Id;
    END
    ELSE IF @DML = 'U'
    BEGIN
        UPDATE M_ServiceSubscriptionTrans
        SET 
            Points = ISNULL(@Points, Points),
            IsCashConvert = ISNULL(@IsCashConvert, IsCashConvert),
            IsCash = ISNULL(@IsCash, IsCash),
            DateFrom = ISNULL(@DateFrom, DateFrom),
            DateTo = ISNULL(@DateTo, DateTo),
            Comments = ISNULL(@Comments, Comments),
            Frequency = ISNULL(@Frequency, Frequency),
            IsDraw = ISNULL(@IsDraw, IsDraw),
            IsReferral = ISNULL(@IsReferral, IsReferral),
            DrawDate = ISNULL(@DrawDate, DrawDate),
            WarrantyPeriod = ISNULL(@WarrantyPeriod, WarrantyPeriod),
            AmtType = ISNULL(@AmtType, AmtType),
            Minval = ISNULL(@Minval, Minval),
            Maxval = ISNULL(@Maxval, Maxval),
            totalamont = ISNULL(@TotalAmount, totalamont)
        WHERE SST_Id = @SST_Id;

        -- Update Referral Limit
        IF @IsReferral > 0 AND @ReferralLimit > 0
        BEGIN
            IF EXISTS (SELECT 1 FROM ReferralLimit WHERE M_SST_id = @SST_Id)
                UPDATE ReferralLimit SET Limit = @ReferralLimit WHERE M_SST_id = @SST_Id;
            ELSE
                INSERT INTO ReferralLimit (Limit, Compid, M_SST_id, CreatedDate)
                VALUES (@ReferralLimit, @Comp_ID, @SST_Id, GETDATE());
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Service setting updated successfully.' AS message, @SST_Id AS SST_Id;
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS success, 'Invalid DML operation.' AS message;
    END
END
GO
