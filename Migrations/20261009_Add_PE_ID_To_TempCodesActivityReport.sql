USE [Vcqru]
GO

/****** Object:  Table [dbo].[TempCodesActivityReport]    Script Date: 10/09/2026 ******/
-- Add PE_ID column to TempCodesActivityReport with default NULL

IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[TempCodesActivityReport]') 
      AND name = 'PE_ID'
)
BEGIN
    ALTER TABLE [dbo].[TempCodesActivityReport]
    ADD [PE_ID] BIGINT NULL CONSTRAINT [DF_TempCodesActivityReport_PE_ID] DEFAULT (NULL);

    PRINT 'Column PE_ID added to [dbo].[TempCodesActivityReport] successfully.';
END
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_TempCodesActivityReport_PE_ID' 
      AND object_id = OBJECT_ID(N'[dbo].[TempCodesActivityReport]')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_TempCodesActivityReport_PE_ID]
    ON [dbo].[TempCodesActivityReport] ([PE_ID])
    INCLUDE ([WornPoint], [Enq_Date], [Comp_ID])
    WHERE [PE_ID] IS NOT NULL;

    PRINT 'Index IX_TempCodesActivityReport_PE_ID created successfully.';
END
ELSE
BEGIN
    PRINT 'Index IX_TempCodesActivityReport_PE_ID already exists.';
END
GO
