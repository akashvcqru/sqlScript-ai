USE [Vcqru]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-06
-- Description: Manage user types for landing page (Add/Update)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageLandingPageUserTypes_AI]
    @Action VARCHAR(20),
    @ID INT = NULL,
    @User_Type VARCHAR(100) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'Add'
    BEGIN
        IF EXISTS (SELECT 1 FROM user_typemasterLandingpage WHERE User_Type = @User_Type AND IsDeleted = 0)
        BEGIN
            SELECT 0 AS [ID], 'User type already exists' AS [Message], 0 AS [Status];
            RETURN;
        END

        INSERT INTO user_typemasterLandingpage (User_Type, IsActive, IsDeleted, Create_Date)
        VALUES (@User_Type, @IsActive, 0, GETDATE());
        
        SELECT SCOPE_IDENTITY() AS [ID], 'Added successfully' AS [Message], 1 AS [Status];
    END
    ELSE IF @Action = 'Update'
    BEGIN
        IF @ID IS NULL OR @ID <= 0
        BEGIN
            SELECT 0 AS [ID], 'Valid ID is required for update' AS [Message], 0 AS [Status];
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM user_typemasterLandingpage WHERE ID = @ID)
        BEGIN
            UPDATE user_typemasterLandingpage
            SET 
                User_Type = ISNULL(@User_Type, User_Type),
                IsActive = ISNULL(@IsActive, IsActive)
            WHERE ID = @ID;

            SELECT @ID AS [ID], 'Updated successfully' AS [Message], 1 AS [Status];
        END
        ELSE
        BEGIN
            SELECT @ID AS [ID], 'User type not found' AS [Message], 0 AS [Status];
        END
    END
    ELSE IF @Action = 'List'
    BEGIN
        SELECT ID, User_Type, IsActive, Create_Date
        FROM user_typemasterLandingpage
        WHERE IsDeleted = 0
        ORDER BY Create_Date DESC;
    END
END
GO
