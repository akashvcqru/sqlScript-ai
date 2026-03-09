/****** Object:  Table [dbo].[Pro_Expiry_Master]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pro_Expiry_Master](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](50) NOT NULL,
	[Pro_ID] [varchar](10) NOT NULL,
	[Product_Name] [varchar](100) NULL,
	[ExpiryDate] [date] NOT NULL,
	[Scheme] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
