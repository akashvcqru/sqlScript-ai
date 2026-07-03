CREATE OR ALTER PROCEDURE [dbo].[PROC_GetUserAddresses]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        AddressId,
        UserId,
        FullName,
        MobileNumber,
        AddressLine1,
        AddressLine2,
        City,
        State,
        PostalCode,
        Country,
        IsDefault,
        CreatedDate
    FROM 
        User_Address
    WHERE 
        UserId = @UserId
        AND (IsDeleted = 0 OR IsDeleted IS NULL);
END
GO
