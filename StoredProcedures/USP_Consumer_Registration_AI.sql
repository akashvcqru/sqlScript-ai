USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_Consumer_Registration_AI]        
    @OutletName NVARCHAR(100) = NULL,        
    @OwnerName NVARCHAR(100) = NULL,        
    @Name NVARCHAR(100),        
    @MobileNumber NVARCHAR(20),        
    @City NVARCHAR(100),        
    @State NVARCHAR(100),        
    @Email NVARCHAR(100),        
    @Pincode NVARCHAR(10),        
    @Segment NVARCHAR(50) = NULL,      
    @Brand NVARCHAR(500)  = null,    
 @compid varchar(100)  ,  
 @Refrence_Consumerid varchar(10)=''  ,
  @UserType varchar(10),
  @TotalCreditLimit varchar(10) = null,
  @DepositAmount varchar(10) = null
AS        
BEGIN        
    SET NOCOUNT ON;        
	
	IF (@TotalCreditLimit IS NULL OR LTRIM(RTRIM(@TotalCreditLimit)) = '')
        SET @TotalCreditLimit = '0';

    IF (@DepositAmount IS NULL OR LTRIM(RTRIM(@DepositAmount)) = '')
        SET @DepositAmount = '0';

    IF LEN(@MobileNumber) != 12        
    BEGIN        
        RAISERROR('Invalid mobile number. It must be exactly 12 digits (including country code).', 16, 1);        
        RETURN;        
    END        
    
    DECLARE @Password INT        
    DECLARE @User_ID VARCHAR(100)        
    DECLARE @M_ConsumerId BIGINT        

    IF NOT EXISTS (SELECT 1 FROM M_Consumer WHERE MobileNo = @MobileNumber)        
    BEGIN        
        SET @Password = CAST((RAND(CHECKSUM(NEWID())) * 90000 + 10000) AS INT)        
    
        EXEC GetCodeGenValue 'Consumer', @User_ID OUTPUT        
    
        INSERT INTO M_Consumer ([User_ID], [Password], MobileNo, Email, ConsumerName)        
        VALUES (@User_ID, @Password, @MobileNumber, @Email, @Name )        
    END        
    
    SELECT @M_ConsumerId = M_Consumerid FROM M_Consumer WHERE MobileNo = @MobileNumber        
    
    IF EXISTS (SELECT * FROM tbl_Vendorvisekycstatus WHERE M_ConsumerId = @M_ConsumerId and Comp_id = @compid)    
    BEGIN    
        UPDATE tbl_Vendorvisekycstatus     
        SET     
            Name = @Name,    
            UserCity = @City,    
            UserState = @State, 
			EmailId = @Email,
            UserPin = @Pincode,    
            Segmanet_name = @Segment,    
            Outlet_name = @OutletName,    
            Owner_name = @OwnerName,    
            BrandDetails = ISNULL(@Brand, '')  ,  
   Dealer_M_consumerid=@Refrence_Consumerid  ,
   Vrkabel_User_Type=@UserType
   
        WHERE M_ConsumerId = @M_ConsumerId and Comp_id=@compid   
		

		IF EXISTS (
        SELECT 1 FROM dealer_credit_limits 
        WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid
    )
    BEGIN
        UPDATE dealer_credit_limits
        SET
            total_credit_limit = CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            current_credit_limit = CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            last_updated_at = GETDATE(),
            remarks = 'Credit limit updated'
        WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid;
    END
    ELSE
    BEGIN
        INSERT INTO dealer_credit_limits (
            M_Consumerid, Comp_id, total_credit_limit, current_credit_limit,
            last_updated_at, remarks
        )
        VALUES (
            @M_ConsumerId, @compid,
            CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            GETDATE(), 'Initial credit limit assigned'
        );
    END


    IF EXISTS (
        SELECT 1 FROM dealer_security_deposits 
        WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid
    )
    BEGIN
        UPDATE dealer_security_deposits
        SET
            deposit_amount = CAST(@DepositAmount AS DECIMAL(12,2)),
            last_updated_at = GETDATE(),
            remarks = 'Deposit updated',
            deposit_date = GETDATE()
        WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid;
    END
    ELSE
    BEGIN
        INSERT INTO dealer_security_deposits (
            M_Consumerid, Comp_id, deposit_amount,
            deposit_date, last_updated_at, remarks
        )
        VALUES (
            @M_ConsumerId, @compid, 
            CAST(@DepositAmount AS DECIMAL(12,2)),
            GETDATE(), GETDATE(), 
            'Initial deposit'
        );
    END
    END    
    ELSE    
    BEGIN    
    IF EXISTS (SELECT 1 FROM tbl_Vendorvisekycstatus WHERE M_ConsumerId = @M_ConsumerId AND Comp_id = @compid)
    BEGIN
        UPDATE tbl_Vendorvisekycstatus
        SET
            Name = @Name,
            UserCity = @City,
            UserState = @State,
            EmailId = @Email,
            UserPin = @Pincode,
            Segmanet_name = @Segment,
            Outlet_name = @OutletName,
            Owner_name = @OwnerName,
            BrandDetails = ISNULL(@Brand, ''),
            Dealer_M_consumerid = @Refrence_Consumerid,
            Vrkabel_User_Type = @UserType
        WHERE M_ConsumerId = @M_ConsumerId AND Comp_id = @compid;
    END
    ELSE
    BEGIN
	    DECLARE @Reffralcode INT , @Finalreffral nvarchar(100);   
	
    SET @Reffralcode = CAST((RAND(CHECKSUM(NEWID())) * 90000000 + 10000000) AS INT);    
		set @Finalreffral=concat(@compid,@Reffralcode)
        INSERT INTO tbl_Vendorvisekycstatus (
            M_ConsumerId, Name, UserCity, UserState, MobileNo, EmailId,
            UserPin, Segmanet_name, Outlet_name, Owner_name, BrandDetails,
            Comp_id, Dealer_M_consumerid, Vrkabel_User_Type , Referral_Code
        )
        VALUES (
            @M_ConsumerId, @Name, @City, @State, @MobileNumber, @Email,
            @Pincode, @Segment, @OutletName, @OwnerName, @Brand,
            @compid, @Refrence_Consumerid, @UserType,@Finalreffral
        );
    END

    IF EXISTS (SELECT 1 FROM dealer_credit_limits WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid)
    BEGIN
        UPDATE dealer_credit_limits
        SET
            total_credit_limit = CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            current_credit_limit = CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            last_updated_at = GETDATE(),
            remarks = 'Credit limit updated'
        WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid;
    END
    ELSE
    BEGIN
        INSERT INTO dealer_credit_limits (
            M_Consumerid, Comp_id, total_credit_limit, current_credit_limit,
            last_updated_at, remarks
        )
        VALUES (
            @M_ConsumerId, @compid,
            CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            CAST(@TotalCreditLimit AS DECIMAL(12,2)),
            GETDATE(), 'Initial credit limit assigned'
        );
    END

    IF EXISTS (SELECT 1 FROM dealer_security_deposits WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid)
    BEGIN
        UPDATE dealer_security_deposits
        SET
            deposit_amount = CAST(@DepositAmount AS DECIMAL(12,2)),
            last_updated_at = GETDATE(),
            remarks = 'Deposit updated',
            deposit_date = GETDATE()
        WHERE M_Consumerid = @M_ConsumerId AND Comp_id = @compid;
    END
    ELSE
    BEGIN
        INSERT INTO dealer_security_deposits (
            M_Consumerid, Comp_id, deposit_amount,
            deposit_date, last_updated_at, remarks
        )
        VALUES (
            @M_ConsumerId, @compid, CAST(@DepositAmount AS DECIMAL(12,2)),
            GETDATE(), GETDATE(), 'Initial deposit'
        );
    END

    END    
END 
GO
