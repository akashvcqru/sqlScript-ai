/****** Object:  Table [dbo].[Tax_Master]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tax_Master](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Service_Tax] [numeric](18, 2) NULL,
	[VAT] [numeric](18, 2) NULL,
	[Offer_Tax] [numeric](18, 2) NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK_Tax_Master] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
