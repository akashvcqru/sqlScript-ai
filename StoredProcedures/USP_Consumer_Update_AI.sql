USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_Consumer_Update_AI]        
    @OutletName NVARCHAR(100) = NULL,        
    @OwnerName NVARCHAR(100) = NULL,        
    @Name NVARCHAR(100),        
    @EmailId NVARCHAR(100),        
    @MobileNumber NVARCHAR(20),        
    @City NVARCHAR(100),        
    @State NVARCHAR(100),        
    @Pincode NVARCHAR(10),   
	@IsActive BIT,
    @Segment NVARCHAR(50) = NULL  ,      
 @M_consumerid bigint   ,    
 @Brand nvarchar(500) = null ,  
 @CompId varchar(100)  ,
  @UserType varchar(10),
  @CrrentCreditLimit varchar(10) = null,
  @DepositAmount varchar(10) = null
AS        
BEGIN        
    SET NOCOUNT ON;  
	SET @CrrentCreditLimit = ISNULL(@CrrentCreditLimit, '0');
SET @DepositAmount = ISNULL(@DepositAmount, '0');

        declare @MsgD varchar(20) = '',
                @MsgC varchar(20) = '',
                @Diff DECIMAL(18,2);

    IF LEN(@MobileNumber) != 12        
    BEGIN        
        RAISERROR('Invalid mobile number. It must be exactly 12 digits (including country code).', 16, 1);        
        RETURN;        
    END        
        
 if not exists ( select*from M_Consumer where mobileno=@MobileNumber)        
  BEGIN        
        RAISERROR('Invalid mobile number. It must be exactly 12 digits (including country code).', 16, 1);        
        RETURN;        
    END        
 begin        
        
         
  Update M_Consumer set ConsumerName=@Name,City=@City,State=@State,Pincode=@Pincode,Email = @EmailId   
  where M_Consumerid=@M_consumerid   ;  
        
     Update tbl_Vendorvisekycstatus set Name=@Name,usercity=@City,userstate=@State,userpin=@Pincode,Outlet_name=@OutletName,Owner_name=@OwnerName, 
  Segmanet_name=@Segment,Branddetails=ISNULL(@Brand, '')   , IsActive = @IsActive, EmailId = @EmailId
  where M_consumerId=@M_consumerid and Comp_id=@CompId;  
        
		-- Update or Insert into dealer_credit_limits
         IF EXISTS (
             SELECT 1 FROM dealer_credit_limits 
             WHERE M_Consumerid = @M_consumerid AND Comp_id = @CompId
         )
         BEGIN
             set @MsgC = 'Updated by backend'
			 SELECT @Diff = total_credit_limit - current_credit_limit 
             FROM dealer_credit_limits 
             WHERE M_Consumerid = @M_consumerid AND Comp_id = @CompId;
         END
         ELSE
         BEGIN
             set @MsgC = 'Initial credit limit assigned'
			 set @Diff = 0
         END
         

		 INSERT INTO dealer_credit_limits (
                 M_Consumerid, Comp_id, total_credit_limit, current_credit_limit, last_updated_at, remarks
             )
             VALUES (
                 @M_consumerid, 
                 @CompId, 
                 CAST(@CrrentCreditLimit AS DECIMAL(12,2)), 
                 CAST(@CrrentCreditLimit AS DECIMAL(12,2)) - @Diff,
                 GETDATE(), 
                 @MsgC
             );
         -- Update or Insert into dealer_security_deposits
         IF EXISTS (
             SELECT 1 FROM dealer_security_deposits 
             WHERE M_Consumerid = @M_consumerid AND Comp_id = @CompId
         )
         BEGIN
            set @MsgD = 'Updated by backend'
         END
         ELSE
         BEGIN
            set @MsgD = 'Initial deposit'
         END

          INSERT INTO dealer_security_deposits (
                 M_Consumerid, Comp_id, deposit_amount, deposit_date, last_updated_at, remarks
             )
             VALUES (
                 @M_consumerid, 
                 @CompId, 
                 CAST(@DepositAmount AS DECIMAL(12,2)), 
                 GETDATE(), 
                 GETDATE(), 
                 @MsgD
             );
END        
END
GO
