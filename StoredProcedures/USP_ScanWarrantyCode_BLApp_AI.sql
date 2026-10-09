SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:        AI Assistant (Antigravity)
-- Create date:   2026-06-01
-- Description:   Scan and register warranty code for products subscribed to Warranty service (SRV1023)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ScanWarrantyCode_BLApp_AI]
    @CouponCode VARCHAR(50),
    @MobileNo VARCHAR(20),
    @Email VARCHAR(100) = NULL,
    @Remark NVARCHAR(MAX) = NULL,
    @AlternateMobileNo VARCHAR(20) = NULL,
    @PurchaseDate DATETIME = NULL,
    @ImagePathBill NVARCHAR(200) = NULL,
    @ImagePath NVARCHAR(400) = NULL,
    @Comp_id VARCHAR(50) = NULL,
    @Mode VARCHAR(50) = NULL,
    @Latitude VARCHAR(50) = NULL,
    @Longitude VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @Code1 VARCHAR(10);
    DECLARE @Code2 VARCHAR(10);
    DECLARE @CleanCode VARCHAR(20);

    -- Format Mobile Number to always include 91 prefix
    DECLARE @FormattedMobile VARCHAR(20) = @MobileNo;
    IF LEN(@FormattedMobile) = 10
        SET @FormattedMobile = '91' + @FormattedMobile;
    ELSE
        SET @FormattedMobile = '91' + RIGHT(@FormattedMobile, 10);

    -- 1. Normalize code (remove hyphens, or split by hyphen/length)
    SET @CleanCode = REPLACE(@CouponCode, '-', '');
    
    IF LEN(@CleanCode) = 13
    BEGIN
        SET @Code1 = SUBSTRING(@CleanCode, 1, 5);
        SET @Code2 = SUBSTRING(@CleanCode, 6, 8);
    END
    ELSE IF CHARINDEX('-', @CouponCode) > 0
    BEGIN
        SET @Code1 = LEFT(@CouponCode, CHARINDEX('-', @CouponCode) - 1);
        SET @Code2 = SUBSTRING(@CouponCode, CHARINDEX('-', @CouponCode) + 1, LEN(@CouponCode));
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid coupon code format. Expected 13-digit code or code1-code2.' AS Message;
        RETURN;
    END

    DECLARE @Pro_ID VARCHAR(50) = NULL;
    DECLARE @ResolvedCompID VARCHAR(50) = NULL;
    DECLARE @TableName NVARCHAR(50) = 'M_Code';

    -- 2. Identify code source table and get Pro_ID and Comp_ID
    IF EXISTS (
        SELECT 1 FROM M_Code 
        WHERE Code1 = @Code1 AND Code2 = @Code2 
          AND (ScrapeFlag <> 1 OR ScrapeFlag IS NULL)
          AND (blockCodeStatus <> 1 OR blockCodeStatus IS NULL)
    )
    BEGIN
        SET @TableName = 'M_Code';
        SELECT TOP 1 @Pro_ID = M.Pro_ID, @ResolvedCompID = P.Comp_ID
        FROM M_Code M
        INNER JOIN Pro_Reg P ON M.Pro_ID = P.Pro_ID
        WHERE M.Code1 = @Code1 AND M.Code2 = @Code2
          AND (M.ScrapeFlag <> 1 OR M.ScrapeFlag IS NULL)
          AND (M.blockCodeStatus <> 1 OR M.blockCodeStatus IS NULL);
    END
    ELSE IF EXISTS (
        SELECT 1 FROM M_Code_PFL 
        WHERE Code1 = @Code1 AND Code2 = @Code2 
          AND (ScrapeFlag <> 1 OR ScrapeFlag IS NULL)
    )
    BEGIN
        SET @TableName = 'M_Code_PFL';
        SELECT TOP 1 @Pro_ID = M.Pro_ID, @ResolvedCompID = P.Comp_ID
        FROM M_Code_PFL M
        INNER JOIN Pro_Reg P ON M.Pro_ID = P.Pro_ID
        WHERE M.Code1 = @Code1 AND M.Code2 = @Code2
          AND (M.ScrapeFlag <> 1 OR M.ScrapeFlag IS NULL);
    END

    IF @Pro_ID IS NULL
    BEGIN
        DECLARE @InvalidReason VARCHAR(100) = 'Warranty Registration: Invalid Coupon';
        DECLARE @InvalidMessage VARCHAR(200) = 'Invalid coupon code or code not registered.';

        IF EXISTS (SELECT 1 FROM M_Code WHERE Code1 = @Code1 AND Code2 = @Code2 AND blockCodeStatus = 1)
        BEGIN
            SET @InvalidReason = 'Warranty Registration: Blocked Coupon';
            SET @InvalidMessage = 'This coupon code is blocked.';
        END
        ELSE IF EXISTS (SELECT 1 FROM M_Code WHERE Code1 = @Code1 AND Code2 = @Code2 AND ScrapeFlag = 1)
             OR EXISTS (SELECT 1 FROM M_Code_PFL WHERE Code1 = @Code1 AND Code2 = @Code2 AND ScrapeFlag = 1)
        BEGIN
            SET @InvalidReason = 'Warranty Registration: Scrapped Coupon';
            SET @InvalidMessage = 'This coupon code has been scrapped.';
        END

        INSERT INTO Pro_Enq (Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, Is_Success, Enq_Date, Comp_ID, Latitude, Longitude, callerdate, callertime)
        VALUES (@Code1, @Code2, @FormattedMobile, ISNULL(@Mode, 'BLApp'), @InvalidReason, '0', GETDATE(), @Comp_id, @Latitude, @Longitude, CAST(GETDATE() AS DATE), CONVERT(VARCHAR(30), GETDATE(), 108));

        SELECT 0 AS Success, @InvalidMessage AS Message;
        RETURN;
    END

    -- 3. Check if the product has subscribed to Warranty service (SRV1023)
    DECLARE @Subscribe_Id NVARCHAR(100) = NULL;
    SELECT TOP 1 @Subscribe_Id = Subscribe_Id 
    FROM M_ServiceSubscription 
    WHERE Pro_ID = @Pro_ID AND Service_ID = 'SRV1023' AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0;

    IF @Subscribe_Id IS NULL
    BEGIN
        INSERT INTO Pro_Enq (Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, Is_Success, Enq_Date, Comp_ID, Latitude, Longitude, callerdate, callertime)
        VALUES (@Code1, @Code2, @FormattedMobile, ISNULL(@Mode, 'BLApp'), 'Warranty Registration: Service Not Subscribed', '0', GETDATE(), @ResolvedCompID, @Latitude, @Longitude, CAST(GETDATE() AS DATE), CONVERT(VARCHAR(30), GETDATE(), 108));

        SELECT 0 AS Success, 'This product is not subscribed for warranty service.' AS Message;
        RETURN;
    END

    -- 4. Get Warranty Period from subscription details
    DECLARE @WarrantyPeriod INT = 0;
    SELECT TOP 1 @WarrantyPeriod = ISNULL(WarrantyPeriod, 0) 
    FROM M_ServiceSubscriptionTrans 
    WHERE Subscribe_Id = @Subscribe_Id AND IsActive = 1 AND ISNULL(IsDelete, 0) = 0
    ORDER BY SST_Id DESC;

    -- Fallback to default if not configured or 0
    IF @WarrantyPeriod = 0
        SET @WarrantyPeriod = 12; -- default to 12 months if not specified

    -- 5. Check if already registered in WarrentyDetails
    DECLARE @ExistingId BIGINT = NULL;
    DECLARE @ExistingExpiration VARCHAR(50) = NULL;
    DECLARE @CodeKey VARCHAR(50) = @Code1 + '-' + @Code2;

    SELECT TOP 1 @ExistingId = id, @ExistingExpiration = CONVERT(VARCHAR(11), ExpirationDate, 106)
    FROM WarrentyDetails
    WHERE Code = @CodeKey;

    IF @ExistingId IS NULL
    BEGIN
        -- Also check by full 13-digit code
        SELECT TOP 1 @ExistingId = id, @ExistingExpiration = CONVERT(VARCHAR(11), ExpirationDate, 106)
        FROM WarrentyDetails
        WHERE Code = @CleanCode;
    END

    IF @ExistingId IS NOT NULL
    BEGIN
        INSERT INTO Pro_Enq (Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, Is_Success, Enq_Date, Comp_ID, Latitude, Longitude, callerdate, callertime)
        VALUES (@Code1, @Code2, @FormattedMobile, ISNULL(@Mode, 'BLApp'), 'Warranty Registration: Already Registered', '0', GETDATE(), @ResolvedCompID, @Latitude, @Longitude, CAST(GETDATE() AS DATE), CONVERT(VARCHAR(30), GETDATE(), 108));

        SELECT 0 AS Success, 'Warranty is already registered for this coupon. Valid till ' + @ExistingExpiration AS Message;
        RETURN;
    END

    -- 6. Register Warranty
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ExpirationDate DATETIME = DATEADD(MONTH, @WarrantyPeriod, GETDATE());
        DECLARE @Brand VARCHAR(200) = NULL;
        SELECT TOP 1 @Brand = Comp_Name FROM Comp_Reg WHERE Comp_ID = @ResolvedCompID;

        INSERT INTO [dbo].[WarrentyDetails] (
            Code, Mobile, Email, WarrantyPeriod, ExpirationDate, 
            PurchaseDate, Comment, IsWarrantyClaimed, VendorClaimStatus, 
            claimdate, AlternateMobileNo, Brand, ImagePathBill, ImagePath, Comp_id
        )
        VALUES (
            @CodeKey, @MobileNo, @Email, CAST(@WarrantyPeriod AS VARCHAR(50)), @ExpirationDate, 
            ISNULL(@PurchaseDate, GETDATE()), @Remark, NULL, NULL, 
            GETDATE(), @AlternateMobileNo, @Brand, @ImagePathBill, @ImagePath, ISNULL(@Comp_id, @ResolvedCompID)
        );

        -- Also record inquiry to track code checks
        INSERT INTO Pro_Enq (Received_Code1, Received_Code2, MobileNo, Dial_Mode, Mode_Detail, Is_Success, Enq_Date, Comp_ID, Latitude, Longitude, callerdate, callertime)
        VALUES (@Code1, @Code2, @FormattedMobile, ISNULL(@Mode, 'BLApp'), 'Warranty Registration', '1', GETDATE(), @ResolvedCompID, @Latitude, @Longitude, CAST(GETDATE() AS DATE), CONVERT(VARCHAR(30), GETDATE(), 108));

        -- Increment code check count
        IF @TableName = 'M_Code'
        BEGIN
            UPDATE M_Code SET Use_Count = ISNULL(Use_Count, 0) + 1 WHERE Code1 = @Code1 AND Code2 = @Code2;
        END
        ELSE
        BEGIN
            UPDATE M_Code_PFL SET Use_Count = ISNULL(Use_Count, 0) + 1 WHERE Code1 = @Code1 AND Code2 = @Code2;
        END

        COMMIT TRANSACTION;

        SELECT 1 AS Success, 'Warranty registered successfully. Valid till ' + CONVERT(VARCHAR(11), @ExpirationDate, 106) AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SELECT 0 AS Success, 'Error: ' + ERROR_MESSAGE() AS Message;
    END CATCH
END
GO
