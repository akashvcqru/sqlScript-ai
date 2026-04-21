CREATE PROCEDURE [dbo].[PROC_GetDepositHistory_AI]  
    @UserId INT  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
 select a.M_Consumerid, a.Comp_id, a.deposit_amount, a.deposit_date, a.last_updated_at, a.remarks, b.Comp_Name from dealer_security_deposits a  
 inner join comp_reg b on a.comp_id = b.comp_id where M_Consumerid = @UserId order by last_updated_at desc   
END
