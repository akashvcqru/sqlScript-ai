USE [Vcqru]
GO

/****** Object:  StoredProcedure [dbo].[USP_CanAddUser] ******/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_CanAddUser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_CanAddUser]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_CanAddUser]
    @M_ConsumerId VARCHAR(50),
    @UserType INT,
    @CompId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CanAddUser BIT = 0;
    DECLARE @v1 INT;
    DECLARE @level1 INT;
    DECLARE @level2 INT;

    IF @M_ConsumerId IS NULL OR LTRIM(RTRIM(@M_ConsumerId)) = ''
    BEGIN
        SET @CanAddUser = 1;
        SELECT @CanAddUser AS CanAddUser;
        RETURN;
    END

    SELECT TOP 1 @v1 = Vrkabel_User_Type
    FROM tbl_Vendorvisekycstatus
    WHERE M_consumerId = CAST(@M_ConsumerId AS INT)
      AND comp_id = @CompId;

    IF @v1 IS NULL
    BEGIN
        SET @CanAddUser = 0;
        SELECT @CanAddUser AS CanAddUser;
        RETURN;
    END

    SELECT TOP 1 @level1 = Level
    FROM User_Type
    WHERE Row_ID = @UserType;

    SELECT TOP 1 @level2 = Level
    FROM User_Type
    WHERE Row_ID = @v1;

    IF @level1 IS NULL OR @level2 IS NULL
    BEGIN
        SET @CanAddUser = 0;
        SELECT @CanAddUser AS CanAddUser;
        RETURN;
    END

    IF @level1 < @level2
        SET @CanAddUser = 1;
    ELSE
        SET @CanAddUser = 0;

    SELECT @CanAddUser AS CanAddUser;
END
GO

/****** Object:  StoredProcedure [dbo].[USP_Consumerreg] ******/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_Consumerreg]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_Consumerreg]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Consumerreg]        
    @MobileNo NVARCHAR(50),        
    @Password NVARCHAR(50),        
    @Entry_Date DATETIME = NULL,        
    @IsActive BIT,        
    @IsDelete BIT,     
	@Comp_id nvarchar(100)=null,
    @User_ID NVARCHAR(50) OUTPUT,        
    @M_Consumerid NVARCHAR(50) OUTPUT        
AS        
BEGIN        
    SET NOCOUNT ON;        
      
    DECLARE @Reffralcode INT , @Finalreffral nvarchar(100);   
	DECLARE @IsKYCRequired BIT;

    SELECT 
        @IsKYCRequired = CASE 
                            WHEN JSON_VALUE(kyc_Details, '$.Iskycrequired') = 'True' 
                            THEN 1 ELSE 0 
                         END
    FROM BrandSettings 
    WHERE Comp_ID = @Comp_id;
         
    SET @Reffralcode = CAST((RAND(CHECKSUM(NEWID())) * 90000000 + 10000000) AS INT);    
	SET @Finalreffral = CONCAT(@Comp_id, @Reffralcode)
      
    EXEC GetCodeGenValue 'Consumer', @User_ID OUTPUT;        
       
    INSERT INTO [M_Consumer]       
        ([User_ID],[Comp_ID], MobileNo, [Password], [Entry_Date], [IsActive], [IsDelete])        
    VALUES       
        (@User_ID, @Comp_id, @MobileNo, @Password, ISNULL(@Entry_Date, GETDATE()), @IsActive, @IsDelete);        
      
    SET @M_Consumerid = CAST(SCOPE_IDENTITY() AS NVARCHAR(50));     
	
	INSERT INTO tbl_Vendorvisekycstatus (M_consumerId, Comp_id, Referral_Code) VALUES (@M_Consumerid, @Comp_id, @Finalreffral)
END
GO

/****** Object:  StoredProcedure [dbo].[USP_UPDATECONSUMERDATA_Multiuser] ******/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_UPDATECONSUMERDATA_Multiuser]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_UPDATECONSUMERDATA_Multiuser]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_UPDATECONSUMERDATA_Multiuser]            
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
   @Vrkabel_User_Type varchar(10) = NULL,            
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
   @M_ConsumerId varchar(100) = NULL   ,      
   @Outlet_name varchar(100)=null,      
   @Owner_name varchar(100)=null,      
   @Segmanet_name varchar(100)=null,      
   @Branddetails nvarchar(max)=null,    
   @Dealer_M_consumerid nvarchar(100)=null    
AS            
BEGIN            
    UPDATE M_Consumer      
    SET       
        ConsumerName = CASE WHEN @ConsumerName IS NOT NULL AND LTRIM(RTRIM(@ConsumerName)) <> '' THEN @ConsumerName ELSE ConsumerName END,      
        City         = CASE WHEN @City IS NOT NULL AND LTRIM(RTRIM(@City)) <> '' THEN @City ELSE City END,      
        PinCode      = CASE WHEN @PinCode IS NOT NULL AND LTRIM(RTRIM(@PinCode)) <> '' THEN @PinCode ELSE PinCode END,      
        state        = CASE WHEN @state IS NOT NULL AND LTRIM(RTRIM(@state)) <> '' THEN @state ELSE state END,      
        Email        = CASE WHEN @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> '' THEN @Email ELSE Email END,      
        UPIId        = CASE WHEN @UPI IS NOT NULL AND LTRIM(RTRIM(@UPI)) <> '' THEN @UPI ELSE UPIId END,      
        Address      = CASE WHEN @Address IS NOT NULL AND LTRIM(RTRIM(@Address)) <> '' THEN @Address ELSE Address END,
        DOB          = CASE WHEN @Vr_dob IS NOT NULL AND LTRIM(RTRIM(@Vr_dob)) <> '' THEN @Vr_dob ELSE DOB END
    WHERE       
        @M_ConsumerId IS NOT NULL AND LTRIM(RTRIM(@M_ConsumerId)) <> '' AND M_Consumerid = @M_ConsumerId;      

    IF (@Comp_id = 'Comp-1152')
    BEGIN
        UPDATE M_Consumer
        SET 
            employeeID = @Outlet_name,
            distributorID = @Owner_name
        WHERE 
            @M_ConsumerId IS NOT NULL 
            AND LTRIM(RTRIM(@M_ConsumerId)) <> '' 
            AND M_Consumerid = @M_ConsumerId;
    END

    UPDATE tbl_Vendorvisekycstatus          
    SET             
        Name = @ConsumerName,            
        EmailId = @Email,            
        usercity = @City,            
        userpin = @PinCode,            
        userstate = @state,            
        Vrkabel_User_Type=@Vrkabel_User_Type,          
        userupi = @UPI,            
        Segmanet_name=@Segmanet_name,      
        Outlet_name=@Outlet_name,      
        Owner_name=@Owner_name,      
        Branddetails=@Branddetails,    
        Dealer_M_consumerid=@Dealer_M_consumerid,  
        shop_file=@shop_file  
    WHERE M_Consumerid = @M_ConsumerId;            
            
    SELECT * FROM [M_Consumer] WHERE M_Consumerid = @M_ConsumerId;
END
GO

/****** Object:  StoredProcedure [dbo].[USP_ADDREFERRALPOINT_BLAPP] ******/
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_ADDREFERRALPOINT_BLAPP]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_ADDREFERRALPOINT_BLAPP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_ADDREFERRALPOINT_BLAPP]  
    @ReferralConsumerId INT,    
    @ReferredConsumerId INT,    
    @CompId VARCHAR(10),    
    @ReferralPoint INT,    
    @ReferredPoint INT  
AS    
BEGIN    
    DECLARE @CurrentDate DATETIME = GETDATE();  
  
    BEGIN TRY  
        IF (@ReferralPoint = 0 AND @ReferredPoint = 0)  
        BEGIN  
            SELECT -1 AS StatusCode, 'Both Referral and Referred Points are Zero. No action taken.' AS RefResult;  
            RETURN;  
        END  
  
        IF (@ReferralPoint > 0)  
        BEGIN  
            INSERT INTO BLoyaltyPointsEarned (M_Consumerid, Points, UpdateDate, ServiceName, compid)    
            VALUES (@ReferralConsumerId, @ReferralPoint, @CurrentDate, 'Referral', @CompId);    
        END  
  
        IF (@ReferredPoint > 0)  
        BEGIN  
            INSERT INTO BLoyaltyPointsEarned (M_Consumerid, Points, UpdateDate, ServiceName, compid)    
            VALUES (@ReferredConsumerId, @ReferredPoint, @CurrentDate, 'Referral', @CompId);    
        END  
  
        SELECT 0 AS StatusCode, 'Referral Points Added Successfully' AS RefResult;    
    END TRY  
    BEGIN CATCH  
        SELECT -1 AS StatusCode, ERROR_MESSAGE() AS ErrorMessage;    
    END CATCH  
END
GO
