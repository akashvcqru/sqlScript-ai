CREATE OR ALTER PROCEDURE [dbo].[USP_ResetVendorPassword_AI]
    @Email NVARCHAR(255),
    @OTP NVARCHAR(10),
    @NewPassword NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify OTP (VerificationCode) in Tbl_EmailVerification
    IF EXISTS (
        SELECT 1 
        FROM Tbl_EmailVerification 
        WHERE Email = @Email 
          AND VerificationCode = @OTP
          AND ExpiryTime > GETDATE()
    )
    BEGIN
        -- Update Password
        UPDATE Comp_Reg
        SET Password = @NewPassword,
            Update_Flag = 1
        WHERE Comp_Email = @Email;

        -- Invalidate OTP
        UPDATE Tbl_EmailVerification
        SET IsVerified = 1,
            VerifiedAt = GETDATE()
        WHERE Email = @Email AND VerificationCode = @OTP;

        SELECT 1 AS Success, 'Password reset successfully.' AS Message;
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid or expired OTP.' AS Message;
    END
END
GO
