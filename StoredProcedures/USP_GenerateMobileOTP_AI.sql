CREATE OR ALTER PROCEDURE [dbo].[USP_GenerateMobileOTP_AI]
    @MobileNumber VARCHAR(15),
    @OTP NVARCHAR(10) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate a random 6-digit OTP
    SET @OTP = RIGHT('000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS NVARCHAR(6)), 6);

    -- Update existing record or insert new one
    IF EXISTS (SELECT 1 FROM Tbl_MobileVerification WHERE MobileNumber = @MobileNumber)
    BEGIN
        UPDATE Tbl_MobileVerification
        SET VerificationCode = @OTP,
            ExpiryTime = DATEADD(MINUTE, 10, GETDATE()),
            IsVerified = 0,
            VerifiedAt = NULL
        WHERE MobileNumber = @MobileNumber;
    END
    ELSE
    BEGIN
        INSERT INTO Tbl_MobileVerification (MobileNumber, VerificationCode, ExpiryTime, IsVerified)
        VALUES (@MobileNumber, @OTP, DATEADD(MINUTE, 10, GETDATE()), 0);
    END

    SELECT @OTP AS GeneratedOTP;
END
GO
