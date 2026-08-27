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
            ID AS Id,
            Comp_ID AS Comp_ID,
            PhoneNumberId AS PhoneNumberId,
            DisplayPhoneNumber AS DisplayPhoneNumber,
            DisplayName AS DisplayName,
            IsDefault AS IsDefault,
            IsActive AS IsActive,
            CreatedDate AS CreatedDate,
            UpdatedDate AS UpdatedDate
        FROM tbl_whatsapp_company_settings
        WHERE (@Search IS NULL OR @Search = '' OR Comp_ID LIKE '%' + @Search + '%' OR PhoneNumberId LIKE '%' + @Search + '%' OR DisplayPhoneNumber LIKE '%' + @Search + '%' OR DisplayName LIKE '%' + @Search + '%')
          AND (@IsActive IS NULL OR IsActive = @IsActive)
        ORDER BY IsDefault DESC, ID DESC;
    END
    ELSE
    BEGIN
        -- Result Set 1: Filtered Company Phone Settings List
        SELECT 
            ID AS Id,
            Comp_ID AS Comp_ID,
            PhoneNumberId AS PhoneNumberId,
            DisplayPhoneNumber AS DisplayPhoneNumber,
            DisplayName AS DisplayName,
            IsDefault AS IsDefault,
            IsActive AS IsActive,
            CreatedDate AS CreatedDate,
            UpdatedDate AS UpdatedDate
        FROM tbl_whatsapp_company_settings
        WHERE (@Search IS NULL OR @Search = '' OR Comp_ID LIKE '%' + @Search + '%' OR PhoneNumberId LIKE '%' + @Search + '%' OR DisplayPhoneNumber LIKE '%' + @Search + '%' OR DisplayName LIKE '%' + @Search + '%')
          AND (@IsActive IS NULL OR IsActive = @IsActive)
        ORDER BY IsDefault DESC, ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Result Set 2: Total Count
        SELECT COUNT(1) AS TotalRecords
        FROM tbl_whatsapp_company_settings
        WHERE (@Search IS NULL OR @Search = '' OR Comp_ID LIKE '%' + @Search + '%' OR PhoneNumberId LIKE '%' + @Search + '%' OR DisplayPhoneNumber LIKE '%' + @Search + '%' OR DisplayName LIKE '%' + @Search + '%')
          AND (@IsActive IS NULL OR IsActive = @IsActive);
    END
END
GO
