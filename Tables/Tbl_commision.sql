/****** Object:  Table [dbo].[Tbl_commision]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_commision](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Mobileno] [nvarchar](12) NOT NULL,
	[Commission] [numeric](18, 2) NOT NULL,
	[Company_id] [nvarchar](10) NOT NULL,
	[Created_by] [int] NOT NULL,
	[created_date] [datetime] NULL,
	[updated_by] [int] NULL,
	[Updated_date] [datetime] NULL
) ON [PRIMARY]
GO
