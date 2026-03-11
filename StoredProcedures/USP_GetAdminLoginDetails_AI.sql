/****** Object:  StoredProcedure [dbo].[USP_GetAdminLoginDetails]    Script Date: 3/10/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetAdminLoginDetails_AI]
	@UserId    NVARCHAR(100),
	@Password  NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

    -- ── 1. Validate Credentials ─────────────────────────────────────────────
    DECLARE @ActualUserId NVARCHAR(50);
    DECLARE @UserType NVARCHAR(50);

    SELECT 
        @ActualUserId = User_Id,
        @UserType = User_Type
    FROM Admin_Login 
    WHERE LTRIM(RTRIM(User_Id)) = LTRIM(RTRIM(@UserId)) 
      AND LTRIM(RTRIM(Password)) = LTRIM(RTRIM(@Password)) 
      AND (Status = '1' OR Status = 1 OR Status IS NULL); -- Safer status check

    IF @ActualUserId IS NULL
    BEGIN
        SELECT 
            0                            AS success, 
            'Invalid user id or password.' AS message,
            CAST(1 AS BIT)               AS isPolicyAccepted,
            CAST(1 AS BIT)               AS ekycCompleted,
            CAST(1 AS BIT)               AS productRegistered,
            CAST(1 AS BIT)               AS serviceActivated,
            'Admin'                      AS Comp_ID,
            NULL                         AS Service_ID,
            NULL                         AS ServiceName;
        RETURN;
    END

    -- ── 2. Return Admin Details ─────────────────────────────────────────────
    -- Note: Admin has all onboarding flags set to TRUE by default.
    -- Comp_ID is returned as 'Admin' to identify admin sessions.
    SELECT 
        1                                AS success,
        'Admin login successful.'        AS message,
        CAST(1 AS BIT)                   AS isPolicyAccepted,
        CAST(1 AS BIT)                   AS ekycCompleted,
        CAST(1 AS BIT)                   AS productRegistered,
        CAST(1 AS BIT)                   AS serviceActivated,
        'Admin'                          AS Comp_ID,
        NULL                             AS Service_ID,
        'Admin Services'                 AS ServiceName;

END
GO
