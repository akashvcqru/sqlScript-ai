/****** Object:  Table [dbo].[tbl_setFrequncyorDefaultPoint]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_setFrequncyorDefaultPoint](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[txtRepeatFrequncy] [int] NULL,
	[DefaultAmount] [numeric](10, 2) NULL,
	[AmountSetNumbers] [varchar](100) NULL,
	[FrequncyNumbers] [varchar](100) NULL,
	[comp_id] [varchar](50) NULL,
	[status] [int] NOT NULL,
	[createddate] [datetime] NOT NULL
) ON [PRIMARY]
GO
