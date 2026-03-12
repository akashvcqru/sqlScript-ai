-- =============================================
-- Procedure: USP_GetLabelList_AI
-- Description: Fetch active labels from M_Label table
-- Called from: ProductController.cs -> GET /api/vendor/products/labelList
-- =============================================
IF OBJECT_ID('USP_GetLabelList_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetLabelList_AI
GO

CREATE PROCEDURE USP_GetLabelList_AI
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Row_Id, 
        Label_Code, 
        Label_Name, 
        Label_Size, 
        Label_Prise,
        Label_Image, 
        Entry_Date, 
        Flag,
        (Label_Name + ' ( ' + Label_Size + ' )') as Label_NameC,
        (CASE WHEN Flag = 1 THEN 'Status of this Label is Activated.' ELSE 'Status of this Label is De-activated.' END) as TooTipMsg
    FROM M_Label
    WHERE Flag = 1;
END
GO
