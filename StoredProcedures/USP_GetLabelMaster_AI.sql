-- =============================================
-- Procedure: USP_GetLabelMaster_AI
-- Description: Fetch active labels (Code, Name, Size) from M_Label table
-- Called from: VendorController.cs -> GET /api/vendor/labels/LabelMaster
-- =============================================
IF OBJECT_ID('USP_GetLabelMaster_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetLabelMaster_AI
GO

CREATE PROCEDURE USP_GetLabelMaster_AI
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Label_Code, 
        Label_Name, 
        Label_Size
    FROM M_Label
    WHERE Flag = 1;
END
GO
