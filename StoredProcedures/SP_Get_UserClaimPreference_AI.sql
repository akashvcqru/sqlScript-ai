CREATE PROCEDURE [dbo].[SP_Get_UserClaimPreference_AI]  
(  
    @M_Consumerid INT,  
    @Comp_Id VARCHAR(20)  
)  
AS  
BEGIN  
    SELECT top 1 ClaimMode  
    FROM UserClaimPreferences  
    WHERE M_Consumerid = @M_Consumerid  
      AND Comp_Id = @Comp_Id order by Created_At desc;  
END
