USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-22
-- Description: Get Label Print List with pagination and filters
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetLabelPrintList_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50) = NULL,
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @Offset INT,
    @Limit INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, SUM(Codes) Codes, pro_id, DownFl, Pro_Name, print_date, MAX(IsDispatched) AS IsDispatched, COUNT(*) OVER() as TotalRecords
        FROM (
            SELECT 
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MIN(MC.Series_Serial)) END) AS SerFr,
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Serial)) END) AS SerTo, 
                COUNT(MC.Row_ID) AS Codes,
                ISNULL(B.Display_Series, MC.Pro_ID) AS pro_id,
                MC.Pro_ID+'*'+ CONVERT(NVARCHAR,CAST(MC.Print_Date AS DATE),105)+'*'+MC.LabelRequestId AS DownFl,
                MAX(ISNULL(B.Display_Product, B.Pro_Name)) AS Pro_Name,
                CAST(MC.Print_Date AS DATE) AS print_date,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) AS IsDispatched
            FROM M_Code_PFL MC 
            LEFT JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
              AND B.Comp_ID = @Comp_ID 
              AND MC.Print_Date >= (SELECT TOP 1 Reg_Date FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1)
              AND (@Pro_ID IS NULL OR @Pro_ID = '' OR @Pro_ID = '0' OR MC.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR MC.Print_Date >= @DateFrom)
              AND (@DateTo IS NULL OR MC.Print_Date <= @DateTo)
            GROUP BY MC.Pro_ID, B.Display_Series, CAST(MC.Print_Date AS DATE), MC.LabelRequestId
        ) A 
        GROUP BY SerFr, SerTo, A.pro_id, DownFl, Pro_Name, print_date
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
    ELSE
    BEGIN
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, SUM(Codes) Codes, pro_id, DownFl, Pro_Name, print_date, MAX(IsDispatched) AS IsDispatched, COUNT(*) OVER() as TotalRecords
        FROM (
            SELECT 
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MIN(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MIN(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MIN(MC.Series_Serial)) END) AS SerFr,
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Order))) = 1 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Order)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 1 THEN  '000' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 2 THEN  '00' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) WHEN LEN(CONVERT(NUMERIC,MAX(MC.Series_Serial))) = 3 THEN  '0' + CONVERT(NVARCHAR,MAX(MC.Series_Serial)) ELSE CONVERT(NVARCHAR,MAX(MC.Series_Serial)) END) AS SerTo, 
                COUNT(MC.Row_ID) AS Codes,
                ISNULL(B.Display_Series, MC.Pro_ID) AS pro_id,
                MC.Pro_ID+'*'+ CONVERT(NVARCHAR,CAST(MC.Print_Date AS DATE),105)+'*'+MC.LabelRequestId AS DownFl,
                MAX(B.Pro_Name) AS Pro_Name,
                CAST(MC.Print_Date AS DATE) AS print_date,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) AS IsDispatched
            FROM M_Code MC 
            LEFT JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
              AND B.Comp_ID = @Comp_ID 
              AND MC.Print_Date >= (SELECT TOP 1 Reg_Date FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1)
              AND (@Pro_ID IS NULL OR @Pro_ID = '' OR @Pro_ID = '0' OR MC.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR MC.Print_Date >= @DateFrom)
              AND (@DateTo IS NULL OR MC.Print_Date <= @DateTo)
            GROUP BY MC.Pro_ID, B.Display_Series, CAST(MC.Print_Date AS DATE), MC.LabelRequestId
        ) A 
        GROUP BY SerFr, SerTo, A.pro_id, DownFl, Pro_Name, print_date
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
END
GO
