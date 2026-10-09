USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[GetProductCatalog_AI]          
(          
@comp_id nvarchar(50)          
)          
as          
begin          
SELECT d.Row_Id, d.CategoryId, p.CategoryName, d.ProductName, d.SubCategory, d.ProductDescription, 
       d.Point, d.Price, d.StockQuantity, d.Isactive, d.IsSalable, d.DiscountPrice, d.IsVariable,
       d.ImagePath, d.ImagePath2, d.ImagePath3, d.ImagePath4, d.ImagePath5, d.CreatedDate,
       (SELECT Color, Size FROM Product_Variants v WHERE v.ProductCatalogId = d.Row_Id AND (v.IsDelete = 0 OR v.IsDelete IS NULL) FOR JSON PATH) as Variants
FROM Products_catalog_Details d
INNER JOIN Products_Category p ON d.CategoryId = p.CategoryId 
WHERE d.Comp_id = @comp_id AND d.Isactive = 1 AND d.Isdelete = 0 AND p.Isdelete = 0
ORDER BY d.CreatedDate DESC
end
GO
-- end