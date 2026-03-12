/****** Object:  Table [dbo].[Payment_Received]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payment_Received](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Rec_Date] [datetime] NULL,
	[Req_Date] [datetime] NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Bank_ID] [nvarchar](50) NULL,
	[Req_Amount] [numeric](18, 2) NULL,
	[Rec_Amount] [numeric](18, 2) NULL,
	[Manu_Remark] [nvarchar](max) NULL,
	[Request_No] [nvarchar](50) NULL,
	[PayMode] [nvarchar](50) NULL,
	[Details] [nvarchar](max) NULL,
	[Payment_For] [nvarchar](50) NULL,
	[Admin_Remark] [nvarchar](max) NULL,
	[Payment_By] [nvarchar](50) NULL,
	[Flag] [int] NULL,
	[ModeofPayment] [nvarchar](50) NULL,
 CONSTRAINT [PK_Payment_Received] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
