/****** Object:  Table [dbo].[Comp_Document]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Comp_Document](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NOT NULL,
	[Comp_Info] [nvarchar](50) NULL,
	[PAN_TAN] [nvarchar](50) NULL,
	[VAT] [nvarchar](50) NULL,
	[Comp_Addressproof] [nvarchar](50) NULL,
	[Owner_proof] [nvarchar](50) NULL,
	[Signature] [nvarchar](max) NULL,
 CONSTRAINT [PK__Comp_Document__208CD6FA] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
