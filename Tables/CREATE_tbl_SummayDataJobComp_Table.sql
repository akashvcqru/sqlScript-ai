USE [Vcqru]
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_SummayDataJobComp]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_SummayDataJobComp](
        [comp_id] [varchar](50) NOT NULL,
        [isactive] [bit] NOT NULL CONSTRAINT [DF_tbl_SummayDataJobComp_isactive] DEFAULT ((1)),
        CONSTRAINT [PK_tbl_SummayDataJobComp] PRIMARY KEY CLUSTERED 
        (
            [comp_id] ASC
        )
    ) ON [PRIMARY];
END
GO
