USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_UPDATECONSUMERDATA_Multiuser_AI]            
   @ConsumerName nvarchar(150),            
   @Email nvarchar(150),            
   @MobileNo nvarchar(50),            
   @City nvarchar(50),            
   @PinCode nvarchar(50),            
   @Address nvarchar(500),            
   @employeeID nvarchar(50) = NULL,            
   @distributorID nvarchar(50) = NULL,            
   @aadharNumber nvarchar(50) = NULL,            
   @aadharFile nvarchar(255) = NULL,            
   @aadharFile_back nvarchar(255) = NULL,            
   @uploadedby nvarchar(50) = NULL,            
   @uploadedsource nvarchar(50) = NULL,            
   @village nvarchar(100) = NULL,            
   @district nvarchar(100) = NULL,            
   @state nvarchar(100) = NULL,            
   @country nvarchar(100) = NULL,            
   @role_id int = NULL,   
   @Ref_By int = NULL,   
   @Comp_id nvarchar(20) = NULL,            
   @Created_by int = NULL,            
   @permanemt nvarchar(500) = NULL,            
   @SellerName nvarchar(500) = NULL,            
   @Commision nvarchar(10) = NULL,            
   @token nvarchar(500) = NULL,            
   @Inox_User_Type varchar(100) = NULL,            
   @Vrkabel_User_Type INT = NULL,            
   @Vr_cin_number varchar(50) = NULL,            
   @Vr_ref_cin_number varchar(50) = NULL,            
   @Vr_designation varchar(100) = NULL,            
   @Vr_dob varchar(50) = NULL,            
   @Vr_gender varchar(50) = NULL,            
   @Vr_sur_name varchar(50) = NULL,            
   @Vr_communication_status int = NULL,            
   @Vr_business_status int = NULL,            
   @Vr_house_number varchar(50) = NULL,            
   @Vr_land_mark varchar(100) = NULL,            
   @Other_Role varchar(50) = NULL,            
   @UPI varchar(50) = NULL,            
   @gst_number varchar(50) = NULL,            
   @shop_file varchar(500) = NULL,            
   @shop_name varchar(500) = NULL,            
   @Shop_address varchar(max) = NULL,            
   @FirmName varchar(500) = NULL,            
   @pancard_number varchar(50) = NULL,            
   @pan_card_file varchar(100) = NULL,            
   @Agegroup varchar(50) = NULL,            
   @ReferralCode varchar(100) = NULL,            
   @teslapayoutmode varchar(100) = NULL,            
   @M_ConsumerId INT = NULL,      
   @Outlet_name varchar(100) = NULL,      
   @Owner_name varchar(100) = NULL,      
   @Segmanet_name varchar(100) = NULL,      
   @Branddetails nvarchar(max) = NULL,    
   @Dealer_M_consumerid nvarchar(100) = NULL    
AS            
BEGIN            
    SET NOCOUNT ON;
    UPDATE M_Consumer      
    SET       
        ConsumerName = CASE WHEN @ConsumerName IS NOT NULL AND LTRIM(RTRIM(@ConsumerName)) <> '' THEN @ConsumerName ELSE ConsumerName END,      
        City         = CASE WHEN @City IS NOT NULL AND LTRIM(RTRIM(@City)) <> '' THEN @City ELSE City END,      
        PinCode      = CASE WHEN @PinCode IS NOT NULL AND LTRIM(RTRIM(@PinCode)) <> '' THEN @PinCode ELSE PinCode END,      
        [state]      = CASE WHEN @state IS NOT NULL AND LTRIM(RTRIM(@state)) <> '' THEN @state ELSE state END,      
        Email        = CASE WHEN @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> '' THEN @Email ELSE Email END,      
        UPIId        = CASE WHEN @UPI IS NOT NULL AND LTRIM(RTRIM(@UPI)) <> '' THEN @UPI ELSE UPIId END,      
        [Address]    = CASE WHEN @Address IS NOT NULL AND LTRIM(RTRIM(@Address)) <> '' THEN @Address ELSE Address END,
        DOB          = CASE WHEN @Vr_dob IS NOT NULL AND LTRIM(RTRIM(@Vr_dob)) <> '' THEN @Vr_dob ELSE DOB END,
        employeeID   = CASE WHEN @employeeID IS NOT NULL AND LTRIM(RTRIM(@employeeID)) <> '' THEN @employeeID ELSE employeeID END,
        distributorID = CASE WHEN @distributorID IS NOT NULL AND LTRIM(RTRIM(@distributorID)) <> '' THEN @distributorID ELSE distributorID END
    WHERE M_Consumerid = @M_ConsumerId;      
      

    UPDATE tbl_Vendorvisekycstatus          
    SET Name = CASE WHEN @ConsumerName IS NOT NULL AND LTRIM(RTRIM(@ConsumerName)) <> '' THEN @ConsumerName ELSE Name END,            
        EmailId = CASE WHEN @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> '' THEN @Email ELSE EmailId END,            
        usercity = CASE WHEN @City IS NOT NULL AND LTRIM(RTRIM(@City)) <> '' THEN @City ELSE usercity END,            
        userpin = CASE WHEN @PinCode IS NOT NULL AND LTRIM(RTRIM(@PinCode)) <> '' THEN @PinCode ELSE userpin END,            
        userstate = CASE WHEN @state IS NOT NULL AND LTRIM(RTRIM(@state)) <> '' THEN @state ELSE userstate END,            
        Vrkabel_User_Type = CASE WHEN @Vrkabel_User_Type IS NOT NULL THEN @Vrkabel_User_Type ELSE Vrkabel_User_Type END,          
        userupi = CASE WHEN @UPI IS NOT NULL AND LTRIM(RTRIM(@UPI)) <> '' THEN @UPI ELSE userupi END,            
        Segmanet_name = CASE WHEN @Segmanet_name IS NOT NULL AND LTRIM(RTRIM(@Segmanet_name)) <> '' THEN @Segmanet_name ELSE Segmanet_name END,      
        Outlet_name = CASE WHEN @Outlet_name IS NOT NULL AND LTRIM(RTRIM(@Outlet_name)) <> '' THEN @Outlet_name ELSE Outlet_name END,      
        Owner_name = CASE WHEN @Owner_name IS NOT NULL AND LTRIM(RTRIM(@Owner_name)) <> '' THEN @Owner_name ELSE Owner_name END,      
        Branddetails = CASE WHEN @Branddetails IS NOT NULL AND LTRIM(RTRIM(@Branddetails)) <> '' THEN @Branddetails ELSE Branddetails END,    
        Dealer_M_consumerid = CASE WHEN @Dealer_M_consumerid IS NOT NULL AND LTRIM(RTRIM(@Dealer_M_consumerid)) <> '' THEN @Dealer_M_consumerid ELSE Dealer_M_consumerid END,  
        shop_file = CASE WHEN @shop_file IS NOT NULL AND LTRIM(RTRIM(@shop_file)) <> '' THEN @shop_file ELSE shop_file END  
    WHERE M_Consumerid = @M_ConsumerId;            
            
    SELECT * FROM [M_Consumer] WHERE M_Consumerid = @M_ConsumerId;
END 
GO
