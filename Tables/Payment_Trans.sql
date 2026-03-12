/****** Object:  Table [dbo].[Payment_Trans]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payment_Trans](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Amc_Offer_ID] [bigint] NULL,
	[Request_No] [nvarchar](50) NULL,
	[Rec_Amount] [numeric](18, 2) NULL,
	[Req_Amount] [numeric](18, 2) NULL,
	[Admin_Remark] [nvarchar](250) NULL,
	[Manu_Remark] [nvarchar](250) NULL,
	[Balance] [numeric](18, 2) NULL,
 CONSTRAINT [PK__Payment_Trans__640DD89F] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
