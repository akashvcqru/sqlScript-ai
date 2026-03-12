/****** Object:  Table [dbo].[M_ServiceTerms_Conditions]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServiceTerms_Conditions](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Service_ID] [nvarchar](10) NOT NULL,
	[EntryDate] [datetime] NULL,
	[AboutService] [nvarchar](max) NULL,
	[Terms_Conditions] [nvarchar](max) NULL,
	[Advantage] [nvarchar](max) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
 CONSTRAINT [PK_M_ServiceTerms_Conditions] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
