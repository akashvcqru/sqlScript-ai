SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:        AI Assistant (Antigravity)
-- Create date:   2026-04-14
-- Update date:   2026-04-16
-- Description:   Unified logic for BL registration and code check, 
--                including loyalty record insertions (M_Consumer_M_Code, 
--                BuiltLoyaltyMCodeCheck, BLoyaltyPointsEarned).
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
    DECLARE @M_Codeid BIGINT = 0;
    DECLARE @Pro_ID VARCHAR(50) = NULL;
    DECLARE @MConsumerMCodeid BIGINT = 0;
    DECLARE @SST_ID INT = 0;

    -- Normalize mobile number (last 10 digits)
    SET @CleanMobile = RIGHT(@MobileNo, 10);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Identify Existing Consumer
        SELECT TOP 1 @M_Consumerid = M_Consumerid 
        FROM M_Consumer 
        WHERE RIGHT(MobileNo, 10) = @CleanMobile AND IsDelete = 0
        ORDER BY M_Consumerid DESC;

        -- 2. Registration / Update Logic
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
            -- UPDATE EXISTING USER
            UPDATE M_Consumer
            SET 
                ConsumerName = CASE WHEN ISNULL(ConsumerName, '') = '' AND @ConsumerName IS NOT NULL THEN @ConsumerName ELSE ConsumerName END,
                Email = CASE WHEN ISNULL(Email, '') = '' AND @Email IS NOT NULL THEN @Email ELSE Email END,
                City = CASE WHEN ISNULL(City, '') = '' AND @City IS NOT NULL THEN @City ELSE City END,
                [state] = CASE WHEN ISNULL([state], '') = '' AND @State IS NOT NULL THEN @State ELSE [state] END,
                PinCode = CASE WHEN ISNULL(PinCode, '') = '' AND @PinCode IS NOT NULL THEN @PinCode ELSE PinCode END,
                [Address] = CASE WHEN ISNULL([Address], '') = '' AND @Address IS NOT NULL THEN @Address ELSE [Address] END,
                UPIId = CASE WHEN ISNULL(UPIId, '') = '' AND @UPI IS NOT NULL THEN @UPI ELSE UPIId END,
                Other_Role = CASE WHEN ISNULL(Other_Role, '') = '' AND @Other_Role IS NOT NULL THEN @Other_Role ELSE Other_Role END
            WHERE M_Consumerid = @M_Consumerid;
            
            SET @Message = 'Details updated.';
        END

        -- 3. Vendor Wise KYC status
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

        -- 5. Code Check & Loyalty Logic
        IF @Code1 IS NOT NULL AND @Code1 <> '' AND @Code2 IS NOT NULL AND @Code2 <> ''
        BEGIN
            -- Identify Code and Product
            SELECT @M_Codeid = Row_ID, @Pro_ID = Pro_ID FROM M_Code WHERE Code1 = @Code1 AND Code2 = @Code2;

            IF @M_Codeid = 0 OR @M_Codeid IS NULL
            BEGIN
                -- Try M_Code_PFL for specific ranges if needed
                SELECT @M_Codeid = Row_ID, @Pro_ID = Pro_ID FROM M_Code_PFL WHERE Code1 = @Code1 AND Code2 = @Code2;
            END

            IF @M_Codeid > 0
            BEGIN
                -- Check if already scanned
                DECLARE @ExistingEnqCount INT;
                SELECT @ExistingEnqCount = COUNT(*) FROM Pro_Enq WHERE Received_Code1 = @Code1 AND Received_Code2 = @Code2 AND Is_Success = 1;

                IF @ExistingEnqCount = 0 OR @Comp_ID = 'Comp-1693' -- Allow Patanjali re-scans if configured
                BEGIN
                    -- A. Insert Scan History
                    INSERT INTO Pro_Enq (Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, Is_Success, Enq_Date, Comp_ID, Latitude, Longitude, City, State, PinCode)
                    VALUES (@Code1, @Code2, @CleanMobile, 'WEB', @Mode, 1, GETDATE(), @Comp_ID, @Latitude, @Longitude, @City, @State, @PinCode);

                    -- B. Increment Use Count
                    UPDATE M_Code SET Use_Count = ISNULL(Use_Count, 0) + 1 WHERE Row_ID = @M_Codeid;

                    -- C. M_Consumer_M_Code (Mapping record)
                    IF NOT EXISTS (SELECT 1 FROM M_Consumer_M_Code WHERE M_Consumerid = @M_Consumerid AND M_Codeid = @M_Codeid)
                    BEGIN
                        INSERT INTO M_Consumer_M_Code (M_Consumerid, M_Codeid, Pro_id, CreatedDate, Compid)
                        VALUES (@M_Consumerid, @M_Codeid, @Pro_ID, GETDATE(), @Comp_ID);
                        SET @MConsumerMCodeid = SCOPE_IDENTITY();
                    END
                    ELSE
                    BEGIN
                        SELECT @MConsumerMCodeid = M_Consumer_MCodeid FROM M_Consumer_M_Code WHERE M_Consumerid = @M_Consumerid AND M_Codeid = @M_Codeid;
                    END

                    -- D. Loyalty Awarding logic
                    -- Find the SST_ID for loyalty services (SRV1001 or SRV1005)
                    SELECT TOP 1 @SST_ID = sst.SST_Id 
                    FROM M_ServiceSubscriptionTrans sst
                    INNER JOIN M_ServiceSubscription ss ON sst.Subscribe_Id = ss.Subscribe_Id
                    WHERE ss.Pro_ID = @Pro_ID AND ss.IsActive = 1 AND sst.IsActive = 1
                    AND ss.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1023') -- Build Loyalty, Cash, or Warranty-Loyalty
                    ORDER BY sst.SST_Id DESC;

                    IF @SST_ID > 0 AND @MConsumerMCodeid > 0
                    BEGIN
                        -- Insert BuiltLoyaltyMCodeCheck
                        INSERT INTO BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate, IsPointsAssigned)
                        VALUES (@SST_ID, @MConsumerMCodeid, @M_Consumerid, GETDATE(), 1);
                        
                        DECLARE @LoyaltyCheckID BIGINT = SCOPE_IDENTITY();

                        -- Calculate Points/Cash from SST
                        DECLARE @Points INT, @Cash DECIMAL(18,2);
                        SELECT @Points = ISNULL(Points, 0), @Cash = ISNULL(IsCash, 0) FROM M_ServiceSubscriptionTrans WHERE SST_Id = @SST_ID;

                        -- Insert BLoyaltyPointsEarned
                        INSERT INTO BLoyaltyPointsEarned (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, Points, Cash, ServiceName)
                        VALUES (@LoyaltyCheckID, @SST_ID, @M_Consumerid, GETDATE(), @Code1, @Code2, @Comp_ID, @Points, @Cash, 'buildloyalty');
                    END
                END
                ELSE
                BEGIN
                    SET @ResultCode = 2; -- Already Checked
                    SET @Message = 'This code has already been verified.';
                END
            END
            ELSE
            BEGIN
                SET @ResultCode = 0; -- Invalid Code
                SET @Message = 'Invalid code. Please check and try again.';
            END
        END

        COMMIT TRANSACTION;

        SELECT 
            @ResultCode AS ResultCode,
            @Message AS Message,
            @Comp_ID AS Comp_ID,
            @Pro_ID AS Pro_ID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ResultCode = 0;
        SET @Message = 'Error: ' + ERROR_MESSAGE();
        
        SELECT @ResultCode AS ResultCode, @Message AS Message, @Comp_ID AS Comp_ID, @Pro_ID AS Pro_ID;
    END CATCH
END
GO
