/****** Object:  Table [dbo].[M_Print]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Print](
	[Row_ID] [numeric](12, 0) IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](10) NULL,
	[Pro_ID] [nvarchar](8) NULL,
	[RowIDFrom] [numeric](18, 0) NULL,
	[RowIDTo] [numeric](18, 0) NULL,
	[TCount] [numeric](18, 0) NULL,
	[IsPrint] [int] NULL,
	[IsDispatch] [int] NULL,
	[IsReceived] [int] NULL,
	[IsPaste] [int] NULL,
	[Print_Date] [datetime] NULL,
 CONSTRAINT [PK__M_Print__7C36D05E405A880E] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
