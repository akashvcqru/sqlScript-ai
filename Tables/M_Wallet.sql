/****** Object:  Table [dbo].[M_Wallet]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Wallet](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Entry_Date] [datetime] NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Bank_ID] [nvarchar](50) NULL,
	[Cr_Amount] [numeric](18, 2) NULL,
	[Dr_Amount] [numeric](18, 2) NULL,
	[Manu_Remark] [nvarchar](max) NULL,
	[Request_No] [nvarchar](50) NULL,
	[PayMode] [nvarchar](50) NULL,
	[Details] [nvarchar](max) NULL,
	[Payment_For] [nvarchar](50) NULL,
	[Admin_Remark] [nvarchar](max) NULL,
	[Payment_By] [nvarchar](50) NULL,
	[Flag] [int] NULL,
	[ModeofPayment] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
