-- Migration: 20260824_Optimize_M_Code_Batch_Index.sql
-- Purpose  : Add nonclustered index on M_Code(Pro_ID, Batch_No) to eliminate full table scans during batch updates & service settings

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_M_Code_ProID_BatchNo' AND object_id = OBJECT_ID('M_Code')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_M_Code_ProID_BatchNo]
    ON [dbo].[M_Code] ([Pro_ID], [Batch_No])
    INCLUDE ([Series_Order], [Series_Serial], [Row_ID])
    WITH (ONLINE = ON, FILLFACTOR = 90);
END
GO
