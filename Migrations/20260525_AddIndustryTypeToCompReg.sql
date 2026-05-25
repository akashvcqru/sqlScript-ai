-- Migration: Add Industry_Type column to Comp_Reg table
IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') 
      AND name = 'Industry_Type'
)
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [Industry_Type] [varchar](100) NULL;
END
GO
