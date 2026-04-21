CREATE PROCEDURE [dbo].[PROC_GetSubCategories_AI]  
    @CategoryId INT  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
  select SubCategory from Products_catalog_Details  where CategoryId = @CategoryId and  IsSalable = 1 and Isactive = 1 and Isdelete = 0  and SubCategory is not NULL group by SubCategory   
  
END
