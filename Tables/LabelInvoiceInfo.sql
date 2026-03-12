/****** Object:  Table [dbo].[LabelInvoiceInfo]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LabelInvoiceInfo](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Invoice_ID] [nvarchar](50) NOT NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Label_Code] [nvarchar](50) NULL,
	[Label_Name] [nvarchar](50) NULL,
	[Series_From] [nvarchar](50) NULL,
	[Series_To] [nvarchar](50) NULL,
	[Qty] [int] NULL,
	[Price] [numeric](18, 2) NULL,
	[G_Amount] [numeric](18, 2) NULL,
	[Service_Tax] [numeric](18, 2) NULL,
	[VAT] [numeric](18, 2) NULL,
	[N_Amount] [numeric](18, 2) NULL,
	[Entry_Date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
