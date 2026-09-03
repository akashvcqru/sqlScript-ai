-- =====================================================================================
-- Migration: 20260903_Create_USP_WhatsApp_GetCompanyDisplayNameByPhoneId_AI
-- Description: Creates stored procedure to fetch dynamic DisplayName from tbl_whatsapp_company_settings
--              based on PhoneNumberId with fallback to default setting.
-- =====================================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_WhatsApp_GetCompanyDisplayNameByPhoneId_AI]
(
    @PhoneNumberId VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DisplayName VARCHAR(100) = NULL;

    -- 1. Try to find active company phone setting matching PhoneNumberId
    IF (@PhoneNumberId IS NOT NULL AND @PhoneNumberId <> '')
    BEGIN
        SELECT TOP 1 @DisplayName = DisplayName
        FROM tbl_whatsapp_company_settings
        WHERE PhoneNumberId = @PhoneNumberId AND IsActive = 1;
    END

    -- 2. Fallback to active default setting if not matched or DisplayName is empty
    IF (@DisplayName IS NULL OR LTRIM(RTRIM(@DisplayName)) = '')
    BEGIN
        SELECT TOP 1 @DisplayName = DisplayName
        FROM tbl_whatsapp_company_settings
        WHERE IsDefault = 1 AND IsActive = 1;
    END

    SELECT @DisplayName AS DisplayName;
END
GO
