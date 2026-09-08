/****** Object:  StoredProcedure [dbo].[USP_WhatsApp_GetVendorMessageList_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_WhatsApp_GetVendorMessageList_AI]
(
    @CompId VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Assigned Vendor Mappings
    SELECT 
        v.ID AS Id,
        v.master_template_id AS MasterTemplateId,
        v.template_id AS TemplateId,
        m.template_name AS TemplateName,
        m.template_message AS TemplateMessage,
        v.messagetype AS MessageType,
        v.is_active AS IsActive,
        v.created_by AS CreatedBy,
        v.created_date AS CreatedDate,
        v.updated_date AS UpdatedDate
    FROM tbl_whatsapp_message_vendor v
    LEFT JOIN tbl_whatsapp_message_master m ON v.master_template_id = m.ID
    WHERE v.comp_id = @CompId AND v.is_active = 1
    ORDER BY v.ID DESC;

    -- Result Set 2: Available Active Master Templates
    SELECT 
        ID AS Id,
        template_id AS TemplateId,
        template_name AS TemplateName,
        template_message AS TemplateMessage,
        messagetype AS MessageType,
        is_default AS IsDefault,
        is_active AS IsActive,
        created_by AS CreatedBy,
        created_date AS CreatedDate,
        updated_date AS UpdatedDate
    FROM tbl_whatsapp_message_master
    WHERE is_active = 1 AND (comp_id = @CompId OR comp_id IS NULL)
    ORDER BY is_default DESC, ID DESC;
END
GO
