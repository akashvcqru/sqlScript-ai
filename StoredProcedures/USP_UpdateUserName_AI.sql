CREATE PROCEDURE [dbo].[USP_UpdateUserName_AI]      
    @MobileNo VARCHAR(20),    
    @Name     VARCHAR(200)      
AS      
BEGIN      
    UPDATE M_Consumer   
    SET ConsumerName = @Name   
    WHERE mobileno = @MobileNo  
END
