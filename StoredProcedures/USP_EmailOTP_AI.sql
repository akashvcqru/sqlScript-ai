CREATE OR ALTER PROCEDURE [dbo].[USP_GenerateEmailOTP_AI]
    @Email NVARCHAR(255),
    @OTP NVARCHAR(10) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate a random 6-digit OTP
    SET @OTP = RIGHT('000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS NVARCHAR(6)), 6);

    -- Update existing record or insert new one
    IF EXISTS (SELECT 1 FROM Tbl_EmailVerification WHERE Email = @Email)
    BEGIN
        UPDATE Tbl_EmailVerification
        SET VerificationCode = @OTP,
            VerificationToken = CAST(NEWID() AS NVARCHAR(100)),
            ExpiryTime = DATEADD(MINUTE, 10, GETDATE()),
            IsVerified = 0,
            CreatedAt = GETDATE(),
            VerifiedAt = NULL
        WHERE Email = @Email;
    END
    ELSE
    BEGIN
        INSERT INTO Tbl_EmailVerification (Email, VerificationCode, VerificationToken, ExpiryTime, IsVerified, CreatedAt)
        VALUES (@Email, @OTP, CAST(NEWID() AS NVARCHAR(100)), DATEADD(MINUTE, 10, GETDATE()), 0, GETDATE());
    END

    SELECT @OTP AS GeneratedOTP;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_VerifyEmailOTP_AI]
    @Email NVARCHAR(255),
    @OTP NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM Tbl_EmailVerification 
        WHERE Email = @Email 
          AND VerificationCode = @OTP 
          AND IsVerified = 0 
          AND ExpiryTime > GETDATE()
    )
    BEGIN
        UPDATE Tbl_EmailVerification
        SET IsVerified = 1,
            VerifiedAt = GETDATE()
        WHERE Email = @Email AND VerificationCode = @OTP;

        -- Also update Comp_Reg if the record already exists
        UPDATE Comp_Reg 
        SET Email_Vari_Flag = 1,
            Status = 1
        WHERE Comp_Email = @Email;

        SELECT 1 AS Success, 'OTP verified successfully.' AS Message;
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid or expired OTP.' AS Message;
    END
END
GO
