CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateCompanyLogo_AI]
    @Comp_ID NVARCHAR(50),
    @Logo_Path NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Comp_Reg 
    SET Logo_Path = @Logo_Path, 
        Update_Flag = 1 
    WHERE Comp_ID = @Comp_ID;

    IF @@ROWCOUNT > 0
        SELECT 1 AS Success, 'Company logo updated successfully.' AS Message;
    ELSE
        SELECT 0 AS Success, 'Company not found or update failed.' AS Message;
END
GO
