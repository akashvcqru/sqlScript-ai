CREATE OR ALTER PROCEDURE [dbo].[USP_GetDirectorDetail_AI]
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        DirectorName,
        DirectorLastName,
        SalutationId,
        Designation,
        DirectorFatherName,
        DirectorEmail,
        DirectorMobile,
        DirectorAddress,
        DirectorPan,
        AadharNumber,
        DirectorPhoto,
        PANCardImage,
        ResiAddress
    FROM Comp_Reg
    WHERE Comp_ID = @Comp_ID;
END
GO
