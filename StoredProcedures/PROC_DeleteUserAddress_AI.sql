CREATE OR ALTER PROCEDURE [dbo].[PROC_DeleteUserAddress_AI]
    @AddressId INT,
    @UserId INT,
    @Message NVARCHAR(200) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [User_Address] WHERE AddressId = @AddressId AND UserId = @UserId AND IsDeleted = 0)
        BEGIN
            UPDATE [User_Address]
            SET IsDeleted = 1
            WHERE AddressId = @AddressId AND UserId = @UserId;
            
            SET @Message = 'Address deleted successfully.';
        END
        ELSE
        BEGIN
            SET @Message = 'Address not found or does not belong to the user.';
        END
    END TRY
    BEGIN CATCH
        SET @Message = 'Failed to delete address: ' + ERROR_MESSAGE();
    END CATCH
END
GO
