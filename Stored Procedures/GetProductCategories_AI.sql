USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[GetProductCategories_AI]          
(          
@comp_id nvarchar(50)          
)          
as          
begin          
SELECT CategoryId, CategoryName, CategoryDescription, Point, Price, StockQuantity, ImagePath, CreatedDate 
FROM Products_Category 
WHERE Comp_id = @comp_id AND Isactive = 1 AND Isdelete = 0 
ORDER BY CreatedDate DESC
end
GO
