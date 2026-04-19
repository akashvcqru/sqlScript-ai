USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetUserKycDetails_BL_AI]    
    @ConsumerId INT      
AS    
BEGIN    
    SELECT     
        mc.ConsumerName,    
        UPIId,    
        aadharNumber,    
        AadharHolderName,     
        m.Bank_Name,    
        m.Account_HolderNm,    
        m.Account_No,    
        m.IFSC_Code,    
        pancard_number    
    FROM     
        M_Consumer mc    
    LEFT JOIN     
        M_BankAccount m ON m.M_Consumerid = mc.M_Consumerid    
    WHERE     
        mc.M_Consumerid = @ConsumerId    
END 
GO
