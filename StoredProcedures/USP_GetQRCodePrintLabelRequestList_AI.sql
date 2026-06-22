USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-22
-- Description: Get QR Code Print Label Request List with pagination and search
-- Optimization: Removed Temp Tables in favor of CTEs to reduce TempDB IO.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetQRCodePrintLabelRequestList_AI]
    @Comp_ID NVARCHAR(50),
    @Search NVARCHAR(200),
    @Offset INT,
    @Limit INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalRecords INT = 0;

    IF @Search = '%%' OR @Search = '' OR @Search IS NULL
    BEGIN
        -- Get total records
        SELECT @TotalRecords = COUNT(1)
        FROM M_Label_Request A WITH (NOLOCK)
        INNER JOIN Pro_Reg B WITH (NOLOCK) ON A.Pro_ID = B.Pro_ID 
        WHERE B.Comp_ID = @Comp_ID;

        WITH CTE AS (
            SELECT A.Row_ID, 
                   CONVERT(nvarchar, A.Entry_Date, 107) AS RequestDate, 
                   A.Pro_ID, 
                   B.Pro_Name, 
                   C.Label_Name as LabelType, 
                   C.Label_Size, 
                   C.Label_Prise, 
                   A.Qty as RequestedLabels,
                   (CASE 
                        WHEN A.Flag = '0' THEN 'Pending' 
                        WHEN A.Flag = '-1' THEN 'Rejected' 
                        WHEN A.Flag = '1' THEN 'Printed' 
                        WHEN A.Flag = '-2' THEN 'Canceled' 
                    END) AS RequestStatusFlag,
                   A.Tracking_No, 
                   A.Flag,
                   B.Comp_ID,
                   A.Entry_Date
            FROM M_Label_Request A WITH (NOLOCK)
            INNER JOIN M_Label C WITH (NOLOCK) ON A.Label_Code = C.Label_Code 
            INNER JOIN Pro_Reg B WITH (NOLOCK) ON A.Pro_ID = B.Pro_ID 
            WHERE B.Comp_ID = @Comp_ID
            ORDER BY A.Entry_Date DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
        )
        SELECT CTE.Row_ID, 
               CTE.RequestDate, 
               CTE.Pro_ID, 
               CTE.Pro_Name, 
               CTE.LabelType, 
               CTE.Label_Size, 
               CTE.Label_Prise, 
               CTE.RequestedLabels,
               CTE.RequestStatusFlag,
               CTE.Tracking_No, 
               CTE.Flag,
               CAST(CASE 
                   WHEN CTE.Comp_ID = 'Comp-1693' THEN ISNULL(PFL.DispatchFlag, 0)
                   ELSE ISNULL(MC.DispatchFlag, 0)
               END AS INT) AS CourierDispatchFlag,
               @TotalRecords AS TotalRecords
        FROM CTE
        OUTER APPLY (
            SELECT TOP 1 DispatchFlag 
            FROM M_Code_PFL WITH (NOLOCK) 
            WHERE CTE.Comp_ID = 'Comp-1693' 
              AND LabelRequestId = CAST(CTE.Tracking_No AS VARCHAR(250)) 
              AND Pro_ID = CTE.Pro_ID
        ) PFL
        OUTER APPLY (
            SELECT TOP 1 DispatchFlag 
            FROM M_Code WITH (NOLOCK) 
            WHERE CTE.Comp_ID <> 'Comp-1693' 
              AND LabelRequestId = CAST(CTE.Tracking_No AS VARCHAR(250)) 
              AND Pro_ID = CTE.Pro_ID
        ) MC
        ORDER BY CTE.Entry_Date DESC
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
        -- Get total records for search
        SELECT @TotalRecords = COUNT(1)
        FROM M_Label_Request A WITH (NOLOCK)
        INNER JOIN M_Label C WITH (NOLOCK) ON A.Label_Code = C.Label_Code 
        INNER JOIN Pro_Reg B WITH (NOLOCK) ON A.Pro_ID = B.Pro_ID 
        WHERE B.Comp_ID = @Comp_ID 
          AND (A.Tracking_No LIKE @Search 
               OR B.Pro_Name LIKE @Search
               OR C.Label_Name LIKE @Search
               OR CAST(A.Row_ID AS NVARCHAR(50)) LIKE @Search);

        WITH CTE AS (
            SELECT A.Row_ID, 
                   CONVERT(nvarchar, A.Entry_Date, 107) AS RequestDate, 
                   A.Pro_ID, 
                   B.Pro_Name, 
                   C.Label_Name as LabelType, 
                   C.Label_Size, 
                   C.Label_Prise, 
                   A.Qty as RequestedLabels,
                   (CASE 
                        WHEN A.Flag = '0' THEN 'Pending' 
                        WHEN A.Flag = '-1' THEN 'Rejected' 
                        WHEN A.Flag = '1' THEN 'Printed' 
                        WHEN A.Flag = '-2' THEN 'Canceled' 
                    END) AS RequestStatusFlag,
                   A.Tracking_No, 
                   A.Flag,
                   B.Comp_ID,
                   A.Entry_Date
            FROM M_Label_Request A WITH (NOLOCK)
            INNER JOIN M_Label C WITH (NOLOCK) ON A.Label_Code = C.Label_Code 
            INNER JOIN Pro_Reg B WITH (NOLOCK) ON A.Pro_ID = B.Pro_ID 
            WHERE B.Comp_ID = @Comp_ID 
              AND (A.Tracking_No LIKE @Search 
                   OR B.Pro_Name LIKE @Search
                   OR C.Label_Name LIKE @Search
                   OR CAST(A.Row_ID AS NVARCHAR(50)) LIKE @Search)
            ORDER BY A.Entry_Date DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
        )
        SELECT CTE.Row_ID, 
               CTE.RequestDate, 
               CTE.Pro_ID, 
               CTE.Pro_Name, 
               CTE.LabelType, 
               CTE.Label_Size, 
               CTE.Label_Prise, 
               CTE.RequestedLabels,
               CTE.RequestStatusFlag,
               CTE.Tracking_No, 
               CTE.Flag,
               CAST(CASE 
                   WHEN CTE.Comp_ID = 'Comp-1693' THEN ISNULL(PFL.DispatchFlag, 0)
                   ELSE ISNULL(MC.DispatchFlag, 0)
               END AS INT) AS CourierDispatchFlag,
               @TotalRecords AS TotalRecords
        FROM CTE
        OUTER APPLY (
            SELECT TOP 1 DispatchFlag 
            FROM M_Code_PFL WITH (NOLOCK) 
            WHERE CTE.Comp_ID = 'Comp-1693' 
              AND LabelRequestId = CAST(CTE.Tracking_No AS VARCHAR(250)) 
              AND Pro_ID = CTE.Pro_ID
        ) PFL
        OUTER APPLY (
            SELECT TOP 1 DispatchFlag 
            FROM M_Code WITH (NOLOCK) 
            WHERE CTE.Comp_ID <> 'Comp-1693' 
              AND LabelRequestId = CAST(CTE.Tracking_No AS VARCHAR(250)) 
              AND Pro_ID = CTE.Pro_ID
        ) MC
        ORDER BY CTE.Entry_Date DESC
        OPTION (RECOMPILE);
    END
END
GO
