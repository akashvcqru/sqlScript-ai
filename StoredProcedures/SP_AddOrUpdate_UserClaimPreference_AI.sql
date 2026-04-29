ALTER PROCEDURE [dbo].[SP_AddOrUpdate_UserClaimPreference_AI]  
(  
    @M_Consumerid INT,  
    @Comp_Id VARCHAR(20),  
    @ClaimMode VARCHAR(20)  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  

    IF EXISTS (SELECT 1 FROM UserClaimPreferences WHERE M_Consumerid = @M_Consumerid AND Comp_Id = @Comp_Id)
    BEGIN
        UPDATE UserClaimPreferences 
        SET ClaimMode = @ClaimMode
        WHERE M_Consumerid = @M_Consumerid AND Comp_Id = @Comp_Id;
    END
    ELSE
    BEGIN
        INSERT INTO UserClaimPreferences (M_Consumerid, Comp_Id, ClaimMode)  
        VALUES (@M_Consumerid, @Comp_Id, @ClaimMode);  
    END
END
