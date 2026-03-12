/****** Object:  Table [dbo].[M_Gift]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Gift](
	[Gift_Pkid] [int] IDENTITY(1,1) NOT NULL,
	[Gift_ID] [nvarchar](50) NOT NULL,
	[GiftName] [nvarchar](150) NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
 CONSTRAINT [PK_M_Gift] PRIMARY KEY CLUSTERED 
(
	[Gift_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
