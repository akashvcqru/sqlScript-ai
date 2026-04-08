USE [VCQRU]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetCodeLabelPrintList_AI]    Script Date: 08-04-2026 16:20:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECT_ID('[dbo].[USP_GetCodeLabelPrintList_AI]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[USP_GetCodeLabelPrintList_AI];
END
GO
-- =============================================
-- Author:      Antigravity AI
-- Create date: 08-04-2026
-- Description: Optimized list of printed code labels with mandatory baseline filters and pagination.
-- =============================================
CREATE PROCEDURE [dbo].[USP_GetCodeLabelPrintList_AI]
    @CompID NVARCHAR(50),
    @ProID NVARCHAR(50) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Offset INT = 0,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Fetch Company Baseline Info
    DECLARE @CompName NVARCHAR(100);
    DECLARE @RegDate DATETIME;

    SELECT TOP 1 @CompName = Comp_Name, @RegDate = Reg_Date 
    FROM Comp_Reg 
    WHERE Comp_ID = @CompID AND Status = 1;

    -- If company is missing or inactive, return empty result set
    IF @CompName IS NULL
    BEGIN
        SELECT NULL AS ID, NULL AS SerFr, NULL AS SerTo, NULL AS Printed_Codes, NULL AS pro_id, NULL AS DownFl, NULL AS Comp_Name, NULL AS Pro_Name, NULL AS print_date, 0 AS TotalRecords WHERE 1=0;
        RETURN;
    END

    -- 2. Handle Default Date Filters
    IF @FromDate IS NULL AND @ToDate IS NULL
    BEGIN
        SET @FromDate = DATEADD(DAY, -90, GETDATE());
    END

    -- Apply Company Registration Date as a mandatory floor for FromDate
    IF @RegDate IS NOT NULL AND (@FromDate IS NULL OR @FromDate < @RegDate)
    BEGIN
        SET @FromDate = @RegDate;
    END

    -- Ensure RegDate baseline is respected even if specific FromDate is provided
    DECLARE @BaselineDate DATETIME = ISNULL(@RegDate, '1900-01-01');

    -- 3. Execute Query based on Table Selection (M_Code vs M_Code_PFL)
    IF @CompID = 'Comp-1693'
    BEGIN
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, Printed_Codes, pro_id, DownFl, @CompName AS Comp_Name, Pro_Name, print_date,
        COUNT(*) OVER() AS TotalRecords
        FROM (
            SELECT 
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,max(Series_Order))) = 1 THEN '0' + CONVERT(NVARCHAR,max(Series_Order)) ELSE CONVERT(NVARCHAR,max(Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,min(Series_Serial))) = 1 THEN '000' + CONVERT(NVARCHAR,min(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,min(Series_Serial))) = 2 THEN '00' + CONVERT(NVARCHAR,min(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,min(Series_Serial))) = 3 THEN '0' + CONVERT(NVARCHAR,min(Series_Serial)) ELSE CONVERT(NVARCHAR,min(Series_Serial)) END) AS SerFr,
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,max(Series_Order))) = 1 THEN '0' + CONVERT(NVARCHAR,max(Series_Order)) ELSE CONVERT(NVARCHAR,max(Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,max(Series_Serial))) = 1 THEN '000' + CONVERT(NVARCHAR,max(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,max(Series_Serial))) = 2 THEN '00' + CONVERT(NVARCHAR,max(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,max(Series_Serial))) = 3 THEN '0' + CONVERT(NVARCHAR,max(Series_Serial)) ELSE CONVERT(NVARCHAR,max(Series_Serial)) END) AS SerTo,
                COUNT(MC.Row_ID) AS Printed_Codes,
                isnull(B.Display_Series,MC.Pro_ID) pro_id,
                MC.Pro_ID+'*'+ convert(nvarchar,CAST(Print_Date AS DATE),105)+'*'+LabelRequestId as DownFl,
                ISNULL(B.Pro_Name, 'N/A') as Pro_Name,
                CAST(Print_Date AS DATE) print_date 
            FROM M_Code_PFL MC WITH (NOLOCK)
            INNER JOIN Pro_Reg B WITH (NOLOCK) on MC.Pro_ID = B.Pro_ID 
            WHERE MC.[Use_Type]='L' 
            AND B.Comp_ID = @CompID
            AND (@ProID IS NULL OR MC.Pro_ID = @ProID OR @ProID = '0' OR @ProID = 'string')
            AND (MC.Print_Date >= @FromDate)
            AND (@ToDate IS NULL OR MC.Print_Date <= @ToDate)
            AND (MC.Print_Date >= @BaselineDate)
            GROUP BY MC.Pro_ID, B.Display_Series, CAST(Print_Date AS DATE), LabelRequestId, B.Pro_Name
        ) FinalA 
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
    ELSE
    BEGIN
        SELECT ROW_NUMBER() OVER(ORDER BY print_date ASC) ID, SerFr, SerTo, Printed_Codes, pro_id, DownFl, @CompName AS Comp_Name, Pro_Name, print_date,
        COUNT(*) OVER() AS TotalRecords
        FROM (
            SELECT 
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,max(Series_Order))) = 1 THEN '0' + CONVERT(NVARCHAR,max(Series_Order)) ELSE CONVERT(NVARCHAR,max(Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,min(Series_Serial))) = 1 THEN '000' + CONVERT(NVARCHAR,min(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,min(Series_Serial))) = 2 THEN '00' + CONVERT(NVARCHAR,min(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,min(Series_Serial))) = 3 THEN '0' + CONVERT(NVARCHAR,min(Series_Serial)) ELSE CONVERT(NVARCHAR,min(Series_Serial)) END) AS SerFr,
                CONVERT(NVARCHAR,MC.Pro_ID)+'-'+(CASE WHEN LEN(CONVERT(NUMERIC,max(Series_Order))) = 1 THEN '0' + CONVERT(NVARCHAR,max(Series_Order)) ELSE CONVERT(NVARCHAR,max(Series_Order)) END) + '-' + (CASE WHEN LEN(CONVERT(NUMERIC,max(Series_Serial))) = 1 THEN '000' + CONVERT(NVARCHAR,max(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,max(Series_Serial))) = 2 THEN '00' + CONVERT(NVARCHAR,max(Series_Serial)) WHEN LEN(CONVERT(NUMERIC,max(Series_Serial))) = 3 THEN '0' + CONVERT(NVARCHAR,max(Series_Serial)) ELSE CONVERT(NVARCHAR,max(Series_Serial)) END) AS SerTo,
                COUNT(MC.Row_ID) AS Printed_Codes,
                isnull(B.Display_Series,MC.Pro_ID) pro_id,
                MC.Pro_ID+'*'+ convert(nvarchar,CAST(Print_Date AS DATE),105)+'*'+LabelRequestId as DownFl,
                ISNULL(B.Pro_Name, 'N/A') as Pro_Name,
                CAST(Print_Date AS DATE) print_date 
            FROM M_Code MC WITH (NOLOCK)
            INNER JOIN Pro_Reg B WITH (NOLOCK) on MC.Pro_ID = B.Pro_ID 
            WHERE MC.[Use_Type]='L' 
            AND B.Comp_ID = @CompID
            AND (@ProID IS NULL OR MC.Pro_ID = @ProID OR @ProID = '0' OR @ProID = 'string')
            AND (MC.Print_Date >= @FromDate)
            AND (@ToDate IS NULL OR MC.Print_Date <= @ToDate)
            AND (MC.Print_Date >= @BaselineDate)
            GROUP BY MC.Pro_ID, B.Display_Series, CAST(Print_Date AS DATE), LabelRequestId, B.Pro_Name
        ) FinalA 
        ORDER BY ID DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END
END
