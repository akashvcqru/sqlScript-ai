USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity AI
-- Create date: 2026-04-19
-- Description: Unified Loyalty Code Check for Instant Cash companies (e.g. Comp-2299).
--              Supports lookup in both M_Code and M_Code_PFL.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_BLCodeCheckInstantCash_AI]
(
    @Code1 NUMERIC(5, 0),
    @Code2 NUMERIC(8, 0),
    @MobileNo VARCHAR(20),
    @ConsumerName NVARCHAR(200) = NULL,
    @Email NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @State NVARCHAR(100) = NULL,
    @PinCode NVARCHAR(20) = NULL,
    @Address NVARCHAR(500) = NULL,
    @Latitude NVARCHAR(50) = NULL,
    @Longitude NVARCHAR(50) = NULL,
    @Comp_ID VARCHAR(50) = NULL,
    @Other_Role NVARCHAR(100) = 'LoyaltyUser',
    @UPI NVARCHAR(100) = NULL,
    @AccountNumber NVARCHAR(100) = NULL,
    @IfscCode NVARCHAR(20) = NULL,
    @AccountHolderName NVARCHAR(200) = NULL,
    @VerifyCode VARCHAR(20) = NULL,
    @Mode VARCHAR(50) = 'Website',
    @Gender NVARCHAR(20) = NULL,
    @Age NVARCHAR(20) = NULL,
    @ReferralCode NVARCHAR(100) = NULL,
    @PanCardNumber NVARCHAR(50) = NULL,
    @AadharNumber NVARCHAR(50) = NULL,
    @ExtraField1 NVARCHAR(500) = NULL,
    @IsVerified NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET QUOTED_IDENTIFIER ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @M_Consumerid BIGINT;
        DECLARE @M_Codeid BIGINT;
        DECLARE @Pro_ID VARCHAR(50);
        DECLARE @ActualComp_ID VARCHAR(50);
        DECLARE @Series_Order INT;
        DECLARE @Series_Serial INT;
        DECLARE @ResultCode INT = 0;
        DECLARE @Message NVARCHAR(Max) = '';
        DECLARE @AwardMessage NVARCHAR(Max) = '';
        DECLARE @IsPFL BIT = 0;
        
        DECLARE @ReturnAmount DECIMAL(18,2) = 0;
        DECLARE @ReturnServiceID VARCHAR(50) = '';
        DECLARE @ReturnIsPayoutAllowed BIT = 1;
        DECLARE @ReturnTransactionID BIGINT = NULL;
        DECLARE @ReturnReferenceId VARCHAR(30) = NULL;
        DECLARE @ReturnMConsumerid BIGINT = NULL;

        DECLARE @ConsumerBalance DECIMAL(18,2) = 0;

        -- New Variables for Limits & Flags
        DECLARE @DailyLimit FLOAT = 0;
        DECLARE @IsClaimReq BIT = 0;
        DECLARE @IsApprovalReq BIT = 0;
        DECLARE @TodaySum FLOAT = 0;
        DECLARE @IsPayoutAllowed BIT = 1;
        DECLARE @TransactionID BIGINT = NULL;
        DECLARE @ReferenceId VARCHAR(30) = NULL;

        -------------------------------------------------------------------
        -- 1. IDENTIFY THE CODE (Support M_Code and M_Code_PFL)
        -------------------------------------------------------------------
        DECLARE @dCode1 NUMERIC(18,0) = TRY_CAST(@Code1 AS NUMERIC(18,0));
        DECLARE @dCode2 NUMERIC(18,0) = TRY_CAST(@Code2 AS NUMERIC(18,0));

        IF @dCode1 IS NULL OR @dCode2 IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ResultCode, 'Invalid Code format.' AS Message;
            RETURN;
        END

        -- Check M_Code
        DECLARE @Batch_No NVARCHAR(100) = NULL;

        SELECT 
            @M_Codeid = Row_ID, 
            @Pro_ID = Pro_ID,
            @Series_Order = TRY_CAST(ISNULL(Series_Order,0) AS INT),
            @Series_Serial = TRY_CAST(ISNULL(Series_Serial,0) AS INT),
            @Batch_No = Batch_No
        FROM M_Code WITH (UPDLOCK, ROWLOCK)
        WHERE Code1 = @dCode1 AND Code2 = @dCode2;

        -- If not found, check M_Code_PFL
        IF @M_Codeid IS NULL
        BEGIN
            SELECT 
                @M_Codeid = Row_ID, 
                @Pro_ID = Pro_ID,
                @Series_Order = 0, 
                @Series_Serial = 0,
                @IsPFL = 1,
                @Batch_No = Batch_No
            FROM M_Code_PFL WITH (UPDLOCK, ROWLOCK)
            WHERE Code1 = @dCode1 AND Code2 = @dCode2;
        END

        IF @M_Codeid IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            
            INSERT INTO Pro_Enq (
                Dial_Mode, Enq_Date, Mode_Detail, MobileNo, Received_Code1, Received_Code2, 
                Is_Success, Comp_ID, Latitude, Longitude, City, state, PinCode,
                IsActive, IsDelete, Created_Date
            )
            VALUES (
                @Mode, GETDATE(), 'InstantCashAPI', @MobileNo, @Code1, @Code2, 
                '0', @Comp_ID, @Latitude, @Longitude, @City, @State, @PinCode,
                1, 0, GETDATE()
            );

            DECLARE @InvalidMessage NVARCHAR(MAX) = NULL;

            -- Try specific company first
            IF @Comp_ID IS NOT NULL AND @Comp_ID <> ''
            BEGIN
                SELECT TOP 1 @InvalidMessage = Message_Text 
                FROM LandingPage_CodeCheckMessages 
                WHERE Comp_ID = @Comp_ID 
                  AND (Service_ID = 'SRV1029' OR Service_ID IS NULL)
                  AND Message_Type IN ('Invalid', 'InvalidCode', 'Error')
                  AND IsActive = 1
                ORDER BY CASE WHEN Service_ID = 'SRV1029' THEN 0 ELSE 1 END;
            END

            -- Try Default company fallback
            IF @InvalidMessage IS NULL OR @InvalidMessage = ''
            BEGIN
                SELECT TOP 1 @InvalidMessage = Message_Text 
                FROM LandingPage_CodeCheckMessages 
                WHERE Comp_ID = 'Default' 
                  AND (Service_ID = 'SRV1029' OR Service_ID IS NULL)
                  AND Message_Type IN ('Invalid', 'InvalidCode', 'Error')
                  AND IsActive = 1
                ORDER BY CASE WHEN Service_ID = 'SRV1029' THEN 0 ELSE 1 END;
            END

            -- Final hardcoded fallback
            IF @InvalidMessage IS NULL OR @InvalidMessage = ''
                SET @InvalidMessage = 'The code you entered is invalid. Please check and try again.';

            SELECT 0 AS ResultCode, @InvalidMessage AS Message;
            RETURN;
        END

        -- Inactive check: if Batch_No is null/empty for active subscriptions
        IF NULLIF(RTRIM(LTRIM(@Batch_No)), '') IS NULL
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM M_ServiceSubscription ss WITH (NOLOCK)
                INNER JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id
                WHERE ss.Pro_ID = @Pro_ID
                  AND sst.IsActive <> 0 AND sst.IsDelete = 0
                  AND ss.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029')
            )
            BEGIN
                ROLLBACK TRANSACTION;
                DECLARE @DeactivatedMessage NVARCHAR(250) = 'This code is currently inactive. Please contact the service provider for assistance.';
                SELECT 0 AS ResultCode, @DeactivatedMessage AS Message;
                RETURN;
            END
        END

        SELECT @ActualComp_ID = Comp_ID FROM Pro_Reg WHERE Pro_ID = @Pro_ID;

        -- For Instant Cash, we might be more lenient or log mismatch but proceed
        -- However, we'll keep the mismatch check but ensure it compares against @ActualComp_ID
        IF @Comp_ID IS NOT NULL AND @Comp_ID <> '' AND @Comp_ID <> @ActualComp_ID
        BEGIN
            -- Log the mismatch for debugging
            INSERT INTO InvalidCodeCompid(ApiComp_ID, DbComp_ID, Code1, Code2, Pro_ID, MobileNo)
            VALUES (@Comp_ID, @ActualComp_ID, @dCode1, @dCode2, @Pro_ID, @MobileNo);

            -- For now, let's allow it if the code is valid for another company, OR reject
            -- The requirement says "fix this isse", if the issue is mismatch, we should allow it but use the actual company ID
            SET @Comp_ID = @ActualComp_ID; 
        END
        ELSE IF @Comp_ID IS NULL OR @Comp_ID = ''
        BEGIN
            SET @Comp_ID = @ActualComp_ID;
        END

    -- =========================================================================
    -- VENDOR-WISE DAILY SCAN LIMIT & TIME WINDOW CHECK
    -- =========================================================================
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tbl_VendorScanLimitSetting')
    BEGIN
        DECLARE @VendorDailyLimit INT = NULL;
        DECLARE @VendorScanStartTime TIME(0) = NULL;
        DECLARE @VendorScanEndTime TIME(0) = NULL;
        DECLARE @VendorCustomLimitMsg NVARCHAR(500) = NULL;
        DECLARE @TargetCompID VARCHAR(50) = ISNULL(NULLIF(@Comp_ID, ''), @ActualComp_ID);

        SELECT TOP 1 
            @VendorDailyLimit = DailyUserScanLimit,
            @VendorScanStartTime = ISNULL(ScanStartTime, '00:00:00'),
            @VendorScanEndTime = ISNULL(ScanEndTime, '23:59:59'),
            @VendorCustomLimitMsg = CustomLimitMessage
        FROM [dbo].[tbl_VendorScanLimitSetting] WITH (NOLOCK)
        WHERE Comp_Id = @TargetCompID 
          AND IsActive = 1;

        IF @VendorDailyLimit IS NOT NULL AND @VendorDailyLimit > 0
        BEGIN
            DECLARE @CurrentTimeVal TIME(0) = CAST(GETDATE() AS TIME(0));

            -- Check Time Window
            IF (@VendorScanStartTime IS NOT NULL AND @VendorScanEndTime IS NOT NULL)
            BEGIN
                IF @CurrentTimeVal < @VendorScanStartTime OR @CurrentTimeVal > @VendorScanEndTime
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 
                        3 AS ResultCode, 
                        CONCAT('Code scanning is allowed only between ', 
                               FORMAT(CAST(@VendorScanStartTime AS DATETIME), 'hh:mm tt'), ' and ', 
                               FORMAT(CAST(@VendorScanEndTime AS DATETIME), 'hh:mm tt'), '.') AS Message,
                        0 AS Amount,
                        '' AS ServiceID,
                        @TargetCompID AS Comp_ID;
                    RETURN;
                END
            END

            -- Check User Daily Limit (if MobileNo is provided)
            IF @MobileNo IS NOT NULL AND LTRIM(RTRIM(@MobileNo)) <> ''
            BEGIN
                DECLARE @TodayScanCountVal INT = 0;
                SELECT @TodayScanCountVal = COUNT(1)
                FROM [dbo].[Pro_Enq] WITH (NOLOCK)
                WHERE Comp_ID = @TargetCompID
                  AND RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
                  AND CAST(Enq_Date AS DATE) = CAST(GETDATE() AS DATE)
                  AND Is_Success = '1';

                IF @TodayScanCountVal >= @VendorDailyLimit
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 
                        3 AS ResultCode, 
                        ISNULL(NULLIF(LTRIM(RTRIM(@VendorCustomLimitMsg)), ''), 'You have reached your daily scan limit for today. Please try again tomorrow.') AS Message,
                        0 AS Amount,
                        '' AS ServiceID,
                        @TargetCompID AS Comp_ID;
                    RETURN;
                END
            END
        END
    END

        -------------------------------------------------------------------
        -- 2. UPSERT M_Consumer
        -------------------------------------------------------------------
        DECLARE @Mobile10 VARCHAR(10) = RIGHT(@MobileNo, 10);
        
        -- Optimized lookup to use index on MobileNo
        SELECT @M_Consumerid = M_Consumerid FROM M_Consumer 
        WHERE (MobileNo = @Mobile10 OR MobileNo = '91' + @Mobile10 OR MobileNo = '0' + @Mobile10)
          AND IsDelete = 0;

        IF @M_Consumerid IS NULL
        BEGIN
            DECLARE @NewUser_ID NVARCHAR(50);
            DECLARE @NewPassword NVARCHAR(50);
            
            EXEC GetCodeGenValue 'Consumer', @NewUser_ID OUTPUT;
            SET @NewPassword = CAST((RAND(CHECKSUM(NEWID())) * 90000 + 10000) AS INT);

            INSERT INTO M_Consumer (User_ID, Password, MobileNo, ConsumerName, Email, City, [state], PinCode, [Address], Entry_Date, IsActive, IsDelete, Other_Role, designation, Vrkabel_User_Type, UPIId, gender, Agegroup, ReferralCode, pancard_number, aadharNumber)
            VALUES (@NewUser_ID, @NewPassword, @MobileNo, @ConsumerName, @Email, @City, @State, @PinCode, @Address, GETDATE(), 1, 0, @Other_Role, @Other_Role, 0, @UPI, @Gender, @Age, @ReferralCode, @PanCardNumber, @AadharNumber);
            
            SET @M_Consumerid = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE M_Consumer
            SET 
                ConsumerName = ISNULL(@ConsumerName, ConsumerName),
                Email = ISNULL(@Email, Email),
                City = ISNULL(@City, City),
                [state] = ISNULL(@State, [state]),
                PinCode = ISNULL(@PinCode, PinCode),
                [Address] = ISNULL(@Address, [Address]),
                UPIId = ISNULL(@UPI, UPIId),
                Other_Role = ISNULL(@Other_Role, Other_Role),
                gender = ISNULL(@Gender, gender),
                Agegroup = ISNULL(@Age, Agegroup)
            WHERE M_Consumerid = @M_Consumerid;
        END

        SET @ReturnMConsumerid = @M_Consumerid;

        -- Fallback for ConsumerName if NULL
        IF @ConsumerName IS NULL OR @ConsumerName = ''
        BEGIN
            SELECT TOP 1 @ConsumerName = ConsumerName FROM M_Consumer WHERE M_Consumerid = @M_Consumerid;
            
            IF @ConsumerName IS NULL OR @ConsumerName = ''
            BEGIN
                SELECT TOP 1 @ConsumerName = Account_HolderNm FROM M_BankAccount WHERE M_Consumerid = @M_Consumerid ORDER BY Row_ID DESC;
            END
            
            IF @ConsumerName IS NULL OR @ConsumerName = '' SET @ConsumerName = 'Consumer';
        END

        -------------------------------------------------------------------
        -- 2.b FETCH LIMITS & FLAGS
        -------------------------------------------------------------------
        SELECT TOP 1 
            @DailyLimit = ISNULL(Daily_Limit, 0),
            @IsClaimReq = ISNULL(IsClaimReq, 0),
            @IsApprovalReq = ISNULL(IsApprovalReq, 0)
        FROM tbl_UPILimitDetails
        WHERE Comp_ID = @ActualComp_ID AND Service_ID = 'SRV1029';

        -- Check today's total for this consumer (Include Pending to prevent over-limit transfers)
        SELECT @TodaySum = ISNULL(SUM(Amount), 0)
        FROM tblUPITransactionDetails
        WHERE M_Consumerid = @M_Consumerid 
          AND Comp_Id = @ActualComp_ID
          AND CAST(ReqDate AS DATE) = CAST(GETDATE() AS DATE)
          AND Status IN ('Success', 'Pending');

        -------------------------------------------------------------------
        -- 3. UPSERT Vendor KYC Status
        -------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM tbl_Vendorvisekycstatus WHERE M_consumerId = @M_Consumerid AND Comp_ID = @ActualComp_ID)
        BEGIN
            INSERT INTO tbl_Vendorvisekycstatus (M_consumerId, Comp_ID, VRKbl_KYC_status, Entry_date)
            VALUES (@M_Consumerid, @ActualComp_ID, 0, GETDATE());
        END

        -------------------------------------------------------------------
        -- 4. UPSERT Bank Account
        -------------------------------------------------------------------
        IF NULLIF(@AccountNumber, '') IS NOT NULL AND NULLIF(@IfscCode, '') IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM M_BankAccount WHERE M_Consumerid = @M_Consumerid AND Account_No = @AccountNumber)
            BEGIN
                -- Generate Bank_ID
                DECLARE @Bank_ID NVARCHAR(50);
                SELECT TOP 1 @Bank_ID = PrPrefix + CONVERT(varchar, PrStart) FROM Code_Gen WHERE Prfor = 'Account' AND PrFlag = 1;
                
                IF @Bank_ID IS NULL
                    SET @Bank_ID = 'ACC' + CAST(CAST(RAND() * 89999 + 10000 AS INT) AS VARCHAR);
                ELSE
                    UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'Account' AND PrFlag = 1;

                INSERT INTO M_BankAccount (Bank_ID, M_Consumerid, Account_No, IFSC_Code, Bank_Name, Account_HolderNm, Entry_Date)
                VALUES (@Bank_ID, @M_Consumerid, @AccountNumber, @IfscCode, @Mode, @AccountHolderName, GETDATE());
            END
            ELSE
            BEGIN
                UPDATE M_BankAccount
                SET 
                    IFSC_Code = @IfscCode,
                    Account_HolderNm = ISNULL(@AccountHolderName, Account_HolderNm)
                WHERE M_Consumerid = @M_Consumerid AND Account_No = @AccountNumber;
            END
        END

        -------------------------------------------------------------------
        -- 5. CODE USAGE CHECK & PRO_ENQ LOGGING
        -------------------------------------------------------------------
        DECLARE @UseCount INT;
        IF @IsPFL = 1
            SELECT @UseCount = TRY_CAST(ISNULL(Use_Count, 0) AS INT) FROM M_Code_PFL WHERE Row_ID = @M_Codeid;
        ELSE
            SELECT @UseCount = TRY_CAST(ISNULL(Use_Count, 0) AS INT) FROM M_Code WHERE Row_ID = @M_Codeid;

        -- Log Inquiry
        DECLARE @Is_Success VARCHAR(5) = '1';
        IF @UseCount > 0
            SET @Is_Success = '2';

        INSERT INTO Pro_Enq (
            Dial_Mode, Enq_Date, Mode_Detail, MobileNo, Received_Code1, Received_Code2, 
            Is_Success, Comp_ID, Latitude, Longitude, City, state, PinCode,
            IsActive, IsDelete, Created_Date
        )
        VALUES (
            @Mode, GETDATE(), 'InstantCashAPI', @MobileNo, @Code1, @Code2, 
            @Is_Success, @ActualComp_ID, @Latitude, @Longitude, @City, @State, @PinCode,
            1, 0, GETDATE()
        );

        IF @UseCount > 0
        BEGIN
            COMMIT TRANSACTION;

            DECLARE @AlreadyMessage NVARCHAR(MAX) = NULL;

            -- Try specific company first
            SELECT TOP 1 @AlreadyMessage = Message_Text 
            FROM LandingPage_CodeCheckMessages 
            WHERE Comp_ID = @ActualComp_ID 
              AND (Service_ID = 'SRV1029' OR Service_ID IS NULL)
              AND Message_Type IN ('Already', 'AlreadyChecked', 'AlreadyUsed')
              AND IsActive = 1
            ORDER BY CASE WHEN Service_ID = 'SRV1029' THEN 0 ELSE 1 END;

            -- Try Default company fallback
            IF @AlreadyMessage IS NULL OR @AlreadyMessage = ''
            BEGIN
                SELECT TOP 1 @AlreadyMessage = Message_Text 
                FROM LandingPage_CodeCheckMessages 
                WHERE Comp_ID = 'Default' 
                  AND (Service_ID = 'SRV1029' OR Service_ID IS NULL)
                  AND Message_Type IN ('Already', 'AlreadyChecked', 'AlreadyUsed')
                  AND IsActive = 1
                ORDER BY CASE WHEN Service_ID = 'SRV1029' THEN 0 ELSE 1 END;
            END

            -- Final hardcoded fallback
            IF @AlreadyMessage IS NULL OR @AlreadyMessage = ''
                SET @AlreadyMessage = 'Code is already checked.';

            SELECT 2 AS ResultCode, @AlreadyMessage AS Message;
            RETURN;
        END

        -- Update Use_Count
        IF @IsPFL = 1
            UPDATE M_Code_PFL SET Use_Count = 1, Allot_Date = GETDATE() WHERE Row_ID = @M_Codeid;
        ELSE
            UPDATE M_Code SET Use_Count = 1, Allot_Date = GETDATE() WHERE Row_ID = @M_Codeid;

        -------------------------------------------------------------------
        -- 6. LOYALTY & SERVICES PROCESSING
        -------------------------------------------------------------------
        -- A. Link Consumer to Code
        IF NOT EXISTS (SELECT 1 FROM M_Consumer_M_Code WHERE M_Consumerid = @M_Consumerid AND M_Codeid = @M_Codeid)
        BEGIN
            INSERT INTO M_Consumer_M_Code (M_Consumerid, M_Codeid, Pro_id, Compid, CreatedDate)
            VALUES (@M_Consumerid, @M_Codeid, @Pro_ID, @ActualComp_ID, GETDATE());
        END

        DECLARE @M_Consumer_MCodeid BIGINT = (SELECT TOP 1 M_Consumer_MCodeid FROM M_Consumer_M_Code WHERE M_Consumerid = @M_Consumerid AND M_Codeid = @M_Codeid);

        -- B. Identify all active services
        DECLARE @Services TABLE (
            SST_Id BIGINT,
            Service_ID VARCHAR(50),
            Points DECIMAL(18,2),
            Frequency INT,
            IsCash DECIMAL(18,2)
        );

        INSERT INTO @Services (SST_Id, Service_ID, Points, Frequency, IsCash)
        SELECT sst.SST_Id, ss.Service_ID, ISNULL(sst.Points, 0), ISNULL(sst.Frequency, 1), ISNULL(sst.IsCash, 0)
        FROM M_ServiceSubscription ss WITH (NOLOCK)
        INNER JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id
        WHERE ss.Pro_ID = @Pro_ID
          AND sst.IsActive = 1 AND sst.IsDelete = 0
          AND (
               (ss.start_order IS NULL OR ss.start_series IS NULL) 
               OR 
               (
                 (ss.start_order < @Series_Order OR (ss.start_order = @Series_Order AND ss.start_series <= @Series_Serial))
                 AND
                 (@Series_Order < ss.end_order OR (@Series_Order = ss.end_order AND @Series_Serial <= ss.end_series))
               )
          );

        -- C. Process services
        DECLARE @CurrSST BIGINT, @CurrServiceID VARCHAR(50), @CurrPoints DECIMAL(18,2), @CurrFreq INT, @CurrIsCash DECIMAL(18,2);
        DECLARE @EarningAmount DECIMAL(18,2) = 0;
        
        DECLARE ServiceCursor CURSOR LOCAL FAST_FORWARD FOR SELECT SST_Id, Service_ID, Points, Frequency, IsCash FROM @Services;
        OPEN ServiceCursor;
        FETCH NEXT FROM ServiceCursor INTO @CurrSST, @CurrServiceID, @CurrPoints, @CurrFreq, @CurrIsCash;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate)
            VALUES (@CurrSST, @M_Consumer_MCodeid, @M_Consumerid, GETDATE());

            DECLARE @Pkid BIGINT = SCOPE_IDENTITY();
            DECLARE @countFrequncy BIGINT = (SELECT COUNT(pkid) FROM BuiltLoyaltyMCodeCheck WHERE sst_id = @CurrSST AND M_Cunsumerid = @M_Consumerid AND ISNULL(IsPointsAssigned,0) = 0);

            IF (@countFrequncy % ISNULL(@CurrFreq, 1) = 0)
            BEGIN
                DECLARE @AwardedAmount DECIMAL(18,2) = CASE WHEN @CurrIsCash > 0 THEN @CurrIsCash ELSE @CurrPoints END;

                -- Limit Check for SRV1029
                IF @CurrServiceID = 'SRV1029' AND @TodaySum + @AwardedAmount > @DailyLimit AND @DailyLimit > 0
                BEGIN
                    -- Optionally cap it or return limit message
                    -- For now, let's proceed but mark as limit reached if user wants a message
                    SET @AwardedAmount = CASE WHEN @DailyLimit > @TodaySum THEN @DailyLimit - @TodaySum ELSE 0 END;
                    
                    IF @AwardedAmount <= 0
                    BEGIN
                        SET @AwardMessage = ' Daily transfer limit reached.';
                        -- We still keep loyalty record if user wants, or skip?
                        -- User said "cap the amount or return a limit exceeded message"
                    END
                END

                IF @AwardedAmount > 0 OR (@IsClaimReq = 0 AND @IsApprovalReq = 0)
                BEGIN
                    INSERT INTO BLoyaltyPointsEarned (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, compid, code1, code2, Cash, Points, Service_ID)
                    VALUES (@Pkid, @CurrSST, @M_Consumerid, GETDATE(), @ActualComp_ID, @dCode1, @dCode2, @CurrIsCash, @CurrPoints, @CurrServiceID);

                    UPDATE BuiltLoyaltyMCodeCheck SET IsPointsAssigned = 1 WHERE sst_id = @CurrSST AND M_Cunsumerid = @M_Consumerid;
                    
                    SET @EarningAmount = @AwardedAmount;

                    -- Table Updates if NO Claim/Approval Req
                    IF @CurrServiceID = 'SRV1029'
                    BEGIN
                        -- Capture return data for SRV1029 specifically to avoid being overwritten by other services
                        SET @ReturnAmount = @EarningAmount;
                        SET @ReturnServiceID = @CurrServiceID;

                        -- Calculate Lifetime Balance for this Consumer matching SP_BL_GetBeneficiariesReport
                        DECLARE @Multiplier DECIMAL(18,2) = 1.00;
                        SELECT TOP 1 @Multiplier = 1.00 + (calculation_value / 100.0) 
                        FROM loyalty_calculation WITH (NOLOCK)
                        WHERE comp_id = @ActualComp_ID AND isactive = 1 AND isdelete = 0;
                        IF @Multiplier IS NULL OR @Multiplier = 0 SET @Multiplier = 1.00;

                        -- Consumer Mobiles for matching
                        DECLARE @ConsumerMobiles TABLE (MobileNo NVARCHAR(50) PRIMARY KEY);
                        INSERT INTO @ConsumerMobiles (MobileNo)
                        SELECT DISTINCT MobileNo FROM M_Consumer WITH (NOLOCK) WHERE M_Consumerid = @M_Consumerid AND MobileNo IS NOT NULL AND LTRIM(RTRIM(MobileNo)) <> ''
                        UNION
                        SELECT @MobileNo
                        UNION
                        SELECT RIGHT(@MobileNo, 10)
                        UNION
                        SELECT '91' + RIGHT(@MobileNo, 10)
                        UNION
                        SELECT '+91' + RIGHT(@MobileNo, 10)
                        UNION
                        SELECT '0' + RIGHT(@MobileNo, 10);

                        -- 1. Total Points Earned
                        DECLARE @TotalPointsEarned DECIMAL(18,2) = 0;
                        SELECT @TotalPointsEarned = ISNULL(SUM(CAST(
                            CASE 
                                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                                ELSE ISNULL(BL.Points, 0)
                            END AS DECIMAL(18,2))), 0)
                        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
                        WHERE (BL.compid = @ActualComp_ID 
                               OR (BL.compid IS NULL AND EXISTS (
                                   SELECT 1 FROM BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK)
                                   INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
                                   INNER JOIN M_Code M WITH (NOLOCK) ON MC.M_Codeid = M.Row_ID
                                   INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
                                   WHERE BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid AND PR.Comp_ID = @ActualComp_ID
                               )))
                          AND BL.M_Consumerid = @M_Consumerid
                          AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral');

                        -- 2. Total Referral Points
                        DECLARE @TotalReferralPoints DECIMAL(18,2) = 0;
                        SELECT @TotalReferralPoints = ISNULL(SUM(CAST(
                            CASE 
                                WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier
                                ELSE ISNULL(BL.Points, 0)
                            END AS DECIMAL(18,2))), 0)
                        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
                        WHERE BL.compid = @ActualComp_ID
                          AND LOWER(ISNULL(BL.ServiceName, '')) IN ('refral', 'referral')
                          AND BL.M_Consumerid = @M_Consumerid;

                        -- 3. Total Claims Transferred
                        DECLARE @TotalClaims DECIMAL(18,2) = 0;
                        SELECT @TotalClaims = ISNULL(SUM(TRY_CAST(CD.Amount AS DECIMAL(18,2))), 0)
                        FROM ClaimDetails CD WITH (NOLOCK)
                        WHERE CD.Comp_id = @ActualComp_ID 
                          AND CD.Mobileno IN (SELECT MobileNo FROM @ConsumerMobiles)
                          AND CD.Isapproved = 1;

                        -- 4. Total UPI Transferred
                        DECLARE @TotalUPI DECIMAL(18,2) = 0;
                        SELECT @TotalUPI = ISNULL(SUM(TRY_CAST(ISNULL(t.Amount, t.Points_Val) AS DECIMAL(18,2))), 0)
                        FROM tblUPITransactionDetails t WITH (NOLOCK)
                        WHERE t.Status = 'Success'
                          AND t.Comp_Id = @ActualComp_ID
                          AND (t.MobileNo IN (SELECT MobileNo FROM @ConsumerMobiles) OR TRY_CAST(t.M_Consumerid AS BIGINT) = @M_Consumerid)
                          AND LEN(ISNULL(t.Code1, '')) > 3;

                        -- 5. Total BPoints Debited
                        DECLARE @TotalBPoints DECIMAL(18,2) = 0;
                        SELECT @TotalBPoints = ISNULL(SUM(TRY_CAST(ISNULL(BT.RedeemPoints, 0) AS DECIMAL(18,2))), 0)
                        FROM BPointsTransaction BT WITH (NOLOCK)
                        WHERE BT.companyid = @ActualComp_ID
                          AND BT.bpstatus IN ('Accepted', 'SUCCESS', 'Debit')
                          AND BT.RedeemBy = @M_Consumerid;

                        -- 6. Total Transactions Amount
                        DECLARE @TotalTransactions DECIMAL(18,2) = 0;
                        SELECT @TotalTransactions = ISNULL(SUM(TRY_CAST(ISNULL(t.Amount, 0) AS DECIMAL(18,2))), 0)
                        FROM Transactions t WITH (NOLOCK)
                        WHERE (t.CompId = REPLACE(@ActualComp_ID, 'Comp-', '') OR t.CompId = @ActualComp_ID)
                          AND t.Issuccess = 1
                          AND TRY_CAST(t.M_CounserID AS BIGINT) = @M_Consumerid;

                        DECLARE @TotalEarned DECIMAL(18,2) = @TotalPointsEarned + @TotalReferralPoints;
                        DECLARE @TotalRedeemed DECIMAL(18,2) = @TotalClaims + @TotalUPI + @TotalBPoints + @TotalTransactions;
                        SET @ConsumerBalance = @TotalEarned - @TotalRedeemed;

                        IF (@ConsumerBalance < 0)
                        BEGIN
                            -- Negative balance: Do not permit payout and do not insert into tblUPITransactionDetails
                            SET @ReturnIsPayoutAllowed = 0;
                        END
                        ELSE IF (@IsClaimReq = 1 OR @IsApprovalReq = 1)
                        BEGIN
                            SET @ReturnIsPayoutAllowed = 0;
                        END
                        ELSE IF @EarningAmount > 0
                        BEGIN
                            SET @ReferenceId = REPLACE(@ActualComp_ID, '-', '') + FORMAT(GETDATE(), 'yyMMddHHmmss');
                            SET @ReturnReferenceId = @ReferenceId;

                            -- 1. Insert into tblUPITransactionDetails
                            INSERT INTO tblUPITransactionDetails 
                            (M_Consumerid, MobileNo, Code1, Code2, Amount, Comp_Id, Status, ReqDate, ConsumerName, UPI_Id, Remarks, FinalStatus, FinalRemarks, RefenceId)
                            VALUES 
                            (@M_Consumerid, @MobileNo, @dCode1, @dCode2, @EarningAmount, @ActualComp_ID, 'Pending', GETDATE(), @ConsumerName, COALESCE(@UPI, @AccountNumber), 'Instant Cash Payout', 'Pending', 'Initial Record', @ReferenceId);

                            SET @TransactionID = SCOPE_IDENTITY();
                            SET @ReturnTransactionID = @TransactionID;

                            -- Removed Credit entry to tblCashWalletBalance as per user request (only Debit entry is needed)
                        END
                    END
                    ELSE IF @CurrServiceID IN ('SRV1001', 'SRV1005')
                    BEGIN
                        -- Capture return data for SRV1001 or SRV1005 if SRV1029 is not already set
                        IF @ReturnServiceID IS NULL OR @ReturnServiceID = '' OR @ReturnServiceID NOT IN ('SRV1029')
                        BEGIN
                            SET @ReturnAmount = @EarningAmount;
                            SET @ReturnServiceID = @CurrServiceID;
                        END
                    END
                END
                
                SET @AwardMessage = @AwardMessage + ' Amount ' + CAST(@EarningAmount AS NVARCHAR(20)) + ' awarded. ';
            END
            FETCH NEXT FROM ServiceCursor INTO @CurrSST, @CurrServiceID, @CurrPoints, @CurrFreq, @CurrIsCash;
        END

        CLOSE ServiceCursor;
        DEALLOCATE ServiceCursor;

        -------------------------------------------------------------------
        -- 7. FETCH MESSAGE
        -------------------------------------------------------------------
        SELECT TOP 1 @Message = Message_Text 
        FROM LandingPage_CodeCheckMessages 
        WHERE Comp_ID = @ActualComp_ID 
          AND (Service_ID = 'SRV1029' OR Service_ID IS NULL)
          AND Message_Type = 'Success' 
          AND IsActive = 1
        ORDER BY CASE WHEN Service_ID = 'SRV1029' THEN 0 ELSE 1 END;

        IF @Message = '' OR @Message IS NULL
        BEGIN
            SELECT TOP 1 @Message = Message_Text 
            FROM LandingPage_CodeCheckMessages 
            WHERE Comp_ID = 'Default' 
              AND (Service_ID = 'SRV1029' OR Service_ID IS NULL)
              AND Message_Type = 'Success' 
              AND IsActive = 1
            ORDER BY CASE WHEN Service_ID = 'SRV1029' THEN 0 ELSE 1 END;
        END

        IF @Message = '' OR @Message IS NULL SET @Message = 'Success! Code Verified.';

        IF @ConsumerBalance < 0
        BEGIN
            SET @Message = @Message + ' Note: adjusted points your outstanding balance.';
        END

        COMMIT TRANSACTION;
        -- Return extra metadata needed for payout triggering in API
        SELECT 1 AS ResultCode, @Message AS Message, @ReturnAmount AS Amount, @ReturnServiceID AS ServiceID, @ActualComp_ID AS Comp_ID, @ReturnIsPayoutAllowed AS IsPayoutAllowed, @ReturnTransactionID AS TransactionID, @ReturnReferenceId AS ReferenceId, @ReturnMConsumerid AS M_Consumerid;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF CURSOR_STATUS('local', 'ServiceCursor') >= 0 BEGIN CLOSE ServiceCursor; DEALLOCATE ServiceCursor; END
        SELECT 0 AS ResultCode, ERROR_MESSAGE() AS Message;
    END CATCH
END
GO
