CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeLabelPrintList_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Offset INT = 0,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Optimized query structure based on fast query performance requirements
    IF @Comp_ID = 'Comp-1693'
    BEGIN
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, SUM(Codes) Codes, pro_id, DownFl, Comp_Name, Pro_Name, print_date, COUNT(*) OVER() as TotalRecords
        FROM (
            SELECT 
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MIN(MC.Series_Serial)) END) AS SerFr,
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Serial)) END) AS SerTo, 
                COUNT(MC.Row_ID) AS Codes,
                ISNULL(B.Display_Series, MC.Pro_ID) AS pro_id,
                MC.Pro_ID+'*'+ CONVERT(NVARCHAR,CAST(MC.Print_Date AS DATE),105)+'*'+MC.LabelRequestId AS DownFl,
                (SELECT Comp_Name FROM Comp_Reg WHERE Comp_ID = (SELECT TOP 1 Comp_ID FROM Pro_Reg WHERE Pro_ID = MC.Pro_ID)) AS Comp_Name,
                (SELECT TOP 1 ISNULL(Display_Product, Pro_Name) FROM Pro_Reg WHERE Pro_ID = MC.Pro_ID) AS Pro_Name,
                CAST(MC.Print_Date AS DATE) AS print_date
            FROM M_Code_PFL MC 
            LEFT JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
            AND (@Comp_ID IS NULL OR B.Comp_ID = @Comp_ID)
            AND (@Pro_ID IS NULL OR @Pro_ID = '0' OR MC.Pro_ID = @Pro_ID)
            AND (@FromDate IS NULL OR MC.Print_Date >= @FromDate)
            AND (@ToDate IS NULL OR MC.Print_Date <= @ToDate)
            GROUP BY MC.Pro_ID, B.Display_Series, CAST(MC.Print_Date AS DATE), MC.LabelRequestId
        ) A 
        GROUP BY SerFr, SerTo, A.pro_id, DownFl, Comp_Name, Pro_Name, print_date
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
    ELSE
    BEGIN
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, SUM(Codes) Codes, pro_id, DownFl, Comp_Name, Pro_Name, print_date, COUNT(*) OVER() as TotalRecords
        FROM (
            SELECT 
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MIN(MC.Series_Serial)) END) AS SerFr,
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Serial)) END) AS SerTo, 
                COUNT(MC.Row_ID) AS Codes,
                ISNULL(B.Display_Series, MC.Pro_ID) AS pro_id,
                MC.Pro_ID+'*'+ CONVERT(NVARCHAR,CAST(MC.Print_Date AS DATE),105)+'*'+MC.LabelRequestId AS DownFl,
                (SELECT Comp_Name FROM Comp_Reg WHERE Comp_ID = (SELECT TOP 1 Comp_ID FROM Pro_Reg WHERE Pro_ID = MC.Pro_ID)) AS Comp_Name,
                (SELECT TOP 1 Pro_Name FROM Pro_Reg WHERE Pro_ID = MC.Pro_ID) AS Pro_Name,
                CAST(MC.Print_Date AS DATE) AS print_date
            FROM M_Code MC 
            LEFT JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
            AND (@Comp_ID IS NULL OR B.Comp_ID = @Comp_ID)
            AND (@Pro_ID IS NULL OR @Pro_ID = '0' OR MC.Pro_ID = @Pro_ID)
            AND (@FromDate IS NULL OR MC.Print_Date >= @FromDate)
            AND (@ToDate IS NULL OR MC.Print_Date <= @ToDate)
            GROUP BY MC.Pro_ID, B.Display_Series, CAST(MC.Print_Date AS DATE), MC.LabelRequestId
        ) A 
        GROUP BY SerFr, SerTo, A.pro_id, DownFl, Comp_Name, Pro_Name, print_date
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
END
GO
