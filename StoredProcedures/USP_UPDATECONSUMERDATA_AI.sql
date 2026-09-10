SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_UPDATECONSUMERDATA_AI]                                
(                                
    @M_ConsumerId nvarchar(50),                                
    @MobileNo nvarchar(100),                                
    @ConsumerName nvarchar(300) = null,                                
    @Email nvarchar(300) = null,                                
    @City nvarchar(100) = null,                                
    @PinCode nvarchar(20) = null,                                
    @Address nvarchar(1000) = null,                                
    @employeeID varchar(20) = null,                                
    @distributorID varchar(20) = null,                                
    @aadharNumber varchar(12) = null,                                
    @aadharFile nvarchar(260) = null,                                
    @aadharFile_back nvarchar(260) = null,                                
    @uploadedby nvarchar(100) = null,                                
    @uploadedsource nvarchar(100) = null,                                
    @village nvarchar(100) = null,                                
    @district nvarchar(80) = null,                                
    @state nvarchar(100) = null,                                
    @country nvarchar(60) = null,                                
    @role_id int = null,                                
    @Comp_id nvarchar(40) = null,                                
    @Created_by varchar(16) = null,                                
    @permanemt nvarchar(max) = null,                                
    @SellerName nvarchar(200) = null,                                
    @Commision int = null,                                
    @token nvarchar(800) = null,                                
    @Inox_User_Type varchar(5) = null,                                
    @Vrkabel_User_Type int = null,                                
    @Vr_cin_number varchar(100) = null,                                
    @Vr_ref_cin_number varchar(100) = null,                                
    @Vr_designation nvarchar(40) = null,                                
    @Vr_dob nvarchar(40) = null,                                
    @Vr_gender varchar(15) = null,                                
    @Vr_sur_name varchar(50) = null,                                
    @Vr_communication_status int = null,                                
    @Vr_business_status int = null,                                
    @Vr_house_number varchar(20) = null,                                
    @Vr_land_mark varchar(100) = null,                                
    @Other_Role varchar(50) = null,                                
    @UPI varchar(100) = null,                                
    @gst_number varchar(50) = null,                                
    @shop_file varchar(100) = null,                                
    @shop_name varchar(50) = null,                                
    @Shop_address varchar(255) = null,                                
    @FirmName varchar(255) = null,                                
    @pancard_number varchar(50) = null,                                
    @pan_card_file varchar(100) = null,                                
    @Agegroup nvarchar(200) = null,                                
    @ReferralCode nvarchar(20) = null,                                
    @teslapayoutmode varchar(100) = null
)                                
AS                                
BEGIN                                
    DECLARE @ActualId int = TRY_CAST(@M_ConsumerId AS int);

    IF @ActualId IS NULL
    BEGIN
        SELECT 'Error: Invalid Consumer ID' AS Result;
        RETURN;
    END

    UPDATE [M_Consumer]                                
    SET 
        [ConsumerName] = COALESCE(@ConsumerName, [ConsumerName]),                                
        [Email] = COALESCE(@Email, [Email]),                                
        [City] = COALESCE(@City, [City]),                                
        [PinCode] = COALESCE(@PinCode, [PinCode]),                                
        [Address] = COALESCE(@Address, [Address]),                                
        [employeeID] = COALESCE(@employeeID, [employeeID]),                                
        [distributorID] = COALESCE(@distributorID, [distributorID]),                                
        [aadharNumber] = COALESCE(@aadharNumber, [aadharNumber]),                                
        [aadharFile] = COALESCE(@aadharFile, [aadharFile]),                                
        [aadharback] = COALESCE(@aadharFile_back, [aadharback]),                                
        [aadharUploadedBy] = COALESCE(@uploadedby, [aadharUploadedBy]),                                
        [Aadhar_source] = COALESCE(@uploadedsource, [Aadhar_source]),                                
        [village] = COALESCE(@village, [village]),                                
        [district] = COALESCE(@district, [district]),                                
        [state] = COALESCE(@state, [state]),                                
        [country] = COALESCE(@country, [country]),                                
        [Role_Id] = COALESCE(@role_id, [Role_Id]),                                
        [Created_by] = COALESCE(@Created_by, [Created_by]),                                
        [Per_Address] = COALESCE(@permanemt, [Per_Address]),                                
        [SellerName] = COALESCE(@SellerName, [SellerName]),                                
        [communication_status] = COALESCE(@Vr_communication_status, @Commision, [communication_status]),                                
        [token] = COALESCE(@token, [token]),                                
        [Inox_User_Type] = COALESCE(@Inox_User_Type, [Inox_User_Type]),                                
        [Vrkabel_User_Type] = COALESCE(@Vrkabel_User_Type, [Vrkabel_User_Type]),                                
        [cin_number] = COALESCE(@Vr_cin_number, [cin_number]),                                
        [ref_cin_number] = COALESCE(@Vr_ref_cin_number, [ref_cin_number]),                                
        [designation] = COALESCE(@Vr_designation, [designation]),                                
        [dob] = COALESCE(@Vr_dob, [dob]),                                
        [gender] = COALESCE(@Vr_gender, [gender]),                                
        [sur_name] = COALESCE(@Vr_sur_name, [sur_name]),                                
        [business_status] = COALESCE(@Vr_business_status, [business_status]),                                
        [house_number] = COALESCE(@Vr_house_number, [house_number]),                                
        [land_mark] = COALESCE(@Vr_land_mark, [land_mark]),                                
        [Other_Role] = COALESCE(@Other_Role, [Other_Role]),                                
        [UPIId] = COALESCE(@UPI, [UPIId]),                                
        [gst_number] = COALESCE(@gst_number, [gst_number]),                                
        [shop_file] = COALESCE(@shop_file, [shop_file]),                                
        [shop_name] = COALESCE(@shop_name, [shop_name]),                                
        [Shop_address] = COALESCE(@Shop_address, [Shop_address]),                                
        [FirmName] = COALESCE(@FirmName, [FirmName]),                                
        [pancard_number] = COALESCE(@pancard_number, [pancard_number]),                                
        [pan_card_file] = COALESCE(@pan_card_file, [pan_card_file]),                                
        [Agegroup] = COALESCE(@Agegroup, [Agegroup]),                                
        [ReferralCode] = COALESCE(TRY_CAST(NULLIF(@ReferralCode, '') AS numeric(13,0)), [ReferralCode]),                                
        [teslapayoutmode] = COALESCE(@teslapayoutmode, [teslapayoutmode]),
        [aadharUploadedate] = GETDATE()
    WHERE [M_Consumerid] = @ActualId AND [MobileNo] = @MobileNo                                
                                
    -- Update tbl_Vendorvisekycstatus if Vrkabel_User_Type is updated or other profile details are updated
    IF @Comp_id IS NOT NULL AND @Comp_id <> ''
    BEGIN
        UPDATE tbl_Vendorvisekycstatus
        SET 
            Name = CASE WHEN @ConsumerName IS NOT NULL AND LTRIM(RTRIM(@ConsumerName)) <> '' THEN @ConsumerName ELSE Name END,
            EmailId = CASE WHEN @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> '' THEN @Email ELSE EmailId END,
            usercity = CASE WHEN @City IS NOT NULL AND LTRIM(RTRIM(@City)) <> '' THEN @City ELSE usercity END,
            userpin = CASE WHEN @PinCode IS NOT NULL AND LTRIM(RTRIM(@PinCode)) <> '' THEN @PinCode ELSE userpin END,
            userstate = CASE WHEN @state IS NOT NULL AND LTRIM(RTRIM(@state)) <> '' THEN @state ELSE userstate END,
            userupi = CASE WHEN @UPI IS NOT NULL AND LTRIM(RTRIM(@UPI)) <> '' THEN @UPI ELSE userupi END,
            shop_file = CASE WHEN @shop_file IS NOT NULL AND LTRIM(RTRIM(@shop_file)) <> '' THEN @shop_file ELSE shop_file END,
            Vrkabel_User_Type = CASE WHEN @Vrkabel_User_Type IS NOT NULL AND @Vrkabel_User_Type > 0 THEN @Vrkabel_User_Type ELSE Vrkabel_User_Type END
        WHERE M_consumerId = @ActualId AND Comp_id = @Comp_id;
    END
    ELSE
    BEGIN
        UPDATE tbl_Vendorvisekycstatus
        SET 
            Name = CASE WHEN @ConsumerName IS NOT NULL AND LTRIM(RTRIM(@ConsumerName)) <> '' THEN @ConsumerName ELSE Name END,
            EmailId = CASE WHEN @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> '' THEN @Email ELSE EmailId END,
            usercity = CASE WHEN @City IS NOT NULL AND LTRIM(RTRIM(@City)) <> '' THEN @City ELSE usercity END,
            userpin = CASE WHEN @PinCode IS NOT NULL AND LTRIM(RTRIM(@PinCode)) <> '' THEN @PinCode ELSE userpin END,
            userstate = CASE WHEN @state IS NOT NULL AND LTRIM(RTRIM(@state)) <> '' THEN @state ELSE userstate END,
            userupi = CASE WHEN @UPI IS NOT NULL AND LTRIM(RTRIM(@UPI)) <> '' THEN @UPI ELSE userupi END,
            shop_file = CASE WHEN @shop_file IS NOT NULL AND LTRIM(RTRIM(@shop_file)) <> '' THEN @shop_file ELSE shop_file END,
            Vrkabel_User_Type = CASE WHEN @Vrkabel_User_Type IS NOT NULL AND @Vrkabel_User_Type > 0 THEN @Vrkabel_User_Type ELSE Vrkabel_User_Type END
        WHERE M_consumerId = @ActualId;
    END

    SELECT 'Success' AS Result                                
END
GO
