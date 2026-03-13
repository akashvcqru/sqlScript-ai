/****** Object:  StoredProcedure [dbo].[USP_GetCompanyLoginDetails]    Script Date: 3/10/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetCompanyLoginDetails_AI]
	@Email    NVARCHAR(100),
	@Password NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

    -- ── 1. Validate Credentials ─────────────────────────────────────────────
    DECLARE @CompID NVARCHAR(50);
    SELECT @CompID = Comp_ID 
    FROM Comp_Reg 
    WHERE LTRIM(RTRIM(Comp_Email)) = LTRIM(RTRIM(@Email)) 
      AND LTRIM(RTRIM(Password))   = LTRIM(RTRIM(@Password)) 
      AND (Status = 1 OR Status IS NULL);

    IF @CompID IS NULL
    BEGIN
        SELECT 
            0                            AS success, 
            'Invalid email or password.' AS message,
            CAST(0 AS BIT)               AS isPolicyAccepted,
            CAST(0 AS BIT)               AS ekycCompleted,
            CAST(0 AS BIT)               AS productRegistered,
            CAST(0 AS BIT)               AS serviceActivated,
            NULL                         AS Comp_ID,
            NULL                         AS Service_ID,
            NULL                         AS ServiceName;
        RETURN;
    END

    -- ── 2. isPolicyAccepted ─────────────────────────────────────────────────
    --      TRUE  => company has accepted the policy (row exists in Tbl_UserPolicyAcceptance)
    DECLARE @IsPolicyAccepted BIT = 0;
    IF EXISTS (SELECT 1 FROM Tbl_UserPolicyAcceptance WHERE Comp_Id = @CompID)
        SET @IsPolicyAccepted = 1;

    -- ── 3. ekycCompleted ────────────────────────────────────────────────────
    --      TRUE  => comp_pan_status = 'VALID'  AND  gst_RegistrationStatus = 1
    --      FALSE => any other combination (NULL, invalid, unregistered GST)
    DECLARE @EkycCompleted BIT = 0;
    SELECT @EkycCompleted = CASE 
        WHEN comp_pan_status = 'VALID' AND gst_RegistrationStatus = 1 THEN 1 
        ELSE 0 
    END 
    FROM Comp_Reg WHERE Comp_ID = @CompID;

    -- ── 4. productRegistered ────────────────────────────────────────────────
    --      TRUE  => at least one product exists in Pro_Reg for this company
    DECLARE @ProductRegistered BIT = 0;
    IF EXISTS (SELECT 1 FROM Pro_Reg WHERE Comp_ID = @CompID)
        SET @ProductRegistered = 1;

    -- ── 5. serviceActivated ─────────────────────────────────────────────────
    --      TRUE  => at least one active, non-deleted subscription in M_ServiceSubscription
    DECLARE @ServiceActivated BIT = 0;
    IF EXISTS (
        SELECT 1 FROM M_ServiceSubscription 
        WHERE Comp_ID  = @CompID 
          AND (IsActive = 1 OR IsActive IS NULL) 
          AND (IsDelete = 0  OR IsDelete IS NULL)
    )
        SET @ServiceActivated = 1;

    -- ── 6. Return onboardingStatus + distinct services list ─────────────────
    DECLARE @BalanceAmount DECIMAL(18, 2) = 0;
    SELECT @BalanceAmount = ISNULL(balance_amount, 0) FROM Paytm_balance WHERE Comp_ID = @CompID;

    SELECT DISTINCT
        1                                AS success,
        'Services fetched successfully.' AS message,
        @IsPolicyAccepted                AS isPolicyAccepted,
        @EkycCompleted                   AS ekycCompleted,
        @ProductRegistered               AS productRegistered,
        @ServiceActivated                AS serviceActivated,
        c.Comp_ID,
        c.Comp_Name,
        c.Status,
        c.Contact_Person                 AS UserName,
        c.Mobile_No                      AS MobileNumber,
        @BalanceAmount                   AS BalanceAmount,
        s.Service_ID,
        s.ServiceName
    FROM Comp_Reg c
    LEFT JOIN M_ServiceSubscription ss ON c.Comp_ID     = ss.Comp_ID
    LEFT JOIN M_Service s              ON ss.Service_ID  = s.Service_ID
    WHERE c.Comp_ID = @CompID
      AND (s.IsDelete = 0 OR s.IsDelete IS NULL);

END
GO
