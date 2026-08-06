-- Migration: Add scrapeCodeDate column to tblScrapdatapfl table
IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[tblScrapdatapfl]') 
      AND name = 'scrapeCodeDate'
)
BEGIN
    ALTER TABLE [dbo].[tblScrapdatapfl] ADD [scrapeCodeDate] [datetime] NULL;
END
GO
