/****** Object:  Table [dbo].[M_ServiceRules]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServiceRules](
	[Trans_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SST_Id] [bigint] NOT NULL,
	[ServiceType] [nvarchar](150) NOT NULL,
	[Rules] [nvarchar](150) NULL,
	[DistributionType] [nvarchar](150) NULL,
	[PrizeTrans_Id] [nvarchar](150) NULL,
	[MasterCodes] [bigint] NULL,
	[WinningCodes] [bigint] NULL,
	[WinCodes] [bigint] NULL,
	[Frequency] [int] NULL,
	[IsPrize] [int] NULL,
	[IsAllPrizeDistributed] [bit] NULL,
	[DueDate] [datetime] NULL,
 CONSTRAINT [PK_M_ServiceRules] PRIMARY KEY CLUSTERED 
(
	[Trans_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
