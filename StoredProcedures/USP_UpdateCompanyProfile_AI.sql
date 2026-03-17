CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateCompanyProfile_AI]
    @Comp_ID NVARCHAR(50),
    @Comp_Name NVARCHAR(50) = NULL,
    @WebSite NVARCHAR(50) = NULL,
    @Address NVARCHAR(MAX) = NULL,
    @City_ID DECIMAL(18,0) = NULL,
    @Contact_Person NVARCHAR(50) = NULL,
    @Mobile_No NVARCHAR(50) = NULL,
    @Phone_No NVARCHAR(50) = NULL,
    @Fax NVARCHAR(50) = NULL,
    @Pincode NVARCHAR(10) = NULL,
    @Landline NVARCHAR(20) = NULL,
    @CompanyIndustry NVARCHAR(200) = NULL,
    @CompanyAddress NVARCHAR(MAX) = NULL,
    @Comp_Cat_Id DECIMAL(18,0) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Comp_Reg
    SET 
        Comp_Name = ISNULL(@Comp_Name, Comp_Name),
        WebSite = ISNULL(@WebSite, WebSite),
        Address = ISNULL(@Address, Address),
        City_ID = ISNULL(@City_ID, City_ID),
        Contact_Person = ISNULL(@Contact_Person, Contact_Person),
        Mobile_No = ISNULL(@Mobile_No, Mobile_No),
        Phone_No = ISNULL(@Phone_No, Phone_No),
        Fax = ISNULL(@Fax, Fax),
        Pincode = ISNULL(@Pincode, Pincode),
        Landline = ISNULL(@Landline, Landline),
        CompanyIndustry = ISNULL(@CompanyIndustry, CompanyIndustry),
        CompanyAddress = ISNULL(@CompanyAddress, CompanyAddress),
        Comp_Cat_Id = ISNULL(@Comp_Cat_Id, Comp_Cat_Id),
        Update_Flag = 1 -- Mark as updated
    WHERE Comp_ID = @Comp_ID;

    IF @@ROWCOUNT > 0
        SELECT 1 AS Success, 'Company profile updated successfully.' AS Message;
    ELSE
        SELECT 0 AS Success, 'Company not found or no changes made.' AS Message;
END
GO
