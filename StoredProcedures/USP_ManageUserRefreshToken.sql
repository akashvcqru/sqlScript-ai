/****** Object:  StoredProcedure [dbo].[USP_ManageUserRefreshToken]    Script Date: 3/10/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageUserRefreshToken]
    @Action NVARCHAR(20), -- 'SAVE', 'GET', 'REVOKE', 'REVOKE_ALL'
    @UserId NVARCHAR(100) = NULL,
    @Comp_ID NVARCHAR(50) = NULL,
    @RefreshToken NVARCHAR(MAX) = NULL,
    @Device NVARCHAR(50) = NULL,
    @ExpiryDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'SAVE'
    BEGIN
        -- Remove existing tokens for this user and device
        DELETE FROM UserRefreshTokens WHERE UserId = @UserId AND Device = @Device;

        INSERT INTO UserRefreshTokens (UserId, Comp_ID, RefreshToken, Device, ExpiryDate)
        VALUES (@UserId, @Comp_ID, @RefreshToken, @Device, @ExpiryDate);
    END
    ELSE IF @Action = 'GET'
    BEGIN
        SELECT UserId, Comp_ID, RefreshToken, Device, ExpiryDate FROM UserRefreshTokens WHERE RefreshToken = @RefreshToken;
    END
    ELSE IF @Action = 'REVOKE'
    BEGIN
        DELETE FROM UserRefreshTokens WHERE RefreshToken = @RefreshToken;
    END
    ELSE IF @Action = 'REVOKE_ALL'
    BEGIN
        DELETE FROM UserRefreshTokens WHERE UserId = @UserId;
    END
END
GO
