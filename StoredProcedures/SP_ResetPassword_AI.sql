CREATE OR ALTER PROCEDURE [dbo].[SP_ResetPassword_AI]
    @EmailID NVARCHAR(255),
    @NewPassword NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Update password if user exists
    IF EXISTS (SELECT 1 FROM Comp_Reg WHERE Comp_Email = @EmailID)
    BEGIN
        UPDATE Comp_Reg
        SET Password = @NewPassword
        WHERE Comp_Email = @EmailID;

        SELECT 1 AS Result; -- success
    END
    ELSE
    BEGIN
        SELECT 0 AS Result; -- user not found
    END
END
GO
