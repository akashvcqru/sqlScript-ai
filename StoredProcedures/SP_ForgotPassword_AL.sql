CREATE OR ALTER PROCEDURE [dbo].[SP_ForgotPassword_AL]
    @Email NVARCHAR(150)
AS
BEGIN
     SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Comp_Reg WHERE Comp_Email = @Email)
        SELECT 1 AS UserExists;
    ELSE
        SELECT 0 AS UserExists;
END
GO
