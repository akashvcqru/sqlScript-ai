/****** Object:  Table [dbo].[tblScrapdatapfl]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tblScrapdatapfl]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tblScrapdatapfl](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Code1] [int] NULL,
        [Code2] [int] NULL,
        [SerialCode] [nvarchar](20) NULL,
        [ScrapedBy] [nvarchar](20) NULL,
        [CompanyId] [nvarchar](10) NULL,
        [ScrapedDate] [datetime] NULL,
        [scrapeCodeDate] [datetime] NULL,
    PRIMARY KEY CLUSTERED 
    (
        [Id] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY]
END
GO
