-- =============================================
-- Procedure: USP_GetLabels
-- Description: Returns all active labels for the "Choose Labels" radio list
-- Called from: ProductController.cs -> GET /api/vendor/products/labels
-- Mirrors: Data_9420.FillGridLabel / function9420.FillGridLabel
-- =============================================
IF OBJECT_ID('USP_GetLabels', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetLabels
GO

CREATE PROCEDURE USP_GetLabels
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Label_Code,
        Label_Name,
        Label_Size,
        ISNULL(Label_Prise, 0)  AS Label_Prise,
        Label_Image,
        Label_Width,
        Label_Height
    FROM M_Label
    WHERE Flag = 1
    ORDER BY Label_Name;
END
GO
