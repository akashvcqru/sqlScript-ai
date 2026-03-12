/****** Object:  Table [dbo].[Temp_PrintLabels]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_PrintLabels](
	[Print_Date] [datetime] NULL,
	[Allot_Date] [datetime] NULL,
	[Pro_ID] [char](4) NULL,
	[Use_Type] [char](7) NULL,
	[Print_Status] [tinyint] NULL,
	[Series_Order] [numeric](10, 0) NULL,
	[Series_Serial] [numeric](4, 0) NULL,
	[LabelRequestId] [nvarchar](15) NULL,
	[Code1] [numeric](5, 0) NOT NULL,
	[Code2] [numeric](8, 0) NOT NULL
) ON [PRIMARY]
GO
