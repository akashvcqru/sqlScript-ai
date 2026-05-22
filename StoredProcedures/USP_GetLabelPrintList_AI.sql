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
        ;WITH RawData AS (
            SELECT 
                MC.Pro_ID,
                MC.Series_Order,
                MC.Series_Serial,
                MC.Print_Date,
                MC.LabelRequestId,
                MC.DispatchFlag,
                MC.Row_ID,
                B.Display_Series,
                ISNULL(B.Display_Product, B.Pro_Name) AS Pro_Name,
                ROW_NUMBER() OVER (PARTITION BY MC.LabelRequestId, MC.Pro_ID ORDER BY MC.Series_Order ASC, MC.Series_Serial ASC) AS rn_start,
                ROW_NUMBER() OVER (PARTITION BY MC.LabelRequestId, MC.Pro_ID ORDER BY MC.Series_Order DESC, MC.Series_Serial DESC) AS rn_end
            FROM M_Code_PFL MC 
            LEFT JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
              AND B.Comp_ID = @Comp_ID 
              AND MC.Print_Date >= (SELECT TOP 1 Reg_Date FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1)
              AND (@Pro_ID IS NULL OR @Pro_ID = '' OR @Pro_ID = '0' OR MC.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR MC.Print_Date >= @DateFrom)
              AND (@DateTo IS NULL OR MC.Print_Date <= @DateTo)
        ),
        Aggregated AS (
            SELECT 
                MC.Pro_ID,
                MC.LabelRequestId,
                MAX(CASE WHEN rn_start = 1 THEN MC.Series_Order END) AS StartOrder,
                MAX(CASE WHEN rn_start = 1 THEN MC.Series_Serial END) AS StartSerial,
                MAX(CASE WHEN rn_end = 1 THEN MC.Series_Order END) AS EndOrder,
                MAX(CASE WHEN rn_end = 1 THEN MC.Series_Serial END) AS EndSerial,
                COUNT(MC.Row_ID) AS Codes,
                ISNULL(MC.Display_Series, MC.Pro_ID) AS Display_Pro_ID,
                MAX(MC.Pro_Name) AS Pro_Name,
                CAST(MAX(MC.Print_Date) AS DATE) AS Print_Date,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) AS IsDispatched
            FROM RawData MC
            GROUP BY MC.Pro_ID, MC.Display_Series, MC.LabelRequestId
        )
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, SUM(Codes) Codes, pro_id, DownFl, Pro_Name, print_date, MAX(IsDispatched) AS IsDispatched, COUNT(*) OVER() as TotalRecords
        FROM (
            SELECT 
                -- Format SerFr
                CONVERT(NVARCHAR, A.Pro_ID) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartOrder, 0))) = 1 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.StartOrder, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.StartOrder, 0)) END) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartSerial, 0))) = 1 THEN '000' + CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartSerial, 0))) = 2 THEN '00' + CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartSerial, 0))) = 3 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) END) AS SerFr,
                -- Format SerTo
                CONVERT(NVARCHAR, A.Pro_ID) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndOrder, 0))) = 1 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.EndOrder, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.EndOrder, 0)) END) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndSerial, 0))) = 1 THEN '000' + CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndSerial, 0))) = 2 THEN '00' + CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndSerial, 0))) = 3 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) END) AS SerTo,
                A.Codes,
                A.Display_Pro_ID AS pro_id,
                A.Pro_ID + '*' + CONVERT(NVARCHAR, A.Print_Date, 105) + '*' + A.LabelRequestId AS DownFl,
                A.Pro_Name,
                A.Print_Date AS print_date,
                A.IsDispatched
            FROM Aggregated A
        ) InnerA
        GROUP BY SerFr, SerTo, InnerA.pro_id, DownFl, Pro_Name, print_date
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
    ELSE
    BEGIN
        ;WITH RawData AS (
            SELECT 
                MC.Pro_ID,
                MC.Series_Order,
                MC.Series_Serial,
                MC.Print_Date,
                MC.LabelRequestId,
                MC.DispatchFlag,
                MC.Row_ID,
                B.Display_Series,
                B.Pro_Name,
                ROW_NUMBER() OVER (PARTITION BY MC.LabelRequestId, MC.Pro_ID ORDER BY MC.Series_Order ASC, MC.Series_Serial ASC) AS rn_start,
                ROW_NUMBER() OVER (PARTITION BY MC.LabelRequestId, MC.Pro_ID ORDER BY MC.Series_Order DESC, MC.Series_Serial DESC) AS rn_end
            FROM M_Code MC 
            LEFT JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
              AND B.Comp_ID = @Comp_ID 
              AND MC.Print_Date >= (SELECT TOP 1 Reg_Date FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1)
              AND (@Pro_ID IS NULL OR @Pro_ID = '' OR @Pro_ID = '0' OR MC.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR MC.Print_Date >= @DateFrom)
              AND (@DateTo IS NULL OR MC.Print_Date <= @DateTo)
        ),
        Aggregated AS (
            SELECT 
                MC.Pro_ID,
                MC.LabelRequestId,
                MAX(CASE WHEN rn_start = 1 THEN MC.Series_Order END) AS StartOrder,
                MAX(CASE WHEN rn_start = 1 THEN MC.Series_Serial END) AS StartSerial,
                MAX(CASE WHEN rn_end = 1 THEN MC.Series_Order END) AS EndOrder,
                MAX(CASE WHEN rn_end = 1 THEN MC.Series_Serial END) AS EndSerial,
                COUNT(MC.Row_ID) AS Codes,
                ISNULL(MC.Display_Series, MC.Pro_ID) AS Display_Pro_ID,
                MAX(MC.Pro_Name) AS Pro_Name,
                CAST(MAX(MC.Print_Date) AS DATE) AS Print_Date,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) AS IsDispatched
            FROM RawData MC
            GROUP BY MC.Pro_ID, MC.Display_Series, MC.LabelRequestId
        )
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, SUM(Codes) Codes, pro_id, DownFl, Pro_Name, print_date, MAX(IsDispatched) AS IsDispatched, COUNT(*) OVER() as TotalRecords
        FROM (
            SELECT 
                -- Format SerFr
                CONVERT(NVARCHAR, A.Pro_ID) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartOrder, 0))) = 1 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.StartOrder, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.StartOrder, 0)) END) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartSerial, 0))) = 1 THEN '000' + CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartSerial, 0))) = 2 THEN '00' + CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.StartSerial, 0))) = 3 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.StartSerial, 0)) END) AS SerFr,
                -- Format SerTo
                CONVERT(NVARCHAR, A.Pro_ID) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndOrder, 0))) = 1 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.EndOrder, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.EndOrder, 0)) END) + '-' + 
                (CASE WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndSerial, 0))) = 1 THEN '000' + CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndSerial, 0))) = 2 THEN '00' + CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) WHEN LEN(CONVERT(NUMERIC, ISNULL(A.EndSerial, 0))) = 3 THEN '0' + CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) ELSE CONVERT(NVARCHAR, ISNULL(A.EndSerial, 0)) END) AS SerTo,
                A.Codes,
                A.Display_Pro_ID AS pro_id,
                A.Pro_ID + '*' + CONVERT(NVARCHAR, A.Print_Date, 105) + '*' + A.LabelRequestId AS DownFl,
                A.Pro_Name,
                A.Print_Date AS print_date,
                A.IsDispatched
            FROM Aggregated A
        ) InnerA
        GROUP BY SerFr, SerTo, InnerA.pro_id, DownFl, Pro_Name, print_date
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
END
GO
