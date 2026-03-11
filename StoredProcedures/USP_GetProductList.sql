-- =============================================
-- Procedure: USP_GetProductList
-- Description: Returns product list for a company (Register Products report)
-- Called from: ProductController.cs -> GET /api/vendor/products/productList
-- Mirrors logic from: Data_9420.FetchSearchData()
-- Columns match the "Register Products" grid screenshot:
--   S.No, Product Name, Label Name, Price/Label, Description, Sound File, Status
-- =============================================
IF OBJECT_ID('USP_GetProductList', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetProductList
GO

CREATE PROCEDURE USP_GetProductList
    @Comp_ID    NVARCHAR(50) = '',
    @Pro_Name   NVARCHAR(200) = ''
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ROW_NUMBER() OVER (ORDER BY pr.Pro_Entry_Date DESC)  AS SNo,
        pr.Pro_ID,
        pr.Pro_Name,
        ISNULL(
            CONVERT(NVARCHAR, ml.Label_Name) + ' ( ' + ml.Label_Size + ' )',
            'N/A'
        )                                                     AS LabelName,
        ISNULL(ml.Label_Prise, 0)                             AS RatePerLabel,
        CASE
            WHEN ISNULL(pr.Pro_Desc, '') = '' THEN '---'
            ELSE pr.Pro_Desc
        END                                                   AS ProDesc,
        '../Data/Sound/'
            + SUBSTRING(pr.Comp_ID, 6, 4)
            + '/' + pr.Pro_ID
            + '/' + pr.Pro_ID + '.mp3'                        AS SoundPath,
        CASE
            WHEN pr.Doc_Flag = 1 AND pr.Sound_Flag = 1 THEN 'Verified'
            ELSE 'Pending'
        END                                                   AS Status,
        pr.Pro_Entry_Date,
        pr.Label_Code,
        pr.BatchSize,
        pr.Dispatch_Location
    FROM   Pro_Reg pr
    LEFT JOIN M_Label ml ON pr.Label_Code = ml.Label_Code
    WHERE
        ('' = @Comp_ID OR pr.Comp_ID = @Comp_ID)
        AND pr.Pro_Name LIKE '%' + @Pro_Name + '%'
    ORDER BY pr.Pro_Entry_Date DESC;
END
GO
