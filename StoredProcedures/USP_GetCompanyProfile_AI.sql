CREATE OR ALTER PROCEDURE [dbo].[USP_GetCompanyProfile_AI]
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Comp_ID,
        Comp_Name,
        Comp_Email,
        WebSite,
        Address,
        City_ID,
        Contact_Person,
        Mobile_No,
        Phone_No,
        Fax,
        Gstin,
        FssiNo,
        MsmeNo,
        CompanyPAN,
        Pincode,
        Landline,
        CompanyIndustry,
        CompanyAddress,
        comp_pan_status,
        gst_RegistrationStatus,
        Comp_Cat_Id,
        Logo_Path,
        Reg_Date,
        Status
    FROM Comp_Reg
    WHERE Comp_ID = @Comp_ID;
END
GO
