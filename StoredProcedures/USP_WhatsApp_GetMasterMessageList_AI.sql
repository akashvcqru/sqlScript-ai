/****** Object:  StoredProcedure [dbo].[USP_WhatsApp_GetMasterMessageList_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
