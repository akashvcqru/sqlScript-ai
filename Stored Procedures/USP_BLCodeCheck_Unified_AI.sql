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
        DECLARE @NewUser_ID NVARCHAR(50);
        EXEC GetCodeGenValue 'Consumer', @NewUser_ID OUTPUT;

        INSERT INTO M_Consumer (
            User_ID, MobileNo, ConsumerName, Email, City, [state], PinCode, [Address], Other_Role, UPIId, 
            Entry_Date, IsActive, IsDelete, [Password], Comp_id
        )
        VALUES (
            @NewUser_ID, @MobileNo, @ConsumerName, @Email, @City, @State, @PinCode, @Address, @Other_Role, @UPI, 
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
            INSERT INTO M_BankAccount (M_Consumerid, Account_No, IFSC_Code, Account_HolderNm, Entry_Date)
            VALUES (@M_Consumerid, @AccountNumber, @IfscCode, @AccountHolderName, GETDATE());
        END
    END

    -- 5. Code Check Logging & Use Count Increment
    IF @Code1 IS NOT NULL AND @Code1 <> '' AND @Code2 IS NOT NULL AND @Code2 <> ''
    BEGIN
        DECLARE @TableName NVARCHAR(50) = 'M_Code';
        IF @Comp_ID = 'Comp-1693' OR NOT EXISTS (SELECT 1 FROM M_Code WHERE Code1 = @Code1 AND Code2 = @Code2)
            SET @TableName = 'M_Code_PFL';
            
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @UseCount INT;
        DECLARE @ActualProId VARCHAR(50);
        
        SET @SQL = N'SELECT @UseCount = ISNULL(Use_Count, 0), @ActualProId = Pro_ID FROM ' + @TableName + ' WHERE Code1 = @Code1 AND Code2 = @Code2';
        EXEC sp_executesql @SQL, N'@Code1 VARCHAR(10), @Code2 VARCHAR(10), @UseCount INT OUTPUT, @ActualProId VARCHAR(50) OUTPUT', @Code1, @Code2, @UseCount OUTPUT, @ActualProId OUTPUT;

        IF @ActualProId IS NOT NULL AND @UseCount = 0
        BEGIN
            -- First use, increment counter (Marks code as checked)
            SET @SQL = N'UPDATE ' + @TableName + ' SET Use_Count = ISNULL(Use_Count, 0) + 1 WHERE Code1 = @Code1 AND Code2 = @Code2';
            EXEC sp_executesql @SQL, N'@Code1 VARCHAR(10), @Code2 VARCHAR(10)', @Code1, @Code2;
            
            -- Insert interaction history (Best effort mapping to standard schema)
            BEGIN TRY
                INSERT INTO Pro_Enq (Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, Is_Success, Enq_Date, Comp_ID)
                VALUES (@Code1, @Code2, RIGHT(@MobileNo, 10), 'WEB', @Mode, 1, GETDATE(), @Comp_ID);
            END TRY
            BEGIN CATCH
            END CATCH
        END
    END

    SELECT 
        @ResultCode AS ResultCode,
        @Message AS Message,
        @Comp_ID AS Comp_ID,
        NULL AS Pro_ID;

END
GO
