-- =============================================
-- Procedure: USP_ServiceActiveDeactiveDelete_AI
-- Description: Toggle IsActive or set IsDelete for service settings in both M_ServiceSubscriptionTrans and M_ServiceSubscription
-- =============================================
IF OBJECT_ID('USP_ServiceActiveDeactiveDelete_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_ServiceActiveDeactiveDelete_AI
GO

CREATE PROCEDURE USP_ServiceActiveDeactiveDelete_AI
    @SST_Id BIGINT,
    @Action NVARCHAR(20) -- 'IsActive', 'IsDelete'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Subscribe_Id NVARCHAR(50);
        DECLARE @CurrentIsActive INT;

        -- Get Subscribe_Id and current status
        SELECT @Subscribe_Id = Subscribe_Id, @CurrentIsActive = IsActive
        FROM M_ServiceSubscriptionTrans
        WHERE SST_Id = @SST_Id;

        IF @Subscribe_Id IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'Invalid SST_Id.' AS message;
            RETURN;
        END

        IF @Action = 'IsActive'
        BEGIN
            DECLARE @NewIsActive INT = CASE WHEN @CurrentIsActive = 0 THEN 1 ELSE 0 END;

            -- Update both tables
            UPDATE M_ServiceSubscriptionTrans SET IsActive = @NewIsActive WHERE SST_Id = @SST_Id;
            UPDATE M_ServiceSubscription SET IsActive = @NewIsActive WHERE Subscribe_Id = @Subscribe_Id;

            SELECT 1 AS success, 'Status updated successfully.' AS message;
        END
        ELSE IF @Action = 'IsDelete'
        BEGIN
            -- Update both tables
            UPDATE M_ServiceSubscriptionTrans SET IsDelete = 1 WHERE SST_Id = @SST_Id;
            UPDATE M_ServiceSubscription SET IsDelete = 1 WHERE Subscribe_Id = @Subscribe_Id;

            SELECT 1 AS success, 'Service setting deleted successfully.' AS message;
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'Invalid Action.' AS message;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        SELECT 0 AS success, @ErrMsg AS message;
    END CATCH
END
GO
