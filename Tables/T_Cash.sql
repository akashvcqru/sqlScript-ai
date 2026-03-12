/****** Object:  Table [dbo].[T_Cash]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cash](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[User_ID] [nvarchar](50) NULL,
	[MobileNo] [nvarchar](15) NULL,
	[Code1] [numeric](18, 0) NULL,
	[Code2] [numeric](18, 0) NULL,
	[IsCash] [numeric](18, 0) NULL,
	[Entry_Date] [datetime] NULL,
	[Mode] [nvarchar](15) NULL,
	[ReferralCode] [nvarchar](15) NULL,
	[IsUsed] [int] NULL
) ON [PRIMARY]
GO
