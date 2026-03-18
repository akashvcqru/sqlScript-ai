-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingAnticounterfit_AI
-- Purpose        : Insert Anticounterfit service setting.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingAnticounterfit_AI]
    @Comp_ID      VARCHAR(50),
    @Pro_ID       VARCHAR(50),
    @Service_ID   VARCHAR(50),
    @Subscribe_Id VARCHAR(50)   = NULL,

    @DateFrom     DATETIME      = NULL,
    @DateTo       DATETIME      = NULL,

    @Comments     NVARCHAR(1000) = NULL,
    @EntryDate    DATETIME       = NULL,

    @Points          NUMERIC(18,0) = 0,
    @IsCashConvert   INT           = 1,
    @IsCash          NUMERIC(18,0) = 0,
    @Frequency       INT           = 1,
    @IsActive        INT           = 0,
    @IsDelete        INT           = 0,
    @AmtType         VARCHAR(12)   = 'Fixed',
    @Minval          NUMERIC(18,0) = 0,
    @Maxval          NUMERIC(18,0) = 0,
    @totalamont      NUMERIC(18,0) = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Resolve Subscribe_Id if not supplied
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
            Subscribe_Id,
            Points, IsCashConvert, IsCash,
            DateFrom, DateTo,
            Comments, Entry_Date,
            Frequency, IsActive, IsDelete,
            AmtType, Minval, Maxval, totalamont
        )
        VALUES
        (
            @Subscribe_Id,
            @Points, @IsCashConvert, @IsCash,
            @DateFrom, @DateTo,
            @Comments, ISNULL(@EntryDate, GETDATE()),
            @Frequency, @IsActive, @IsDelete,
            @AmtType, @Minval, @Maxval, @totalamont
        );

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Anticounterfit service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
