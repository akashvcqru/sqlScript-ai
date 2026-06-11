CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateCompanyProfile_AI]
    @Comp_ID NVARCHAR(50),
    @Comp_Name NVARCHAR(50) = NULL,
    @WebSite NVARCHAR(50) = NULL,
    @Address NVARCHAR(MAX) = NULL,
    @City_ID DECIMAL(18,0) = NULL,
    @StateId INT = NULL,
    @Contact_Person NVARCHAR(50) = NULL,
    @Mobile_No NVARCHAR(50) = NULL,
    @Pincode NVARCHAR(10) = NULL,
    @Gstin NVARCHAR(50) = NULL,
    @CompanyPAN NVARCHAR(50) = NULL,
    @gst_LegalBusinessName NVARCHAR(200) = NULL,
    @gst_RegistrationStatus BIT = NULL,
    @gst_BusinessConstitution NVARCHAR(200) = NULL,
    @gst_TradeName NVARCHAR(200) = NULL,
    @gst_RegistrationDate NVARCHAR(50) = NULL,
    @comp_pan_type NVARCHAR(50) = NULL,
    @comp_pan_status NVARCHAR(50) = NULL,
    @Industry_Type NVARCHAR(100) = NULL,
    @SalesPersonName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Comp_Reg
    SET 
        Comp_Name = ISNULL(@Comp_Name, Comp_Name),
        WebSite = ISNULL(@WebSite, WebSite),
        Address = ISNULL(@Address, Address),
        City_ID = ISNULL(@City_ID, City_ID),
        StateId = ISNULL(@StateId, StateId),
        Contact_Person = ISNULL(@Contact_Person, Contact_Person),
        Mobile_No = ISNULL(@Mobile_No, Mobile_No),
        Pincode = ISNULL(@Pincode, Pincode),
        Gstin = ISNULL(@Gstin, Gstin),
        CompanyPAN = ISNULL(@CompanyPAN, CompanyPAN),
        gst_LegalBusinessName = ISNULL(@gst_LegalBusinessName, gst_LegalBusinessName),
        gst_RegistrationStatus = ISNULL(@gst_RegistrationStatus, gst_RegistrationStatus),
        gst_BusinessConstitution = ISNULL(@gst_BusinessConstitution, gst_BusinessConstitution),
        gst_TradeName = ISNULL(@gst_TradeName, gst_TradeName),
        gst_RegistrationDate = ISNULL(@gst_RegistrationDate, gst_RegistrationDate),
        comp_pan_type = ISNULL(@comp_pan_type, comp_pan_type),
        comp_pan_status = ISNULL(@comp_pan_status, comp_pan_status),
        Industry_Type = ISNULL(@Industry_Type, Industry_Type),
        SalesPersonName = ISNULL(@SalesPersonName, SalesPersonName),
        Update_Flag = 1
    WHERE Comp_ID = @Comp_ID;

    IF @@ROWCOUNT > 0
        SELECT 1 AS Success, 'Company profile updated successfully.' AS Message;
    ELSE
        SELECT 0 AS Success, 'Company not found or no changes made.' AS Message;
END
GO

