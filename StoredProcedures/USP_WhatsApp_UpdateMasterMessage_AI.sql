/****** Object:  StoredProcedure [dbo].[USP_WhatsApp_UpdateMasterMessage_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_WhatsApp_UpdateMasterMessage_AI]
(
    @Id INT,
    @Comp_ID VARCHAR(50) = NULL,
    @TemplateId VARCHAR(100),
    @TemplateName VARCHAR(150),
    @TemplateMessage NVARCHAR(MAX) = NULL,
    @MessageType VARCHAR(20),
    @IsDefault BIT = 0,
    @IsActive BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@IsDefault = 1)
    BEGIN
        UPDATE tbl_whatsapp_message_master 
        SET is_default = 0 
        WHERE messagetype = @MessageType AND ID <> @Id
          AND ((@Comp_ID IS NULL AND comp_id IS NULL) OR comp_id = @Comp_ID);
    END

    UPDATE tbl_whatsapp_message_master
    SET 
        comp_id = @Comp_ID,
        template_id = @TemplateId,
        template_name = @TemplateName,
        template_message = @TemplateMessage,
        messagetype = @MessageType,
        is_default = @IsDefault,
        is_active = @IsActive,
        updated_date = GETDATE()
    WHERE ID = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO
