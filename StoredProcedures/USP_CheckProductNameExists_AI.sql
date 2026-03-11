-- =============================================
-- Procedure: USP_CheckProductNameExists_AI
-- Description: Checks if a product name already exists for a company
-- Called from: ProductController.cs -> GET /api/vendor/products/checkName
-- =============================================
IF OBJECT_ID('USP_CheckProductNameExists_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_CheckProductNameExists_AI
GO

CREATE PROCEDURE USP_CheckProductNameExists_AI
    @Comp_ID  NVARCHAR(50),
    @Pro_Name NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Pro_Reg
        WHERE Comp_ID = @Comp_ID
          AND Pro_Name = @Pro_Name
    )
        SELECT 1 AS [Exists];
    ELSE
        SELECT 0 AS [Exists];
END
GO
