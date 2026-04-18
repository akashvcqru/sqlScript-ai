SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:        AI Assistant (Antigravity)
-- Create date:   2026-04-14
-- Update date:   2026-04-17
-- Description:   Unified logic for BL registration and code check with:
--                - Loyalty record insertions (M_Consumer_M_Code, BuiltLoyaltyMCodeCheck, BLoyaltyPointsEarned)
--                - Phase 2: Referral points logic & Frequency-based loyalty caps
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_BLCodeCheck_Unified_AI]
    @Code1 NUMERIC(5, 0),
    @Code2 NUMERIC(8, 0),
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
    @Mode NVARCHAR(50) = 'Website',
    @ReferralMobileNo NVARCHAR(15) = NULL -- Phase 2: Referrer's mobile for points award
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
    
    -- Phase 2: Referral & Frequency variables
    DECLARE @ReferrerConsumerid INT = NULL;
    DECLARE @FrequencyLimit INT = 0;
    DECLARE @CurrentScanCount INT = 0;
    DECLARE @ReferrerReferralSST_ID INT = 0;
    DECLARE @ServiceID NVARCHAR(50) = NULL;

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

                    -- D. Loyalty Awarding logic with Phase 2 enhancements
                    -- Find the SST_ID for loyalty services (SRV1001 or SRV1005)
                    SELECT TOP 1 @SST_ID = sst.SST_Id, @ServiceID = ss.Service_ID
                    FROM M_ServiceSubscriptionTrans sst
                    INNER JOIN M_ServiceSubscription ss ON sst.Subscribe_Id = ss.Subscribe_Id
                    WHERE ss.Pro_ID = @Pro_ID AND ss.IsActive = 1 AND sst.IsActive = 1
                    AND ss.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1023', 'SRV1029') -- Build Loyalty, Cash, Warranty-Loyalty, or Cashback-UPI
                    ORDER BY sst.SST_Id DESC;

                    IF @SST_ID > 0 AND @MConsumerMCodeid > 0
                    BEGIN
                        -- Phase 2: Check Frequency-Based Loyalty Caps
                        -- Get frequency limit from M_ServiceSubscriptionTrans
                        SELECT @FrequencyLimit = ISNULL([Frequency], 0) 
                        FROM M_ServiceSubscriptionTrans 
                        WHERE SST_Id = @SST_ID;

                        -- If frequency limit is set (>0), check current scan count
                        IF @FrequencyLimit > 0
                        BEGIN
                            -- Count scans in last period (Frequency = days)
                            DECLARE @FrequencyStartDate DATETIME = DATEADD(DAY, -@FrequencyLimit, GETDATE());
                            
                            SELECT @CurrentScanCount = COUNT(1)
                            FROM Pro_Enq pe
                            INNER JOIN M_Code mc ON pe.Received_Code1 = mc.Code1 AND pe.Received_Code2 = mc.Code2
                            INNER JOIN M_ServiceSubscriptionTrans mst ON mc.Pro_ID = (SELECT Pro_ID FROM M_ServiceSubscriptionTrans WHERE SST_Id = @SST_ID)
                            WHERE RIGHT(pe.MobileNo, 10) = @CleanMobile
                            AND pe.Is_Success = 1
                            AND pe.Enq_Date >= @FrequencyStartDate;

                            -- If frequency limit exceeded, block and return error
                            IF @CurrentScanCount >= @FrequencyLimit
                            BEGIN
                                SET @ResultCode = 3; -- Frequency limit exceeded
                                SET @Message = 'You have reached the maximum number of code scans for this service in the specified period. Please try again later.';
                                ROLLBACK TRANSACTION;
                                SELECT @ResultCode AS ResultCode, @Message AS Message, @Comp_ID AS Comp_ID, @Pro_ID AS Pro_ID;
                                RETURN;
                            END
                        END

                        -- Insert BuiltLoyaltyMCodeCheck
                        INSERT INTO BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate, IsPointsAssigned)
                        VALUES (@SST_ID, @MConsumerMCodeid, @M_Consumerid, GETDATE(), 1);
                        
                        DECLARE @LoyaltyCheckID BIGINT = SCOPE_IDENTITY();

                        -- Calculate Points/Cash from SST
                        DECLARE @Points INT, @Cash DECIMAL(18,2);
                        SELECT @Points = ISNULL(Points, 0), @Cash = ISNULL(IsCash, 0) FROM M_ServiceSubscriptionTrans WHERE SST_Id = @SST_ID;

                        -- Insert BLoyaltyPointsEarned for main consumer
                        INSERT INTO BLoyaltyPointsEarned (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, Points, Cash, ServiceName)
                        VALUES (@LoyaltyCheckID, @SST_ID, @M_Consumerid, GETDATE(), @Code1, @Code2, @Comp_ID, @Points, @Cash, 'buildloyalty');

                        -- Phase 2: Referral Points Logic
                        -- If referrer mobile is provided, award referral points to referrer
                        IF @ReferralMobileNo IS NOT NULL AND @ReferralMobileNo <> ''
                        BEGIN
                            -- Find referrer's consumer ID
                            SELECT TOP 1 @ReferrerConsumerid = M_Consumerid 
                            FROM M_Consumer 
                            WHERE RIGHT(MobileNo, 10) = RIGHT(@ReferralMobileNo, 10) AND IsDelete = 0;

                            -- If referrer exists and is different from current consumer
                            IF @ReferrerConsumerid IS NOT NULL AND @ReferrerConsumerid <> @M_Consumerid
                            BEGIN
                                -- Find referral service for same product (SRV1004 or similar)
                                SELECT TOP 1 @ReferrerReferralSST_ID = sst.SST_Id
                                FROM M_ServiceSubscriptionTrans sst
                                INNER JOIN M_ServiceSubscription ss ON sst.Subscribe_Id = ss.Subscribe_Id
                                WHERE ss.Pro_ID = @Pro_ID AND ss.IsActive = 1 AND sst.IsActive = 1
                                AND ss.Service_ID IN ('SRV1004', 'SRV1005') -- Referral or Cash services
                                ORDER BY sst.SST_Id DESC;

                                -- If referral service exists, award points to referrer
                                IF @ReferrerReferralSST_ID > 0
                                BEGIN
                                    DECLARE @ReferralPoints INT, @ReferralCash DECIMAL(18,2);
                                    SELECT @ReferralPoints = ISNULL(Points, 0), @ReferralCash = ISNULL(IsCash, 0) 
                                    FROM M_ServiceSubscriptionTrans WHERE SST_Id = @ReferrerReferralSST_ID;

                                    -- Create BuiltLoyaltyMCodeCheck for referrer
                                    INSERT INTO BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate, IsPointsAssigned)
                                    VALUES (@ReferrerReferralSST_ID, @MConsumerMCodeid, @ReferrerConsumerid, GETDATE(), 1);
                                    
                                    DECLARE @ReferrerLoyaltyCheckID BIGINT = SCOPE_IDENTITY();

                                    -- Insert BLoyaltyPointsEarned for referrer with referral flag
                                    INSERT INTO BLoyaltyPointsEarned (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, Points, Cash, ServiceName, refranceM_Consumerid, isPointsUsedReferral)
                                    VALUES (@ReferrerLoyaltyCheckID, @ReferrerReferralSST_ID, @ReferrerConsumerid, GETDATE(), @Code1, @Code2, @Comp_ID, @ReferralPoints, @ReferralCash, 'referral', @M_Consumerid, 1);
                                END
                            END
                        END
                        
                        -- Phase 3: SRV1029 Cashback Payout Integration
                        IF @ServiceID = 'SRV1029' AND @Cash > 0
                        BEGIN
                            -- 1. Insert into tblUPITransactionDetails
                            INSERT INTO tblUPITransactionDetails (M_Consumerid, MobileNo, Code1, Code2, Amount, Comp_Id, Status, ReqDate)
                            VALUES (@M_Consumerid, @MobileNo, @Code1, @Code2, @Cash, @Comp_ID, 'Pending', GETDATE());

                            -- 2. Update Paytm_balance (Deduct from company pool)
                            IF EXISTS (SELECT 1 FROM Paytm_balance WHERE Comp_ID = @Comp_ID)
                            BEGIN
                                UPDATE Paytm_balance 
                                SET Amount = ISNULL(Amount, 0) - @Cash, 
                                    Updated_date = GETDATE() 
                                WHERE Comp_ID = @Comp_ID;
                            END
                            ELSE
                            BEGIN
                                INSERT INTO Paytm_balance (Comp_ID, Amount, Updated_date)
                                VALUES (@Comp_ID, -@Cash, GETDATE());
                            END

                            -- 3. Update tblCashWalletBalance (Ledger)
                            DECLARE @OldWalletBal DECIMAL(18,2) = 0;
                            SELECT TOP 1 @OldWalletBal = ISNULL(NewBal, 0) 
                            FROM tblCashWalletBalance 
                            WHERE M_Consumerid = @M_Consumerid AND Comp_Id = @Comp_ID 
                            ORDER BY Id DESC;
                            
                            INSERT INTO tblCashWalletBalance (Comp_Id, M_Consumerid, OldBal, NewBal, Amount, Cr_Dr_Type, Updated_date, Remarks, Service_ID)
                            VALUES (@Comp_ID, @M_Consumerid, @OldWalletBal, @OldWalletBal + @Cash, @Cash, 'Credit', GETDATE(), 'Cashback for code ' + CAST(@Code1 AS VARCHAR) + '-' + CAST(@Code2 AS VARCHAR), 'SRV1029');
                        END
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
            @Pro_ID AS Pro_ID,
            @Cash AS Amount,
            @ServiceID AS ServiceID,
            @ConsumerName AS ConsumerName,
            @Email AS ConsumerEmail;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ResultCode = 0;
        SET @Message = 'Error: ' + ERROR_MESSAGE();
        
        SELECT 
            @ResultCode AS ResultCode, 
            @Message AS Message, 
            @Comp_ID AS Comp_ID, 
            @Pro_ID AS Pro_ID,
            0 AS Amount,
            '' AS ServiceID,
            @ConsumerName AS ConsumerName,
            @Email AS ConsumerEmail;
    END CATCH
END
GO
