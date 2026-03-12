/****** Object:  Table [dbo].[Tax_Master_Info]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tax_Master_Info](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[TaxSet_ID] [nvarchar](150) NULL,
	[Comp_ID] [nvarchar](150) NULL,
	[Pro_ID] [nvarchar](150) NOT NULL,
	[Label_ServiceTax] [numeric](18, 2) NULL,
	[Label_Vat] [numeric](18, 2) NULL,
	[AMC_ServiceTax] [numeric](18, 2) NULL,
	[AMC_Vat] [numeric](18, 2) NULL,
	[Offer_ServiceTax] [numeric](18, 2) NULL,
	[Offer_Vat] [numeric](18, 2) NULL,
	[Date_From] [datetime] NOT NULL,
	[Date_To] [datetime] NOT NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK_Tax_Master_Info] PRIMARY KEY CLUSTERED 
(
	[Pro_ID] ASC,
	[Date_From] ASC,
	[Date_To] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
