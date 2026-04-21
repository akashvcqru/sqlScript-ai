CREATE PROCEDURE [dbo].[SP_GetDuesDetails_AI]        
    @UserId VARCHAR(20)     
AS        
BEGIN        
select *  from vw_InvoiceSummary where Dealerid = @UserId  
END
