-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingCashTransfer_AI
-- Purpose        : Insert Cash Transfer service setting.
--                  Handles points-to-cash conversion parameters.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingCashTransfer_AI]
    @Comp_ID       VARCHAR(50),
    @Pro_ID        VARCHAR(50),
    @Service_ID    VARCHAR(50),
    @Subscribe_Id  VARCHAR(50)   = NULL,

    @DateFrom      DATETIME      = NULL,
    @DateTo        DATETIME      = NULL,

    @Points        DECIMAL(18,2) = NULL,
    @IsCashConvert INT           = NULL,
    @IsCash        DECIMAL(18,2) = NULL,
    @Frequency     INT           = NULL,

    @Comments      NVARCHAR(1000) = NULL,
    @EntryDate     DATETIME       = NULL,
    @DML           VARCHAR(10)    = 'I'
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
            Subscribe_Id,
            DateFrom, DateTo,
            Points, IsCashConvert, IsCash, Frequency,
            Comments, Entry_Date, IsActive, IsDelete
        )
        VALUES
        (
            @Subscribe_Id,
            @DateFrom, @DateTo,
            @Points, @IsCashConvert, @IsCash, @Frequency,
            @Comments, ISNULL(@EntryDate, GETDATE()), 1, 0
        );

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Cash Transfer service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
