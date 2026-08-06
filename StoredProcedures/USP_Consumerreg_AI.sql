USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_Consumerreg_AI]        
    @MobileNo NVARCHAR(50),        
    @Password NVARCHAR(50),        
    @Entry_Date DATETIME = NULL,        
    @IsActive BIT,        
    @IsDelete BIT,     
	@Comp_id nvarchar(100)=null,
	@Addedfrom INT = NULL,
    @User_ID NVARCHAR(50) OUTPUT,        
    @M_Consumerid NVARCHAR(50) OUTPUT        
AS        
BEGIN        
    SET NOCOUNT ON;        
    DECLARE @Reffralcode INT, @Finalreffral nvarchar(100);   
	DECLARE @IsKYCRequired BIT;

    SELECT @IsKYCRequired = CASE WHEN COALESCE(JSON_VALUE(kyc_Details, '$.0.Iskycrequired'), JSON_VALUE(kyc_Details, '$.Iskycrequired')) = 'True' THEN 1 ELSE 0 END
    FROM BrandSettings_AI WHERE Comp_ID = @Comp_id;
         
    SET @Reffralcode = CAST((RAND(CHECKSUM(NEWID())) * 90000000 + 10000000) AS INT);    
    SET @Finalreffral = CONCAT(@Comp_id, @Reffralcode);
      
    EXEC GetCodeGenValue 'Consumer', @User_ID OUTPUT;        
       
    INSERT INTO [M_Consumer]       
        ([User_ID],[Comp_ID], MobileNo, [Password], [Entry_Date], [IsActive], [IsDelete], Addedfrom)        
    VALUES       
        (@User_ID, @Comp_id, @MobileNo, @Password, ISNULL(@Entry_Date, GETDATE()), @IsActive, @IsDelete, @Addedfrom);        
      
    SET @M_Consumerid = CAST(SCOPE_IDENTITY() AS NVARCHAR(50));     
	
    INSERT INTO tbl_Vendorvisekycstatus (M_consumerId, Comp_id, Referral_Code) 
    VALUES (@M_Consumerid, @Comp_id, @Finalreffral);
END;
GO
