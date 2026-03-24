-- Migration: Add BatchSize column to codeassign_tractrac table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'BatchSize')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ADD [BatchSize] [int] NULL;
END
GO
