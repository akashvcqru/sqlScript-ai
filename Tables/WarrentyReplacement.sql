/****** Object:  Table [dbo].[WarrentyReplacement]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WarrentyReplacement](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[BillNo] [nvarchar](50) NULL,
	[PurchaseDate] [datetime] NULL,
	[ExpirationDate] [datetime] NULL,
	[Code] [varchar](20) NULL,
	[NewSerialno] [varchar](100) NULL,
	[OldSerialno] [varchar](100) NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[claim_id] [int] NULL
) ON [PRIMARY]
GO
