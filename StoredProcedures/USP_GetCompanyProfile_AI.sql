CREATE OR ALTER PROCEDURE [dbo].[USP_GetCompanyProfile_AI]
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        cr.Comp_ID,
        cr.Comp_Name,
        cr.Comp_Email,
        cr.WebSite,
        cr.Address,
        cm.CityName AS City,
        sm.StateName AS State,
        cr.Contact_Person,
        cr.Mobile_No,
        cr.Reg_Date,
        cr.Status,
        cr.Logo_Path,
        cr.Gstin,
        cr.CompanyPAN,
        cr.Pincode,
        cr.gst_LegalBusinessName,
        cr.gst_RegistrationStatus,
        cr.gst_BusinessConstitution,
        cr.gst_TradeName,
        cr.gst_RegistrationDate,
        cr.comp_pan_type,
        cr.comp_pan_status,
        cr.Industry_Type
    FROM Comp_Reg cr
    LEFT JOIN CityMaster cm ON cr.City_ID = cm.City_Id
    LEFT JOIN StateMaster sm ON cr.StateId = sm.State_Id
    WHERE cr.Comp_ID = @Comp_ID;
END
GO

