SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-05-12
-- Description: Changes company password
-- =============================================
ALTER PROCEDURE [dbo].[USP_ChangePassword_AI]
    @CompId NVARCHAR(12),
    @OldPassword NVARCHAR(15),
    @NewPassword NVARCHAR(215),
    @ConfirmPassword NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Message NVARCHAR(255);
    DECLARE @Success INT = 0;
    DECLARE @CurrentPassword NVARCHAR(255);

    -- Step 1: Check if user exists
    SELECT @CurrentPassword = [Password]
    FROM Comp_Reg
    WHERE Comp_ID = @CompId;

    IF @CurrentPassword IS NULL
    BEGIN
        SET @Message = 'User not found.';
    END
    -- Step 2: Check if old password matches
    ELSE IF @CurrentPassword <> @OldPassword
    BEGIN
        SET @Message = 'Old password is incorrect.';
    END
    -- Step 3: Validate new and confirm password match
    ELSE IF @NewPassword <> @ConfirmPassword
    BEGIN
        SET @Message = 'New password and confirm password do not match.';
    END
    -- Step 4: Update password
    ELSE
    BEGIN
        UPDATE Comp_Reg
        SET [Password] = @NewPassword
        WHERE Comp_ID = @CompId;

        SET @Message = 'Password changed successfully.';
        SET @Success = 1;
    END

    SELECT @Message AS [Message], @Success AS [Success];
END
GO
