-- =============================================
-- Procedure: USP_GetLabels_AI
-- Description: Returns all active labels for the "Choose Labels" radio list
-- Called from: ProductController.cs -> GET /api/vendor/products/labels
-- =============================================
IF OBJECT_ID('USP_GetLabels_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetLabels_AI
GO

CREATE PROCEDURE USP_GetLabels_AI
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Label_Code,
        Label_Name,
        Label_Size,
        ISNULL(Label_Prise, 0)  AS Label_Prise,
        ISNULL(Label_Image, '') AS Label_Image
    FROM M_Label
    WHERE Flag = 1
    ORDER BY Label_Name;
END
GO
