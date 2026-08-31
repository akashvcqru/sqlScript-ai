/****** Object:  StoredProcedure [dbo].[USP_WhatsApp_AddMasterMessage_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_WhatsApp_AddMasterMessage_AI]
(
    @Comp_ID VARCHAR(50) = NULL,
    @TemplateId VARCHAR(100),
    @TemplateName VARCHAR(150),
    @TemplateMessage NVARCHAR(MAX) = NULL,
    @MessageType VARCHAR(20),
    @IsDefault BIT = 0,
    @IsActive BIT = 1,
    @CreatedBy VARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@IsDefault = 1)
    BEGIN
        UPDATE tbl_whatsapp_message_master 
        SET is_default = 0 
        WHERE messagetype = @MessageType
          AND ((@Comp_ID IS NULL AND comp_id IS NULL) OR comp_id = @Comp_ID);
    END

    INSERT INTO tbl_whatsapp_message_master 
        (comp_id, template_id, template_name, template_message, messagetype, is_default, is_active, created_by, created_date)
    VALUES 
        (@Comp_ID, @TemplateId, @TemplateName, @TemplateMessage, @MessageType, @IsDefault, @IsActive, @CreatedBy, GETDATE());

    SELECT SCOPE_IDENTITY() AS NewId;
END
GO
