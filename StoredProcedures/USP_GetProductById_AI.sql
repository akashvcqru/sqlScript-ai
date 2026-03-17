-- =============================================
-- Procedure: USP_GetProductById_AI
-- Description: Returns details for a single product by ID
-- Called from: ProductController.cs -> GET /api/vendor/products/GetProductById/{id}
-- =============================================
IF OBJECT_ID('USP_GetProductById_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetProductById_AI
GO

CREATE PROCEDURE USP_GetProductById_AI
    @Comp_ID NVARCHAR(50),
    @Pro_ID  NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        1                                                     AS TotalRecords, -- Not used for single item but kept for consistency with DTO mapping if needed
        1                                                     AS SNo,
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
        ISNULL(pr.BatchSize, 0)                               AS BatchSize,
        ISNULL(pr.Dispatch_Location, '')                      AS Dispatch_Location,
        -- Correctly construct ImgPath (matching logic from GetProductList)
        (SELECT TOP 1 [PrPrefix] FROM [Code_Gen] WHERE [Prfor] = 'Product') + pr.Pro_ID + '.jpg' AS ImgPath -- This is a placeholder, usually it's just Pro_ID + extension
    FROM   Pro_Reg pr
    LEFT JOIN M_Label ml ON pr.Label_Code = ml.Label_Code
    WHERE
        pr.Comp_ID = @Comp_ID
        AND pr.Pro_ID = @Pro_ID;
END
GO
