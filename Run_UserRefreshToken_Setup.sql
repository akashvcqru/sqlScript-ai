-- ============================================================
-- STEP 1: Create table UserRefreshTokens (if it doesn't exist)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'UserRefreshTokens')
BEGIN
    CREATE TABLE [dbo].[UserRefreshTokens] (
        [Id]           INT            IDENTITY(1,1) NOT NULL,
        [UserId]       NVARCHAR(100)  NOT NULL,
        [Comp_ID]      NVARCHAR(50)   NOT NULL,
        [RefreshToken] NVARCHAR(MAX)  NOT NULL,
        [Device]       NVARCHAR(50)   NULL,
        [ExpiryDate]   DATETIME       NOT NULL,
        [CreatedAt]    DATETIME       NOT NULL DEFAULT (GETDATE()),
        CONSTRAINT [PK_UserRefreshTokens] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    PRINT 'Table UserRefreshTokens created.';
END
ELSE
BEGIN
    PRINT 'Table UserRefreshTokens already exists. Skipped.';
END
GO

-- ============================================================
-- STEP 2: Create or Alter USP_ManageUserRefreshToken
-- Actions: SAVE | GET | REVOKE | REVOKE_ALL
-- ============================================================
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'USP_ManageUserRefreshToken')
    DROP PROCEDURE [dbo].[USP_ManageUserRefreshToken];
GO

CREATE PROCEDURE [dbo].[USP_ManageUserRefreshToken]
    @Action       NVARCHAR(20),          -- 'SAVE' | 'GET' | 'REVOKE' | 'REVOKE_ALL'
    @UserId       NVARCHAR(100) = NULL,
    @Comp_ID      NVARCHAR(50)  = NULL,
    @RefreshToken NVARCHAR(MAX) = NULL,
    @Device       NVARCHAR(50)  = NULL,
    @ExpiryDate   DATETIME      = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ── SAVE: Remove old tokens for same user+device, then insert new one ──
    IF @Action = 'SAVE'
    BEGIN
        DELETE FROM [dbo].[UserRefreshTokens]
        WHERE [UserId] = @UserId AND [Device] = @Device;

        INSERT INTO [dbo].[UserRefreshTokens]
            ([UserId], [Comp_ID], [RefreshToken], [Device], [ExpiryDate])
        VALUES
            (@UserId, @Comp_ID, @RefreshToken, @Device, @ExpiryDate);
        RETURN;
    END

    -- ── GET: Fetch a valid (non-expired) token ─────────────────────────────
    IF @Action = 'GET'
    BEGIN
        SELECT
            [UserId],
            [Comp_ID],
            [RefreshToken],
            [Device],
            [ExpiryDate]
        FROM [dbo].[UserRefreshTokens]
        WHERE [RefreshToken] = @RefreshToken
          AND [ExpiryDate]   > GETDATE();
        RETURN;
    END

    -- ── REVOKE: Delete a specific refresh token ────────────────────────────
    IF @Action = 'REVOKE'
    BEGIN
        DELETE FROM [dbo].[UserRefreshTokens]
        WHERE [RefreshToken] = @RefreshToken;
        RETURN;
    END

    -- ── REVOKE_ALL: Delete all tokens for a user ───────────────────────────
    IF @Action = 'REVOKE_ALL'
    BEGIN
        DELETE FROM [dbo].[UserRefreshTokens]
        WHERE [UserId] = @UserId;
        RETURN;
    END

END
GO

PRINT 'USP_ManageUserRefreshToken created successfully.';
