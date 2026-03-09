/****** Object:  Table [dbo].[Paytm_balance]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Paytm_balance](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](100) NULL,
	[Amount] [decimal](18, 2) NULL,
	[Updated_date] [datetime] NULL
) ON [PRIMARY]
GO
