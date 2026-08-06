IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.tblScrapdatapfl') AND name = 'IDX_tblScrapdatapfl_Comp_Date')
BEGIN
    CREATE NONCLUSTERED INDEX [IDX_tblScrapdatapfl_Comp_Date]
    ON [dbo].[tblScrapdatapfl] ([CompanyId], [ScrapedDate])
    INCLUDE ([SerialCode], [ScrapedBy], [Code1], [Code2], [Id]);
END
GO
