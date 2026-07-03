CREATE OR ALTER PROCEDURE [dbo].[USP_VerifyMobileOTP_AI]
    @MobileNumber VARCHAR(15),
    @OTP NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM Tbl_MobileVerification 
        WHERE MobileNumber = @MobileNumber 
          AND VerificationCode = @OTP 
          AND IsVerified = 0 
          AND ExpiryTime > GETDATE()
    )
    BEGIN
        UPDATE Tbl_MobileVerification
        SET IsVerified = 1,
            VerifiedAt = GETDATE()
        WHERE MobileNumber = @MobileNumber AND VerificationCode = @OTP;

        -- Also update Comp_Reg if the record already exists
        UPDATE Comp_Reg 
        SET Mobile_Vari_Flag = 1,
            Status = 1
        WHERE Mobile_No = @MobileNumber;

        SELECT 1 AS Success, 'OTP verified successfully.' AS Message;
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid or expired OTP.' AS Message;
    END
END
GO
