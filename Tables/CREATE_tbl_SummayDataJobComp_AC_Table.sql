USE [Vcqru]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_SummayDataJobComp_AC]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_SummayDataJobComp_AC](
        [comp_id] [varchar](50) NOT NULL PRIMARY KEY,
        [email_list] [nvarchar](MAX) NULL,                -- Comma-separated emails specific to this company job
        [isactive] [bit] NOT NULL CONSTRAINT [DF_tbl_SummayDataJobComp_AC_isactive] DEFAULT ((1))
    ) ON [PRIMARY];
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_SummayDataJobComp_AC]') AND name = 'email_list')
    BEGIN
        ALTER TABLE [dbo].[tbl_SummayDataJobComp_AC] ADD [email_list] [nvarchar](MAX) NULL;
    END
END
GO

-- Seed Comp-1555 with default recipient emails if missing
IF NOT EXISTS (SELECT 1 FROM [dbo].[tbl_SummayDataJobComp_AC] WHERE [comp_id] = 'Comp-1555')
BEGIN
    INSERT INTO [dbo].[tbl_SummayDataJobComp_AC] ([comp_id], [email_list], [isactive]) 
    VALUES ('Comp-1555', 'akash@vcqru.com,ajinkya@vcqru.com,varun@vcqru.com,devraj@vcqru.com', 1);
END
ELSE
BEGIN
    UPDATE [dbo].[tbl_SummayDataJobComp_AC] 
    SET [email_list] = 'akash@vcqru.com,ajinkya@vcqru.com,varun@vcqru.com,devraj@vcqru.com' 
    WHERE [comp_id] = 'Comp-1555' AND ([email_list] IS NULL OR [email_list] = '');
END
GO
