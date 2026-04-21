CREATE PROCEDURE [dbo].[SP_AddOrUpdate_UserClaimPreference_AI]  
(  
    @M_Consumerid INT,  
    @Comp_Id VARCHAR(20),  
    @ClaimMode VARCHAR(20)  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
        INSERT INTO UserClaimPreferences (M_Consumerid, Comp_Id, ClaimMode)  
        VALUES (@M_Consumerid, @Comp_Id, @ClaimMode);  
END
