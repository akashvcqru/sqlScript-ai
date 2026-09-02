SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_ACCodeCheck_Unified_AI]
    @Code1 NVARCHAR(10),
    @Code2 NVARCHAR(15),
    @MobileNo NVARCHAR(20) = NULL,
    @ConsumerName NVARCHAR(150) = NULL,
    @Email NVARCHAR(150) = NULL,
    @City NVARCHAR(50) = NULL,
    @State NVARCHAR(50) = NULL,
    @PinCode NVARCHAR(10) = NULL,
    @Lat NVARCHAR(50) = NULL,
    @Long NVARCHAR(50) = NULL,
    @Comp_ID NVARCHAR(20) = NULL,
    @Role_Id INT = NULL,
    @Mode NVARCHAR(50) = 'Web'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResultCode INT = 1; -- 1: Success, 0: Invalid, 2: Already Used, 3: Error
    DECLARE @Message NVARCHAR(MAX) = '';
    DECLARE @RowID NUMERIC(12, 0);
    DECLARE @UseCount NUMERIC(5, 0);
    DECLARE @M_ConsumerID INT;
    DECLARE @CurrentCompID NVARCHAR(20);
    DECLARE @IsSuccess NVARCHAR(50) = '1';
    DECLARE @ProID VARCHAR(50);
    DECLARE @Batch_No NVARCHAR(100) = NULL;

    -- 1. Normalize Mobile (add 91 if 10 digits)
    IF @MobileNo IS NOT NULL AND LEN(@MobileNo) = 10
    BEGIN
        SET @MobileNo = '91' + @MobileNo;
    END

    -- 2. Validate Code
    SELECT TOP 1 
        @RowID = mc.Row_ID, 
        @UseCount = mc.Use_Count, 
        @CurrentCompID = pr.Comp_ID,
        @ProID = mc.Pro_ID,
        @Batch_No = mc.Batch_No
    FROM M_Code mc
    INNER JOIN Pro_Reg pr ON mc.Pro_ID = pr.Pro_ID
    WHERE mc.Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND mc.Code2 = CAST(@Code2 AS NUMERIC(8,0));

    -- Fallback to M_Code_PFL if not found in M_Code (e.g. for Patanjali)
    IF @RowID IS NULL
    BEGIN
        SELECT TOP 1 
            @RowID = mc.Row_ID, 
            @UseCount = mc.Use_Count, 
            @CurrentCompID = pr.Comp_ID,
            @ProID = mc.Pro_ID,
            @Batch_No = mc.Batch_No
        FROM M_Code_PFL mc
        INNER JOIN Pro_Reg pr ON mc.Pro_ID = pr.Pro_ID
        WHERE mc.Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND mc.Code2 = CAST(@Code2 AS NUMERIC(8,0));
    END

    IF @RowID IS NULL
    BEGIN
        SET @ResultCode = 0;
        SET @Message = 'Invalid Code. Please check the 13-digit code and try again.';
        SELECT @ResultCode AS ResultCode, @Message AS [Message];
        RETURN;
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
        DECLARE @CheckCompID NVARCHAR(50) = ISNULL(@Comp_ID, @CurrentCompID);

        SELECT TOP 1 
            @VendorDailyLimit = DailyUserScanLimit,
            @VendorScanStartTime = ISNULL(ScanStartTime, '00:00:00'),
            @VendorScanEndTime = ISNULL(ScanEndTime, '23:59:59'),
            @VendorCustomLimitMsg = CustomLimitMessage
        FROM [dbo].[tbl_VendorScanLimitSetting] WITH (NOLOCK)
        WHERE Comp_Id = @CheckCompID 
          AND IsActive = 1;

        IF @VendorDailyLimit IS NOT NULL AND @VendorDailyLimit > 0
        BEGIN
            DECLARE @CurrentTimeVal TIME(0) = CAST(GETDATE() AS TIME(0));

            -- Check Time Window
            IF (@VendorScanStartTime IS NOT NULL AND @VendorScanEndTime IS NOT NULL)
            BEGIN
                IF @CurrentTimeVal < @VendorScanStartTime OR @CurrentTimeVal > @VendorScanEndTime
                BEGIN
                    SELECT 
                        3 AS ResultCode, 
                        CONCAT('Code scanning is allowed only between ', 
                               FORMAT(CAST(@VendorScanStartTime AS DATETIME), 'hh:mm tt'), ' and ', 
                               FORMAT(CAST(@VendorScanEndTime AS DATETIME), 'hh:mm tt'), '.') AS [Message],
                        @CheckCompID AS Comp_ID;
                    RETURN;
                END
            END

            -- Check User Daily Limit (if MobileNo is provided)
            IF @MobileNo IS NOT NULL AND LTRIM(RTRIM(@MobileNo)) <> ''
            BEGIN
                DECLARE @TodayScanCountVal INT = 0;
                SELECT @TodayScanCountVal = COUNT(1)
                FROM [dbo].[Pro_Enq] WITH (NOLOCK)
                WHERE Comp_ID = @CheckCompID
                  AND RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
                  AND CAST(Enq_Date AS DATE) = CAST(GETDATE() AS DATE);

                IF @TodayScanCountVal >= @VendorDailyLimit
                BEGIN
                    SELECT 
                        3 AS ResultCode, 
                        ISNULL(NULLIF(LTRIM(RTRIM(@VendorCustomLimitMsg)), ''), 'You have reached your daily scan limit for today. Please try again tomorrow.') AS [Message],
                        @CheckCompID AS Comp_ID;
                    RETURN;
                END
            END
        END
    END

    -- Check Service Subscription
    IF NOT EXISTS (SELECT 1 FROM M_ServiceSubscription WHERE Pro_ID = @ProID)
    BEGIN
        SET @ResultCode = 0;
        SET @Message = 'This code is currently not linked to any service. Please contact customer support for assistance.';
        SELECT @ResultCode AS ResultCode, @Message AS [Message], @CurrentCompID AS Comp_ID;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM M_ServiceSubscription WHERE Pro_ID = @ProID AND IsActive = 1)
    BEGIN
        SET @ResultCode = 0;
        SET @Message = 'The code is deactivate';
        SELECT @ResultCode AS ResultCode, @Message AS [Message], @CurrentCompID AS Comp_ID;
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1 
        FROM M_ServiceSubscription ms
        INNER JOIN M_ServiceSubscriptionTrans mst ON ms.Subscribe_Id = mst.Subscribe_Id
        WHERE ms.Pro_ID = @ProID AND ms.IsActive = 1 AND mst.IsActive = 1
    )
    BEGIN
        SET @ResultCode = 0;
        SET @Message = 'The code is deactivate';
        SELECT @ResultCode AS ResultCode, @Message AS [Message], @CurrentCompID AS Comp_ID;
        RETURN;
    END

    -- Check if Batch_No is null or empty for active subscriptions
    IF NULLIF(RTRIM(LTRIM(@Batch_No)), '') IS NULL
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM M_ServiceSubscription ms WITH (NOLOCK)
            INNER JOIN M_ServiceSubscriptionTrans mst WITH (NOLOCK) ON ms.Subscribe_Id = mst.Subscribe_Id
            WHERE ms.Pro_ID = @ProID AND ms.IsActive = 1 AND mst.IsActive = 1 AND mst.IsDelete = 0
              AND ms.Service_ID IN ('SRV1018', 'SRV1001', 'SRV1005', 'SRV1029')
        )
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'This code is currently inactive. Please contact the service provider for assistance.';
            SELECT @ResultCode AS ResultCode, @Message AS [Message], @CurrentCompID AS Comp_ID;
            RETURN;
        END
    END

    -- 3. Check if already used based on Frequency limit
    DECLARE @Frequency INT = 1;
    SELECT TOP 1 @Frequency = ISNULL(mst.Frequency, 1)
    FROM M_ServiceSubscription ms WITH (NOLOCK)
    INNER JOIN M_ServiceSubscriptionTrans mst WITH (NOLOCK) ON ms.Subscribe_Id = mst.Subscribe_Id
    WHERE ms.Pro_ID = @ProID AND ms.IsActive = 1 AND mst.IsActive = 1 AND mst.Frequency IS NOT NULL AND mst.Frequency > 0
    ORDER BY mst.SST_Id DESC;

    IF ISNULL(@UseCount, 0) >= @Frequency
    BEGIN
        SET @ResultCode = 2;
        -- Message will be overridden by individualized message if available
        SET @Message = 'This code has already been verified.';
        SET @IsSuccess = '2'; -- Mark as duplicate in Pro_Enq
    END

    -- 4. If MobileNo is provided, perform registration/verification
    IF @MobileNo IS NOT NULL AND (@ResultCode = 1 OR @ResultCode = 2)
    BEGIN
        BEGIN TRY
            -- Find or Create Consumer
            SELECT @M_ConsumerID = M_Consumerid FROM M_Consumer WHERE MobileNo = @MobileNo;

            IF @M_ConsumerID IS NULL
            BEGIN
                SELECT @M_ConsumerID = M_Consumerid FROM M_Consumer WHERE right(MobileNo, 10) = right(@MobileNo, 10);
            END

            -- Identify Company ID
            DECLARE @LogCompID NVARCHAR(50) = ISNULL(@Comp_ID, @CurrentCompID);

            IF @M_ConsumerID IS NULL
            BEGIN
                DECLARE @GeneratedUserID NVARCHAR(50);
                EXEC GetCodeGenValue 'Consumer', @GeneratedUserID OUTPUT;

                -- Generate 5-digit Password
                DECLARE @RandomPassword NVARCHAR(5) = RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR(5)), 5);

                INSERT INTO M_Consumer (User_ID, ConsumerName, Email, MobileNo, City, state, PinCode, Entry_Date, IsActive, IsDelete, Role_Id, Password, Comp_id)
                VALUES (@GeneratedUserID, ISNULL(@ConsumerName, 'Consumer'), @Email, @MobileNo, @City, @State, @PinCode, GETDATE(), 1, 0, @Role_Id, @RandomPassword, @LogCompID);
                
                SET @M_ConsumerID = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                -- Update existing consumer if details provided
                UPDATE M_Consumer 
                SET ConsumerName = ISNULL(@ConsumerName, ConsumerName),
                    Email = ISNULL(@Email, Email),
                    City = ISNULL(@City, City),
                    state = ISNULL(@State, state),
                    PinCode = ISNULL(@PinCode, PinCode),
                    Comp_id = ISNULL(Comp_id, @LogCompID),
                    Role_Id = ISNULL(@Role_Id, Role_Id)
                WHERE M_Consumerid = @M_ConsumerID;
            END

            -- Handle Vendor KYC Status (tbl_Vendorvisekycstatus)
            IF NOT EXISTS (SELECT 1 FROM tbl_Vendorvisekycstatus WHERE M_consumerId = @M_ConsumerID AND Comp_id = @LogCompID)
            BEGIN
                INSERT INTO tbl_Vendorvisekycstatus (
                    M_consumerId, Comp_id, Name, MobileNo, EmailId, UserCity, UserState, UserPin, VRKbl_KYC_status, Entry_date
                )
                VALUES (
                    @M_ConsumerID, @LogCompID, ISNULL(@ConsumerName, 'Consumer'), @MobileNo, @Email, @City, @State, @PinCode, 0, GETDATE()
                );
            END

            -- Log Inquiry in Pro_Enq
            -- Ensure we use the company ID passed in or the one from the code registry

            INSERT INTO Pro_Enq (
                Dial_Mode, Enq_Date, Mode_Detail, MobileNo, Received_Code1, Received_Code2, 
                Is_Success, City, state, PinCode, Latitude, Longitude, 
                IsActive, IsDelete, Comp_ID, Created_Date
            )
            VALUES (
                @Mode, GETDATE(), 'Unified API', @MobileNo, @Code1, @Code2, 
                @IsSuccess, @City, @State, @PinCode, @Lat, @Long, 
                1, 0, @LogCompID, GETDATE()
            );

            -- Mark code as used ONLY if this is the first successful check
            IF @ResultCode = 1
            BEGIN
                UPDATE M_Code SET Use_Count = ISNULL(Use_Count, 0) + 1, Allot_Date = GETDATE() WHERE Row_ID = @RowID;
                -- Update PFL as well if that's where we found it
                UPDATE M_Code_PFL SET Use_Count = ISNULL(Use_Count, 0) + 1, Allot_Date = GETDATE() WHERE Row_ID = @RowID;
                
                SET @Message = 'Success! Your product has been verified successfully.';
            END
        END TRY
        BEGIN CATCH
            -- In case of error, we still want to return a response
            SET @ResultCode = 3;
            SET @Message = 'Internal Error: ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE IF @MobileNo IS NULL AND @ResultCode = 1
    BEGIN
        -- Just a check call (like chkwarranty)
        SET @ResultCode = 1;
        SET @Message = 'Code is valid and ready for verification.';
    END

    SELECT @ResultCode AS ResultCode, @Message AS [Message], @CurrentCompID AS Comp_ID;
END
GO
