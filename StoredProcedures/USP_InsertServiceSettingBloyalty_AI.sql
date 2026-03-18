-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingBloyalty_AI
-- Purpose        : Insert Brand Loyalty service setting.
--                  Handles points, cash conversion, frequency,
--                  referral sub-fields and gift list (JSON).
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingBloyalty_AI]
    @Comp_ID      VARCHAR(50),
    @Pro_ID       VARCHAR(50),
    @Service_ID   VARCHAR(50),
    @Subscribe_Id VARCHAR(50)   = NULL,

    @DateFrom     DATETIME      = NULL,
    @DateTo       DATETIME      = NULL,

    -- Loyalty core
    @IsCashConvert INT           = NULL,
    @Frequency     INT           = NULL,
    @Points        DECIMAL(18,2) = NULL,
    @AmtType       VARCHAR(50)   = NULL,   -- 'Fixed' | 'Random'
    @TotalLoyalty  BIGINT        = NULL,
    @Multiple      INT           = NULL,
    @Minval        INT           = NULL,
    @Maxval        INT           = NULL,
    @IsCash        DECIMAL(18,2) = NULL,

    -- Referral
    @IsReferral        INT           = NULL,  -- 0=None,1=Cash,2=Points,3=Gift
    @RefGiftReferral   VARCHAR(50)   = NULL,
    @RefGiftUsers      VARCHAR(50)   = NULL,
    @RefPointsReferral BIGINT        = NULL,
    @RefPointsUsers    BIGINT        = NULL,
    @RefIsCashConvert  INT           = NULL,
    @RefIsCashReferral BIGINT        = NULL,
    @RefIsCashUsers    BIGINT        = NULL,

    -- Gifts JSON array: [{"Gift_ID":"...","GiftName":"...","GiftCount":1}]
    @GiftListJson  NVARCHAR(MAX) = NULL,

    @Comments      NVARCHAR(1000) = NULL,
    @EntryDate     DATETIME       = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Resolve Subscribe_Id
        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID;
        END

        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT 0 AS success, 'No active subscription found for the given Comp/Product/Service.' AS message;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO M_ServiceSubscriptionTrans
        (
            Subscribe_Id, Comp_ID, Pro_ID, Service_ID,
            DateFrom, DateTo,
            IsCashConvert, Frequency, Points, AmtType, TotalLoyalty,
            Multiple, Minval, Maxval, IsCash,
            IsReferral,
            RefGiftReferral, RefGiftUsers,
            RefPointsReferral, RefPointsUsers,
            RefIsCashConvert, RefIsCashReferral, RefIsCashUsers,
            Comments, EntryDate
        )
        VALUES
        (
            @Subscribe_Id, @Comp_ID, @Pro_ID, @Service_ID,
            @DateFrom, @DateTo,
            @IsCashConvert, @Frequency, @Points, @AmtType, @TotalLoyalty,
            @Multiple, @Minval, @Maxval, @IsCash,
            @IsReferral,
            @RefGiftReferral, @RefGiftUsers,
            @RefPointsReferral, @RefPointsUsers,
            @RefIsCashConvert, @RefIsCashReferral, @RefIsCashUsers,
            @Comments, ISNULL(@EntryDate, GETDATE())
        );

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        -- Insert gifts if provided
        IF @GiftListJson IS NOT NULL AND LEN(@GiftListJson) > 2
        BEGIN
            INSERT INTO M_ServiceSettingGifts (SST_Id, Gift_ID, GiftName, GiftCount)
            SELECT @NewSST_Id, Gift_ID, GiftName, GiftCount
            FROM OPENJSON(@GiftListJson)
            WITH (
                Gift_ID   VARCHAR(50)      '$.Gift_ID',
                GiftName  NVARCHAR(255)    '$.GiftName',
                GiftCount INT              '$.GiftCount'
            );
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Brand Loyalty service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
