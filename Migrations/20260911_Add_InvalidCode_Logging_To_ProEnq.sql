-- =============================================
-- Migration: Add Invalid Code Logging to Pro_Enq in USP_BLchkwarranty_AI
-- Date: 2026-09-11
-- Description:
--   1. When an invalid code is submitted to USP_BLchkwarranty_AI (@RowID IS NULL),
--      resolve Comp_ID (from parameter or Code1 fallback) and insert into Pro_Enq
--      with Is_Success = '0' and Dial_Mode = 'Website'.
--   2. Update existing success and duplicate enquiries in USP_BLchkwarranty_AI to use Dial_Mode = 'Website'.
-- =============================================

USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_BLchkwarranty_AI]
    @Code1 VARCHAR(10),
    @Code2 VARCHAR(15),
    @MobileNo VARCHAR(20) = NULL,
    @ConsumerName NVARCHAR(150) = NULL,
    @Email NVARCHAR(150) = NULL,
    @City NVARCHAR(100) = NULL,
    @State NVARCHAR(100) = NULL,
    @PinCode NVARCHAR(15) = NULL,
    @Address NVARCHAR(250) = NULL,
    @PurchaseDate DATETIME = NULL,
    @Comp_ID VARCHAR(50) = NULL,
    @Latitude VARCHAR(50) = NULL,
    @Longitude VARCHAR(50) = NULL,
    @Role_Id INT = NULL,
    @Remark NVARCHAR(MAX) = NULL,
    @ImagePath NVARCHAR(400) = NULL,
    @BillNo NVARCHAR(50) = NULL,
    @PurchaseFrom VARCHAR(50) = NULL,
    @ImagePathBill NVARCHAR(200) = NULL,
    @SerialNo VARCHAR(100) = NULL,
    @VehicleNumber NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResultCode INT = 1; -- 1: Success, 0: Invalid, 2: Already Registered, 3: Error
    DECLARE @Message NVARCHAR(MAX) = '';
    DECLARE @RowID NUMERIC(12, 0) = NULL;
    DECLARE @UseCount NUMERIC(5, 0) = 0;
    DECLARE @ActualCompID VARCHAR(50) = NULL;
    DECLARE @ProID VARCHAR(50) = NULL;
    DECLARE @TableName NVARCHAR(50) = 'M_Code';
    DECLARE @M_ConsumerID INT = NULL;
    DECLARE @ResolvedServiceId VARCHAR(50) = 'SRV1023';

    -- 1. Normalize Mobile (add 91 if 10 digits)
    IF @MobileNo IS NOT NULL AND LEN(@MobileNo) = 10
    BEGIN
        SET @MobileNo = '91' + @MobileNo;
    END

    -- 2. Validate Code Existence
    IF EXISTS (SELECT 1 FROM M_Code WHERE Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND Code2 = CAST(@Code2 AS NUMERIC(8,0)) AND (ScrapeFlag = 0 OR ScrapeFlag IS NULL))
    BEGIN
        SET @TableName = 'M_Code';
        SELECT TOP 1 
            @RowID = mc.Row_ID, 
            @UseCount = ISNULL(mc.Use_Count, 0), 
            @ActualCompID = pr.Comp_ID,
            @ProID = mc.Pro_ID
        FROM M_Code mc
        INNER JOIN Pro_Reg pr ON mc.Pro_ID = pr.Pro_ID
        WHERE mc.Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND mc.Code2 = CAST(@Code2 AS NUMERIC(8,0));
    END
    ELSE IF EXISTS (SELECT 1 FROM M_Code_PFL WHERE Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND Code2 = CAST(@Code2 AS NUMERIC(8,0)) AND (ScrapeFlag = 0 OR ScrapeFlag IS NULL))
    BEGIN
        SET @TableName = 'M_Code_PFL';
        SELECT TOP 1 
            @RowID = mc.Row_ID, 
            @UseCount = ISNULL(mc.Use_Count, 0), 
            @ActualCompID = pr.Comp_ID,
            @ProID = mc.Pro_ID
        FROM M_Code_PFL mc
        INNER JOIN Pro_Reg pr ON mc.Pro_ID = pr.Pro_ID
        WHERE mc.Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND mc.Code2 = CAST(@Code2 AS NUMERIC(8,0));
    END

    IF @RowID IS NULL
    BEGIN
        DECLARE @ResolvedCompID VARCHAR(50) = @Comp_ID;
        IF @ResolvedCompID IS NULL OR @ResolvedCompID = ''
        BEGIN
            SELECT TOP 1 @ResolvedCompID = pr.Comp_ID 
            FROM M_Code mc WITH (NOLOCK) 
            INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID 
            WHERE mc.Code1 = TRY_CAST(@Code1 AS NUMERIC(5,0));

            IF @ResolvedCompID IS NULL OR @ResolvedCompID = ''
            BEGIN
                SELECT TOP 1 @ResolvedCompID = pr.Comp_ID 
                FROM M_Code_PFL mc WITH (NOLOCK) 
                INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID 
                WHERE mc.Code1 = TRY_CAST(@Code1 AS NUMERIC(5,0));
            END
        END

        INSERT INTO Pro_Enq (
            Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, 
            Is_Success, Enq_Date, Comp_ID, Latitude, Longitude, City, state, PinCode,
            IsActive, IsDelete, Created_Date
        )
        VALUES (
            @Code1, @Code2, RIGHT(ISNULL(@MobileNo, ''), 10), 'Website', 'Warranty Registration', 
            '0', GETDATE(), @ResolvedCompID, @Latitude, @Longitude, @City, @State, @PinCode,
            1, 0, GETDATE()
        );

        SET @ResultCode = 0;
        SET @Message = 'INVALID: Invalid Code. Please check the 13-digit code and try again.';
        SELECT 
            @ResultCode AS ResultCode, 
            @Message AS [Message],
            NULL AS ProductName,
            NULL AS BrandName,
            @ResolvedCompID AS CompId,
            NULL AS ProductImage,
            0 AS WarrantyPeriod,
            NULL AS ExpirationDate,
            NULL AS ProId;
        RETURN;
    END

    -- Check Service Subscription for E-Warranty (@ResolvedServiceId)
    DECLARE @Subscribe_Id NVARCHAR(100) = NULL;
    SELECT TOP 1 @Subscribe_Id = Subscribe_Id 
    FROM M_ServiceSubscription 
    WHERE Pro_ID = @ProID AND Service_ID = @ResolvedServiceId AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0;

    IF @Subscribe_Id IS NULL
    BEGIN
        SET @ResultCode = 0;
        SET @Message = 'INVALID: This product is not registered/subscribed for warranty service.';
        SELECT 
            @ResultCode AS ResultCode, 
            @Message AS [Message],
            NULL AS ProductName,
            NULL AS BrandName,
            @ActualCompID AS CompId,
            NULL AS ProductImage,
            0 AS WarrantyPeriod,
            NULL AS ExpirationDate,
            @ProID AS ProId;
        RETURN;
    END

    -- Dynamic Landing Page Field Configurations validation
    DECLARE @PageId INT;
    SELECT TOP 1 @PageId = PageId 
    FROM LandingPage 
    WHERE Comp_Id = @ActualCompID AND Service_Id = @ResolvedServiceId AND IsActive = 1;

    IF @PageId IS NOT NULL
    BEGIN
        -- 1. MobileNo Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'mobile' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@MobileNo IS NULL OR @MobileNo = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Mobile number is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 2. ConsumerName Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'name' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@ConsumerName IS NULL OR @ConsumerName = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Consumer Name is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 3. Email Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'email' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@Email IS NULL OR @Email = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Email ID is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 4. City Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'city' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@City IS NULL OR @City = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: City is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 5. State Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'state' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@State IS NULL OR @State = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: State is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 6. PinCode Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'PinCode' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@PinCode IS NULL OR @PinCode = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Pin Code is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 7. Address Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'Address' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@Address IS NULL OR @Address = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Address is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 8. PurchaseDate Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'purchasedate' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND @PurchaseDate IS NULL
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Purchase Date is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 9. BillNo Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'billno' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@BillNo IS NULL OR @BillNo = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Bill Number is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END

        -- 10. PurchaseFrom Validation
        IF EXISTS (
            SELECT 1 
            FROM LandingPage_FieldConfig FC 
            INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId 
            WHERE FC.PageId = @PageId AND MF.FieldName = 'PurchaseFrom' AND FC.IsRequired = 1 AND FC.IsVisible = 1
        ) AND (@PurchaseFrom IS NULL OR @PurchaseFrom = '')
        BEGIN
            SET @ResultCode = 0;
            SET @Message = 'INVALID: Purchased From is required.';
            SELECT 
                @ResultCode AS ResultCode, 
                @Message AS [Message],
                NULL AS ProductName,
                NULL AS BrandName,
                @ActualCompID AS CompId,
                NULL AS ProductImage,
                0 AS WarrantyPeriod,
                NULL AS ExpirationDate,
                @ProID AS ProId;
            RETURN;
        END
    END

    -- 3. Check Warranty Registration Table (WarrentyDetails)
    DECLARE @ExistingId BIGINT = NULL;
    DECLARE @ExistingExpiration VARCHAR(50) = NULL;
    DECLARE @CodeKey VARCHAR(50) = @Code1 + '-' + @Code2;
    DECLARE @CleanCode VARCHAR(50) = @Code1 + @Code2;

    SELECT TOP 1 @ExistingId = id, @ExistingExpiration = CONVERT(VARCHAR(11), ExpirationDate, 106)
    FROM WarrentyDetails
    WHERE Code = @CodeKey;

    IF @ExistingId IS NULL
    BEGIN
        SELECT TOP 1 @ExistingId = id, @ExistingExpiration = CONVERT(VARCHAR(11), ExpirationDate, 106)
        FROM WarrentyDetails
        WHERE Code = @CleanCode;
    END

    -- Fetch Product details
    DECLARE @ProductName NVARCHAR(200) = 'Authentic Product';
    DECLARE @ProductImage VARCHAR(200) = '';
    DECLARE @BrandName VARCHAR(200) = NULL;

    SELECT TOP 1 
        @ProductName = P.Pro_Name,
        @BrandName = C.Comp_Name,
        @ProductImage = ISNULL(LP.ProductImage1, '')
    FROM Pro_Reg P
    INNER JOIN Comp_Reg C ON P.Comp_ID = C.Comp_ID
    LEFT JOIN LandingPage LP ON LP.Comp_Id = C.Comp_ID AND LP.Service_Id = @ResolvedServiceId
    WHERE P.Pro_ID = @ProID;

    IF @BrandName IS NULL
    BEGIN
        SELECT TOP 1 @BrandName = Comp_Name FROM Comp_Reg WHERE Comp_ID = @ActualCompID;
    END

    IF @ExistingId IS NOT NULL
    BEGIN
        SET @ResultCode = 2;
        -- The legacy Javascript check expects the message to contain "ALREADY"
        SET @Message = 'ALREADY: Warranty is already registered for this coupon. Valid till ' + @ExistingExpiration;
        
        SELECT 
            @ResultCode AS ResultCode, 
            @Message AS [Message],
            @ProductName AS ProductName,
            @BrandName AS BrandName,
            @ActualCompID AS CompId,
            @ProductImage AS ProductImage,
            @WarrantyPeriod AS WarrantyPeriod,
            @ExistingExpiration AS ExpirationDate,
            @ProID AS ProId;
        RETURN;
    END

    -- 4. Calculate Warranty Expiration Date
    DECLARE @WarrantyPeriod INT = 0;
    SELECT TOP 1 @WarrantyPeriod = ISNULL(WarrantyPeriod, 0)
    FROM M_ServiceSubscriptionTrans
    WHERE Subscribe_Id = @Subscribe_Id AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0;

    DECLARE @EffectivePurchaseDate DATETIME = ISNULL(@PurchaseDate, GETDATE());
    DECLARE @ExpirationDate DATETIME = DATEADD(MONTH, @WarrantyPeriod, @EffectivePurchaseDate);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert into WarrentyDetails
        INSERT INTO WarrentyDetails (
            Code, MobileNo, ConsumerName, Email, City, State, PinCode, Address, 
            PurchaseDate, EntryDate, Comp_ID, Latitude, Longitude, Role_Id, 
            Remark, ImagePath, BillNo, PurchaseFrom, ImagePathBill, SerialNo, 
            VehicleNumber, ExpirationDate
        )
        VALUES (
            @CodeKey, RIGHT(ISNULL(@MobileNo, ''), 10), @ConsumerName, @Email, @City, @State, @PinCode, @Address,
            @EffectivePurchaseDate, GETDATE(), @ActualCompID, @Latitude, @Longitude, @Role_Id,
            @Remark, @ImagePath, @BillNo, @PurchaseFrom, @ImagePathBill, @SerialNo,
            @VehicleNumber, @ExpirationDate
        );

        -- Consumer Profile Sync
        IF @MobileNo IS NOT NULL AND @MobileNo <> ''
        BEGIN
            SELECT TOP 1 @M_ConsumerID = M_Consumerid FROM M_Consumer WHERE right(MobileNo, 10) = right(@MobileNo, 10);
            DECLARE @LogCompID NVARCHAR(50) = ISNULL(@Comp_ID, @ActualCompID);

            IF @M_ConsumerID IS NULL
            BEGIN
                DECLARE @GeneratedUserID NVARCHAR(50);
                EXEC GetCodeGenValue 'Consumer', @GeneratedUserID OUTPUT;
                DECLARE @RandomPassword NVARCHAR(5) = RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR(5)), 5);

                INSERT INTO M_Consumer (User_ID, ConsumerName, Email, MobileNo, City, state, PinCode, Entry_Date, IsActive, IsDelete, Role_Id, Password, Comp_id, Address)
                VALUES (@GeneratedUserID, ISNULL(@ConsumerName, 'Consumer'), @Email, @MobileNo, @City, @State, @PinCode, GETDATE(), 1, 0, @Role_Id, @RandomPassword, @LogCompID, @Address);
                
                SET @M_ConsumerID = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                UPDATE M_Consumer 
                SET ConsumerName = ISNULL(@ConsumerName, ConsumerName),
                    Email = ISNULL(@Email, Email),
                    City = ISNULL(@City, City),
                    state = ISNULL(@State, state),
                    PinCode = ISNULL(@PinCode, PinCode),
                    Comp_id = ISNULL(Comp_id, @LogCompID),
                    Address = ISNULL(@Address, Address)
                WHERE M_Consumerid = @M_ConsumerID;
            END
        END

        -- Also record inquiry to track code checks
        INSERT INTO Pro_Enq (Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, Is_Success, Enq_Date, Comp_ID)
        VALUES (@Code1, @Code2, RIGHT(ISNULL(@MobileNo, ''), 10), 'Website', 'Warranty Registration', '1', GETDATE(), @ActualCompID);

        -- Increment code check count
        IF @TableName = 'M_Code'
        BEGIN
            UPDATE M_Code SET Use_Count = ISNULL(Use_Count, 0) + 1 WHERE Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND Code2 = CAST(@Code2 AS NUMERIC(8,0));
        END
        ELSE
        BEGIN
            UPDATE M_Code_PFL SET Use_Count = ISNULL(Use_Count, 0) + 1 WHERE Code1 = CAST(@Code1 AS NUMERIC(5,0)) AND Code2 = CAST(@Code2 AS NUMERIC(8,0));
        END

        COMMIT TRANSACTION;

        SET @Message = 'Warranty registered successfully. Valid till ' + CONVERT(VARCHAR(11), @ExpirationDate, 106);

        SELECT 
            @ResultCode AS ResultCode, 
            @Message AS [Message],
            @ProductName AS ProductName,
            @BrandName AS BrandName,
            @ActualCompID AS CompId,
            @ProductImage AS ProductImage,
            @WarrantyPeriod AS WarrantyPeriod,
            CONVERT(VARCHAR(11), @ExpirationDate, 106) AS ExpirationDate,
            @ProID AS ProId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ResultCode = 3;
        SET @Message = 'ERROR: ' + ERROR_MESSAGE();

        SELECT 
            @ResultCode AS ResultCode, 
            @Message AS [Message],
            NULL AS ProductName,
            NULL AS BrandName,
            @ActualCompID AS CompId,
            NULL AS ProductImage,
            0 AS WarrantyPeriod,
            NULL AS ExpirationDate,
            @ProID AS ProId;
    END CATCH
END
GO
