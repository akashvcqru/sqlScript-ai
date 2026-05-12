-- =============================================
-- Author:      AI
-- Create date: 2026-05-04
-- Description: Get list of reassigned code batches for a company
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetReassignedCodeList_AI]
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        tp.Row_ID AS BatchRowId,
        tp.Pro_ID AS ProductId,
        pr.Pro_Name AS ProductName,
        tp.Batch_No AS BatchNo,
        tp.Entry_Date AS ReassignedDate,
        tp.Series_Limit AS SeriesLimit,
        tp.Comments
    FROM T_Pro tp WITH (NOLOCK)
    INNER JOIN Pro_Reg pr WITH (NOLOCK) ON tp.Pro_ID = pr.Pro_ID
    WHERE pr.Comp_ID = @Comp_ID
      AND tp.Comments LIKE 'Reassigned from %'
    ORDER BY tp.Entry_Date DESC;
END
GO
