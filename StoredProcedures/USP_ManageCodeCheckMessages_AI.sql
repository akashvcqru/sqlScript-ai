SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:        AI Assistant
-- Create date:   2026-04-13
-- Description:   Manage custom code check messages for landing pages
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageCodeCheckMessages_AI]
    @Action VARCHAR(20),
    @Id INT = NULL,
    @Comp_Id VARCHAR(50) = NULL,
    @Service_Id VARCHAR(50) = NULL,
    @Message_Type VARCHAR(20) = NULL,
    @Message_Text NVARCHAR(MAX) = NULL OUTPUT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'Add'
    BEGIN
        INSERT INTO [LandingPage_CodeCheckMessages] (Comp_Id, Service_Id, Message_Type, Message_Text, IsActive, CreatedDate)
        VALUES (@Comp_Id, @Service_Id, @Message_Type, @Message_Text, @IsActive, GETDATE());

        SELECT 1 AS Status, 'Message added successfully' AS Message;
    END
    ELSE IF @Action = 'Update'
    BEGIN
        UPDATE [LandingPage_CodeCheckMessages]
        SET Message_Text = @Message_Text,
            Service_Id = ISNULL(@Service_Id, Service_Id),
            Message_Type = ISNULL(@Message_Type, Message_Type),
            IsActive = @IsActive,
            UpdatedDate = GETDATE()
        WHERE Id = @Id AND Comp_Id = @Comp_Id;

        SELECT 1 AS Status, 'Message updated successfully' AS Message;
    END
    ELSE IF @Action = 'Delete'
    BEGIN
        DELETE FROM [LandingPage_CodeCheckMessages]
        WHERE Id = @Id AND Comp_Id = @Comp_Id;

        SELECT 1 AS Status, 'Message deleted successfully' AS Message;
    END
    ELSE IF @Action = 'ListAll'
    BEGIN
        SELECT * FROM [LandingPage_CodeCheckMessages] ORDER BY CreatedDate DESC;
    END
    ELSE IF @Action = 'ListByVendor'
    BEGIN
        SELECT * FROM [LandingPage_CodeCheckMessages] 
        WHERE Comp_Id = @Comp_Id 
        ORDER BY CreatedDate DESC;
    END
    ELSE IF @Action = 'GetMessage'
    BEGIN
        -- Priority: 1. Specific Service, 2. Global for Vendor (Service_Id IS NULL)
        SELECT TOP 1 @Message_Text = Message_Text
        FROM [LandingPage_CodeCheckMessages]
        WHERE Comp_Id = @Comp_Id 
          AND Message_Type = @Message_Type
          AND (Service_Id = @Service_Id OR Service_Id IS NULL)
          AND IsActive = 1
        ORDER BY CASE WHEN Service_Id = @Service_Id THEN 0 ELSE 1 END;
    END
END
GO
