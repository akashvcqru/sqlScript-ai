CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateDirectorDetail_AI]
    @Comp_ID NVARCHAR(50),
    @DirectorName NVARCHAR(55) = NULL,
    @DirectorLastName NVARCHAR(100) = NULL,
    @SalutationId INT = NULL,
    @Designation NVARCHAR(100) = NULL,
    @DirectorFatherName NVARCHAR(55) = NULL,
    @DirectorEmail NVARCHAR(100) = NULL,
    @DirectorMobile NVARCHAR(20) = NULL,
    @DirectorAddress NVARCHAR(MAX) = NULL,
    @DirectorPan NVARCHAR(20) = NULL,
    @AadharNumber NVARCHAR(12) = NULL,
    @ResiAddress NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Comp_Reg
    SET 
        DirectorName = ISNULL(@DirectorName, DirectorName),
        DirectorLastName = ISNULL(@DirectorLastName, DirectorLastName),
        SalutationId = ISNULL(@SalutationId, SalutationId),
        Designation = ISNULL(@Designation, Designation),
        DirectorFatherName = ISNULL(@DirectorFatherName, DirectorFatherName),
        DirectorEmail = ISNULL(@DirectorEmail, DirectorEmail),
        DirectorMobile = ISNULL(@DirectorMobile, DirectorMobile),
        DirectorAddress = ISNULL(@DirectorAddress, DirectorAddress),
        DirectorPan = ISNULL(@DirectorPan, DirectorPan),
        AadharNumber = ISNULL(@AadharNumber, AadharNumber),
        ResiAddress = ISNULL(@ResiAddress, ResiAddress)
    WHERE Comp_ID = @Comp_ID;

    IF @@ROWCOUNT > 0
        SELECT 1 AS Success, 'Director details updated successfully.' AS Message;
    ELSE
        SELECT 0 AS Success, 'Company not found or no changes made.' AS Message;
END
GO
