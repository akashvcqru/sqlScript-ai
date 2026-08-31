-- Migration: 20260831_Optimize_M_Code_LabelRequestId_Index.sql
-- Purpose  : Add nonclustered indexes on M_Code and M_Code_PFL for LabelRequestId and Pro_ID to speed up LabelPrintList queries

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_M_Code_LabelRequestId_ProID' AND object_id = OBJECT_ID('M_Code')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_M_Code_LabelRequestId_ProID]
    ON [dbo].[M_Code] ([LabelRequestId], [Pro_ID])
    INCLUDE ([Series_Order], [Series_Serial], [Row_ID], [DispatchFlag])
    WITH (FILLFACTOR = 90);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_M_Code_PFL_LabelRequestId_ProID' AND object_id = OBJECT_ID('M_Code_PFL')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_M_Code_PFL_LabelRequestId_ProID]
    ON [dbo].[M_Code_PFL] ([LabelRequestId], [Pro_ID])
    INCLUDE ([Series_Order], [Series_Serial], [Row_ID], [DispatchFlag])
    WITH (FILLFACTOR = 90);
END
GO
