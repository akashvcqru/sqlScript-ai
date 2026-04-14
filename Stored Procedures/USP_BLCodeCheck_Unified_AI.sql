SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:        AI Assistant (Antigravity)
-- Create date:   2026-04-14
-- Description:   Unified logic for BL registration and code check, 
--                aligning with legacy MasterHandler.ashx verifyotp logic.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_BLCodeCheck_Unified_AI]
    @Code1 VARCHAR(10),
    @Code2 VARCHAR(10),
    @MobileNo VARCHAR(15),
    @ConsumerName NVARCHAR(200) = NULL,
    @Email NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @State NVARCHAR(100) = NULL,
    @PinCode NVARCHAR(10) = NULL,
    @Address NVARCHAR(MAX) = NULL,
    @Latitude NVARCHAR(50) = NULL,
    @Longitude NVARCHAR(50) = NULL,
    @Comp_ID NVARCHAR(50) = NULL,
    @Other_Role NVARCHAR(50) = NULL,
    @UPI NVARCHAR(100) = NULL,
    @AccountNumber NVARCHAR(50) = NULL,
    @IfscCode NVARCHAR(20) = NULL,
    @AccountHolderName NVARCHAR(200) = NULL,
    @VerifyCode NVARCHAR(10) = NULL, -- OTP (Pass empty for loyalty check bypassing OTP)
    @Mode NVARCHAR(50) = 'Website'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @M_Consumerid INT;
    DECLARE @ResultCode INT = 1;
    DECLARE @Message NVARCHAR(MAX) = '';
    DECLARE @CleanMobile VARCHAR(10);

    -- Normalize mobile number (last 10 digits)
    SET @CleanMobile = RIGHT(@MobileNo, 10);

    -- 1. Identify Existing Consumer
    SELECT TOP 1 @M_Consumerid = M_Consumerid 
    FROM M_Consumer 
    WHERE RIGHT(MobileNo, 10) = @CleanMobile AND IsDelete = 0
    ORDER BY M_Consumerid DESC;

    -- 2. Registration / Update Logic (Aligning with MasterHandler.ashx: chkgenuenity)
    IF @M_Consumerid IS NULL
    BEGIN
        -- REGISTER NEW USER
        INSERT INTO M_Consumer (
            MobileNo, ConsumerName, Email, City, [state], PinCode, [Address], Other_Role, UPIId, 
            Entry_Date, IsActive, IsDelete, [Password], Comp_id
        )
        VALUES (
            @MobileNo, @ConsumerName, @Email, @City, @State, @PinCode, @Address, @Other_Role, @UPI, 
            GETDATE(), 1, 0, CAST(FLOOR(RAND() * 90000 + 10000) AS VARCHAR(5)), @Comp_ID
        );
        
        SET @M_Consumerid = SCOPE_IDENTITY();
        SET @Message = 'Registration successful.';
    END
    ELSE
    BEGIN
        -- UPDATE EXISTING USER (Only if fields are NULL or Empty - Aligning with legacy "update if null")
        UPDATE M_Consumer
        SET 
            ConsumerName = CASE WHEN ISNULL(ConsumerName, '') = '' THEN @ConsumerName ELSE ConsumerName END,
            Email = CASE WHEN ISNULL(Email, '') = '' THEN @Email ELSE Email END,
            City = CASE WHEN ISNULL(City, '') = '' THEN @City ELSE City END,
            [state] = CASE WHEN ISNULL([state], '') = '' THEN @State ELSE [state] END,
            PinCode = CASE WHEN ISNULL(PinCode, '') = '' THEN @PinCode ELSE PinCode END,
            [Address] = CASE WHEN ISNULL([Address], '') = '' THEN @Address ELSE [Address] END,
            UPIId = CASE WHEN ISNULL(UPIId, '') = '' THEN @UPI ELSE UPIId END,
            Other_Role = CASE WHEN ISNULL(Other_Role, '') = '' THEN @Other_Role ELSE Other_Role END
        WHERE M_Consumerid = @M_Consumerid;
        
        SET @Message = 'Details updated.';
    END

    -- 3. Vendor Wise KYC status (tbl_Vendorvisekycstatus) - Avoiding duplicates per Comp_ID
    IF @Comp_ID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM tbl_Vendorvisekycstatus WHERE Comp_id = @Comp_ID AND M_Consumerid = @M_Consumerid)
    BEGIN
        INSERT INTO tbl_Vendorvisekycstatus (Comp_id, M_Consumerid, VRKbl_KYC_status, Entry_date)
        VALUES (@Comp_ID, @M_Consumerid, '0', GETDATE());
    END

    -- 4. Bank Account Logic
    IF (@AccountNumber IS NOT NULL AND @AccountNumber <> '') OR (@IfscCode IS NOT NULL AND @IfscCode <> '')
    BEGIN
        IF EXISTS (SELECT 1 FROM M_BankAccount WHERE M_Consumerid = @M_Consumerid)
        BEGIN
            UPDATE M_BankAccount
            SET 
                Account_No = CASE WHEN ISNULL(Account_No, '') = '' THEN @AccountNumber ELSE Account_No END,
                IFSC_Code = CASE WHEN ISNULL(IFSC_Code, '') = '' THEN @IfscCode ELSE IFSC_Code END,
                Account_HolderNm = CASE WHEN ISNULL(Account_HolderNm, '') = '' THEN @AccountHolderName ELSE Account_HolderNm END,
                Entry_Date = GETDATE()
            WHERE M_Consumerid = @M_Consumerid;
        END
        ELSE
        BEGIN
            INSERT INTO M_BankAccount (M_Consumerid, Account_No, IFSC_Code, Account_HolderNm, Entry_Date, IsDelete)
            VALUES (@M_Consumerid, @AccountNumber, @IfscCode, @AccountHolderName, GETDATE(), 0);
        END
    END

    -- Final Step: Product Code Verification
    -- We capture the results from USP_VerifyProductCode_AI to return them with correct column names
    DECLARE @VerificationResults TABLE (
        ProductName NVARCHAR(200),
        CompanyName NVARCHAR(200),
        CompId NVARCHAR(50),
        ProId NVARCHAR(50),
        ProductImage NVARCHAR(MAX),
        Message NVARCHAR(MAX),
        IsValid INT
    );

    INSERT INTO @VerificationResults (ProductName, CompanyName, CompId, ProId, ProductImage, Message, IsValid)
    EXEC USP_VerifyProductCode_AI @Code1 = @Code1, @Code2 = @Code2, @Latitude = @Latitude, @Longitude = @Longitude, @Comp_Id = @Comp_ID;

    SELECT 
        ProductName, 
        CompanyName, 
        CompId, 
        ProId, 
        ProductImage, 
        Message, 
        IsValid AS ResultCode
    FROM @VerificationResults;

END
GO
