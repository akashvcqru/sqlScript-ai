/****** Object:  Table [dbo].[T_CashWallet]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CashWallet](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [nvarchar](25) NULL,
	[Comp_ID] [nvarchar](10) NULL,
	[Award_Key] [nvarchar](10) NULL,
	[Particulers] [nvarchar](500) NULL,
	[Credit] [numeric](10, 2) NULL,
	[Debit] [numeric](10, 2) NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK_T_CashWallet] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
