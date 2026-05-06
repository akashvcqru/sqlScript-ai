USE [Vcqru]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-06
-- Description: Manage purchased from options for landing page (Add/Update)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageLandingPagePurchasedFrom_AI]
    @Action VARCHAR(20),
    @ID INT = NULL,
    @purchased_From VARCHAR(100) = NULL,
    @IsActive BIT = 1,
    @Comp_ID VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'Add'
    BEGIN
        IF EXISTS (SELECT 1 FROM purchased_FromLandingpage WHERE purchased_From = @purchased_From AND Comp_ID = @Comp_ID AND IsDeleted = 0)
        BEGIN
            SELECT 0 AS [ID], 'Purchased from option already exists' AS [Message], 0 AS [Status];
            RETURN;
        END

        INSERT INTO purchased_FromLandingpage (purchased_From, Comp_ID, IsActive, IsDeleted, Create_Date)
        VALUES (@purchased_From, @Comp_ID, @IsActive, 0, GETDATE());
        
        SELECT SCOPE_IDENTITY() AS [ID], 'Added successfully' AS [Message], 1 AS [Status];
    END
    ELSE IF @Action = 'Update'
    BEGIN
        IF @ID IS NULL OR @ID <= 0
        BEGIN
            SELECT 0 AS [ID], 'Valid ID is required for update' AS [Message], 0 AS [Status];
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM purchased_FromLandingpage WHERE ID = @ID)
        BEGIN
            UPDATE purchased_FromLandingpage
            SET 
                purchased_From = ISNULL(@purchased_From, purchased_From),
                IsActive = ISNULL(@IsActive, IsActive)
            WHERE ID = @ID;

            SELECT @ID AS [ID], 'Updated successfully' AS [Message], 1 AS [Status];
        END
        ELSE
        BEGIN
            SELECT @ID AS [ID], 'Option not found' AS [Message], 0 AS [Status];
        END
    END
    ELSE IF @Action = 'List'
    BEGIN
        SELECT ID, purchased_From, IsActive, Create_Date
        FROM purchased_FromLandingpage
        WHERE IsDeleted = 0 
        AND (Comp_ID = @Comp_ID OR @Comp_ID IS NULL)
        ORDER BY Create_Date DESC;
    END
END
GO
