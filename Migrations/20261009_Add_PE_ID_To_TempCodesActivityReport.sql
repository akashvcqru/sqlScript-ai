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
ELSE
BEGIN
    PRINT 'Column PE_ID already exists in [dbo].[TempCodesActivityReport].';
END
GO
