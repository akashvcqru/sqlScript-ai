USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-22
-- Description: Get Label Print List with pagination and filters (optimized with CROSS APPLY)
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

    DECLARE @RegDate DATETIME;
    SELECT TOP 1 @RegDate = Reg_Date FROM Comp_Reg WHERE Comp_ID = @Comp_ID AND Status = 1;

    -- Normalize empty or zero product ID
    IF @Pro_ID = '' OR @Pro_ID = '0'
        SET @Pro_ID = NULL;

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        ;WITH UniqueBatches AS (
            SELECT 
                MC.LabelRequestId, 
                MC.Pro_ID,
                MAX(MC.Row_ID) as MaxRowID,
                MAX(MC.Print_Date) as Print_DateTime
            FROM M_Code_PFL MC 
            INNER JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
              AND B.Comp_ID = @Comp_ID 
              AND MC.Print_Date >= @RegDate
              AND (@Pro_ID IS NULL OR MC.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR MC.Print_Date >= @DateFrom)
              AND (@DateTo IS NULL OR MC.Print_Date <= @DateTo)
              AND MC.LabelRequestId IS NOT NULL
            GROUP BY MC.LabelRequestId, MC.Pro_ID
        ),
        NumberedBatches AS (
            SELECT 
                LabelRequestId,
                Pro_ID,
                Print_DateTime,
                ROW_NUMBER() OVER(ORDER BY MaxRowID ASC) AS ID,
                COUNT(*) OVER() as TotalRecords
            FROM UniqueBatches
        ),
        PaginatedBatches AS (
            SELECT LabelRequestId, Pro_ID, Print_DateTime, ID, TotalRecords
            FROM NumberedBatches
            ORDER BY ID DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
        )
        SELECT 
            PB.ID,
            CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex % 10000, 0)), 4) AS SerFr,
            CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex % 10000, 0)), 4) AS SerTo,
            S.Codes,
            ISNULL(B.Display_Series, PB.Pro_ID) AS pro_id,
            PB.Pro_ID + '*' + CONVERT(NVARCHAR, PB.Print_DateTime, 105) + '*' + PB.LabelRequestId AS DownFl,
            ISNULL(B.Display_Product, B.Pro_Name) AS Pro_Name,
            CAST(PB.Print_DateTime AS DATE) AS print_date,
            S.IsDispatched,
            PB.TotalRecords
        FROM PaginatedBatches PB
        INNER JOIN Pro_Reg B ON PB.Pro_ID = B.Pro_ID
        CROSS APPLY (
            SELECT 
                MIN(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MinIndex,
                MAX(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MaxIndex,
                COUNT(MC.Row_ID) as Codes,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) as IsDispatched
            FROM M_Code_PFL MC
            WHERE MC.LabelRequestId = PB.LabelRequestId AND MC.Pro_ID = PB.Pro_ID AND MC.[Use_Type]='L'
        ) S
        ORDER BY PB.ID DESC;
    END
    ELSE
    BEGIN
        ;WITH UniqueBatches AS (
            SELECT 
                MC.LabelRequestId, 
                MC.Pro_ID,
                MAX(MC.Row_ID) as MaxRowID,
                MAX(MC.Print_Date) as Print_DateTime
            FROM M_Code MC 
            INNER JOIN Pro_Reg B ON MC.Pro_ID = B.Pro_ID
            WHERE MC.[Use_Type]='L' 
              AND B.Comp_ID = @Comp_ID 
              AND MC.Print_Date >= @RegDate
              AND (@Pro_ID IS NULL OR MC.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR MC.Print_Date >= @DateFrom)
              AND (@DateTo IS NULL OR MC.Print_Date <= @DateTo)
              AND MC.LabelRequestId IS NOT NULL
            GROUP BY MC.LabelRequestId, MC.Pro_ID
        ),
        NumberedBatches AS (
            SELECT 
                LabelRequestId,
                Pro_ID,
                Print_DateTime,
                ROW_NUMBER() OVER(ORDER BY MaxRowID ASC) AS ID,
                COUNT(*) OVER() as TotalRecords
            FROM UniqueBatches
        ),
        PaginatedBatches AS (
            SELECT LabelRequestId, Pro_ID, Print_DateTime, ID, TotalRecords
            FROM NumberedBatches
            ORDER BY ID DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
        )
        SELECT 
            PB.ID,
            CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex % 10000, 0)), 4) AS SerFr,
            CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex % 10000, 0)), 4) AS SerTo,
            S.Codes,
            ISNULL(B.Display_Series, PB.Pro_ID) AS pro_id,
            PB.Pro_ID + '*' + CONVERT(NVARCHAR, PB.Print_DateTime, 105) + '*' + PB.LabelRequestId AS DownFl,
            B.Pro_Name,
            CAST(PB.Print_DateTime AS DATE) AS print_date,
            S.IsDispatched,
            PB.TotalRecords
        FROM PaginatedBatches PB
        INNER JOIN Pro_Reg B ON PB.Pro_ID = B.Pro_ID
        CROSS APPLY (
            SELECT 
                MIN(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MinIndex,
                MAX(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MaxIndex,
                COUNT(MC.Row_ID) as Codes,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) as IsDispatched
            FROM M_Code MC
            WHERE MC.LabelRequestId = PB.LabelRequestId AND MC.Pro_ID = PB.Pro_ID AND MC.[Use_Type]='L'
        ) S
        ORDER BY PB.ID DESC;
    END
END
GO
