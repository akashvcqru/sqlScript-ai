-- ============================================================
-- Run Script: Update USP_GetCompanyLoginDetails
-- Purpose : Sets ekycCompleted = 1 only when
--           comp_pan_status = 'VALID' AND gst_RegistrationStatus = 1
-- Date    : 2026-03-10
-- ============================================================

-- ── STEP 1: Drop existing procedure ────────────────────────
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'USP_GetCompanyLoginDetails')
BEGIN
    DROP PROCEDURE [dbo].[USP_GetCompanyLoginDetails];
    PRINT 'Existing USP_GetCompanyLoginDetails dropped.';
END
GO

-- ── STEP 2: Re-create with updated ekycCompleted logic ─────
CREATE PROCEDURE [dbo].[USP_GetCompanyLoginDetails]
	@Email    NVARCHAR(100),
	@Password NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

    -- 1. Validate Credentials and Get Company Info
    DECLARE @CompID NVARCHAR(50);
    SELECT @CompID = Comp_ID 
    FROM Comp_Reg 
    WHERE LTRIM(RTRIM(Comp_Email)) = LTRIM(RTRIM(@Email)) 
      AND LTRIM(RTRIM(Password))   = LTRIM(RTRIM(@Password)) 
      AND (Status = 1 OR Status IS NULL);

    IF @CompID IS NULL
    BEGIN
        SELECT 
            0                    AS success, 
            'Invalid email or password.' AS message,
            CAST(0 AS BIT)       AS isPolicyAccepted,
            CAST(0 AS BIT)       AS ekycCompleted,
            CAST(0 AS BIT)       AS productRegistered,
            CAST(0 AS BIT)       AS serviceActivated,
            NULL                 AS Comp_ID,
            NULL                 AS Service_ID,
            NULL                 AS ServiceName;
        RETURN;
    END

    -- 2. Fetch Policy Acceptance Status
    DECLARE @IsPolicyAccepted BIT = 0;
    IF EXISTS (SELECT 1 FROM Tbl_UserPolicyAcceptance WHERE Comp_Id = @CompID)
    BEGIN
        SET @IsPolicyAccepted = 1;
    END

    -- 3. Check Onboarding Status

    -- ekycCompleted: true only when PAN is VALID and GST is registered (1)
    DECLARE @EkycCompleted BIT = 0;
    SELECT @EkycCompleted = CASE 
        WHEN comp_pan_status = 'VALID' AND gst_RegistrationStatus = 1 THEN 1 
        ELSE 0 
    END 
    FROM Comp_Reg WHERE Comp_ID = @CompID;

    -- productRegistered: true if company exists in Pro_Reg
    DECLARE @ProductRegistered BIT = 0;
    IF EXISTS (SELECT 1 FROM Pro_Reg WHERE Comp_ID = @CompID)
    BEGIN
        SET @ProductRegistered = 1;
    END

    -- serviceActivated: true if at least one active, non-deleted subscription exists
    DECLARE @ServiceActivated BIT = 0;
    IF EXISTS (
        SELECT 1 FROM M_ServiceSubscription 
        WHERE Comp_ID = @CompID 
          AND (IsActive = 1 OR IsActive IS NULL) 
          AND (IsDelete = 0  OR IsDelete IS NULL)
    )
    BEGIN
        SET @ServiceActivated = 1;
    END

    -- 4. Return Main Response with DISTINCT Services List
    SELECT DISTINCT
        1                              AS success,
        'Services fetched successfully.' AS message,
        @IsPolicyAccepted              AS isPolicyAccepted,
        @EkycCompleted                 AS ekycCompleted,
        @ProductRegistered             AS productRegistered,
        @ServiceActivated              AS serviceActivated,
        c.Comp_ID,
        s.Service_ID,
        s.ServiceName
    FROM Comp_Reg c
    LEFT JOIN M_ServiceSubscription ss ON c.Comp_ID = ss.Comp_ID
    LEFT JOIN M_Service s              ON ss.Service_ID = s.Service_ID
    WHERE c.Comp_ID = @CompID
      AND (s.IsDelete = 0 OR s.IsDelete IS NULL);

END
GO

PRINT 'USP_GetCompanyLoginDetails updated successfully.';
PRINT '';
PRINT 'ekycCompleted logic:';
PRINT '  TRUE  => comp_pan_status = ''VALID'' AND gst_RegistrationStatus = 1';
PRINT '  FALSE => any other combination';
