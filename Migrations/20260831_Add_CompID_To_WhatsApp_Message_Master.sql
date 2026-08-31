-- Migration: Add comp_id to tbl_whatsapp_message_master and update stored procedures
-- Date: 2026-08-31

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Ensure comp_id column exists in tbl_whatsapp_message_master
IF OBJECT_ID('tbl_whatsapp_message_master', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tbl_whatsapp_message_master') AND name = 'comp_id')
    BEGIN
        ALTER TABLE tbl_whatsapp_message_master ADD comp_id VARCHAR(50) NULL;
    END
END
GO

-- 2. Stored Procedure: USP_WhatsApp_AddMasterMessage_AI
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

-- 3. Stored Procedure: USP_WhatsApp_UpdateMasterMessage_AI
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

-- 4. Stored Procedure: USP_WhatsApp_GetMasterMessageList_AI
CREATE OR ALTER PROCEDURE [dbo].[USP_WhatsApp_GetMasterMessageList_AI]
(
    @Page INT = 1,
    @Limit INT = 10,
    @Search VARCHAR(100) = NULL,
    @MessageType VARCHAR(20) = NULL,
    @IsActive BIT = NULL,
    @Comp_ID VARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@Page IS NULL OR @Page < 1) SET @Page = 1;
    IF (@Limit IS NULL OR @Limit < 1) SET @Limit = 10;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -- Result Set 1: Filtered Master Templates List
    SELECT 
        m.ID AS Id,
        m.comp_id AS Comp_ID,
        c.Comp_Name AS CompanyName,
        m.template_id AS TemplateId,
        m.template_name AS TemplateName,
        m.template_message AS TemplateMessage,
        m.messagetype AS MessageType,
        m.is_default AS IsDefault,
        m.is_active AS IsActive,
        m.created_by AS CreatedBy,
        m.created_date AS CreatedDate,
        m.updated_date AS UpdatedDate
    FROM tbl_whatsapp_message_master m
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON m.comp_id = c.Comp_ID
    WHERE (@Search IS NULL OR @Search = '' 
           OR m.template_id LIKE '%' + @Search + '%' 
           OR m.template_name LIKE '%' + @Search + '%' 
           OR m.template_message LIKE '%' + @Search + '%'
           OR m.comp_id LIKE '%' + @Search + '%'
           OR c.Comp_Name LIKE '%' + @Search + '%')
      AND (@MessageType IS NULL OR @MessageType = '' OR m.messagetype = @MessageType)
      AND (@IsActive IS NULL OR m.is_active = @IsActive)
      AND (@Comp_ID IS NULL OR @Comp_ID = '' OR m.comp_id = @Comp_ID)
    ORDER BY m.is_default DESC, m.ID DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    -- Result Set 2: Total Count
    SELECT COUNT(1) AS TotalRecords
    FROM tbl_whatsapp_message_master m
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON m.comp_id = c.Comp_ID
    WHERE (@Search IS NULL OR @Search = '' 
           OR m.template_id LIKE '%' + @Search + '%' 
           OR m.template_name LIKE '%' + @Search + '%' 
           OR m.template_message LIKE '%' + @Search + '%'
           OR m.comp_id LIKE '%' + @Search + '%'
           OR c.Comp_Name LIKE '%' + @Search + '%')
      AND (@MessageType IS NULL OR @MessageType = '' OR m.messagetype = @MessageType)
      AND (@IsActive IS NULL OR m.is_active = @IsActive)
      AND (@Comp_ID IS NULL OR @Comp_ID = '' OR m.comp_id = @Comp_ID);
END
GO
