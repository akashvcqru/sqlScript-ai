IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_GetCodesByBatchID_V2_AI]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_GetCodesByBatchID_V2_AI]
GO

CREATE PROCEDURE [dbo].[USP_GetCodesByBatchID_V2_AI]
    @Pro_ID NVARCHAR(50),
    @Series_Order INT,
    @Series_From INT,
    @Series_To INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT row_number() OVER (ORDER BY Excel.Series_Name) AS SNO, * 
    FROM (
        SELECT 
            Pro_ID + '-' + 
            (CASE WHEN LEN(CONVERT(NVARCHAR, Series_Order)) = 1 THEN '0' + CONVERT(NVARCHAR, Series_Order) ELSE CONVERT(NVARCHAR, Series_Order) END) + '-' + 
            (CASE 
                WHEN LEN(CONVERT(NVARCHAR, Series_Serial)) = 1 THEN '000' + CONVERT(NVARCHAR, Series_Serial) 
                WHEN LEN(CONVERT(NVARCHAR, Series_Serial)) = 2 THEN '00' + CONVERT(NVARCHAR, Series_Serial) 
                WHEN LEN(CONVERT(NVARCHAR, Series_Serial)) = 3 THEN '0' + CONVERT(NVARCHAR, Series_Serial) 
                ELSE CONVERT(NVARCHAR, Series_Serial) 
            END) AS Series_Name,
            Code1,
            ' ' AS Mark_Scrap
        FROM M_Code
        WHERE Pro_ID = @Pro_ID 
          AND Print_Status = 1 
          AND Series_Order = @Series_Order 
          AND Series_Serial >= @Series_From 
          AND Series_Serial <= @Series_To
    ) AS Excel;
END
GO
