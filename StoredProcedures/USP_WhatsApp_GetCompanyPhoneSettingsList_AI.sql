/****** Object:  StoredProcedure [dbo].[USP_WhatsApp_GetCompanyPhoneSettingsList_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_WhatsApp_GetCompanyPhoneSettingsList_AI]
(
    @Page INT = 1,
    @Limit INT = 10,
    @Search VARCHAR(100) = NULL,
    @IsActive BIT = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@Page IS NULL OR @Page < 1) SET @Page = 1;
    IF (@Limit IS NULL OR @Limit < 1) SET @Limit = 10;
    IF (@IsExport IS NULL) SET @IsExport = 0;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    IF (@IsExport = 1)
    BEGIN
        SELECT 
            w.ID AS Id,
            w.Comp_ID AS Comp_ID,
            c.Comp_Name AS CompanyName,
            w.PhoneNumberId AS PhoneNumberId,
            w.DisplayPhoneNumber AS DisplayPhoneNumber,
            w.DisplayName AS DisplayName,
            w.IsDefault AS IsDefault,
            w.IsActive AS IsActive,
            w.CreatedDate AS CreatedDate,
            w.UpdatedDate AS UpdatedDate
        FROM tbl_whatsapp_company_settings w
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON w.Comp_ID = c.Comp_ID
        WHERE (@Search IS NULL OR @Search = '' 
               OR w.Comp_ID LIKE '%' + @Search + '%' 
               OR c.Comp_Name LIKE '%' + @Search + '%' 
               OR w.PhoneNumberId LIKE '%' + @Search + '%' 
               OR w.DisplayPhoneNumber LIKE '%' + @Search + '%' 
               OR w.DisplayName LIKE '%' + @Search + '%')
          AND (@IsActive IS NULL OR w.IsActive = @IsActive)
        ORDER BY w.IsDefault DESC, w.ID DESC;
    END
    ELSE
    BEGIN
        -- Result Set 1: Filtered Company Phone Settings List
        SELECT 
            w.ID AS Id,
            w.Comp_ID AS Comp_ID,
            c.Comp_Name AS CompanyName,
            w.PhoneNumberId AS PhoneNumberId,
            w.DisplayPhoneNumber AS DisplayPhoneNumber,
            w.DisplayName AS DisplayName,
            w.IsDefault AS IsDefault,
            w.IsActive AS IsActive,
            w.CreatedDate AS CreatedDate,
            w.UpdatedDate AS UpdatedDate
        FROM tbl_whatsapp_company_settings w
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON w.Comp_ID = c.Comp_ID
        WHERE (@Search IS NULL OR @Search = '' 
               OR w.Comp_ID LIKE '%' + @Search + '%' 
               OR c.Comp_Name LIKE '%' + @Search + '%' 
               OR w.PhoneNumberId LIKE '%' + @Search + '%' 
               OR w.DisplayPhoneNumber LIKE '%' + @Search + '%' 
               OR w.DisplayName LIKE '%' + @Search + '%')
          AND (@IsActive IS NULL OR w.IsActive = @IsActive)
        ORDER BY w.IsDefault DESC, w.ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Result Set 2: Total Count
        SELECT COUNT(1) AS TotalRecords
        FROM tbl_whatsapp_company_settings w
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON w.Comp_ID = c.Comp_ID
        WHERE (@Search IS NULL OR @Search = '' 
               OR w.Comp_ID LIKE '%' + @Search + '%' 
               OR c.Comp_Name LIKE '%' + @Search + '%' 
               OR w.PhoneNumberId LIKE '%' + @Search + '%' 
               OR w.DisplayPhoneNumber LIKE '%' + @Search + '%' 
               OR w.DisplayName LIKE '%' + @Search + '%')
          AND (@IsActive IS NULL OR w.IsActive = @IsActive);
    END
END
GO
