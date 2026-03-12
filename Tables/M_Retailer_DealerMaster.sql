/****** Object:  Table [dbo].[M_Retailer_DealerMaster]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Retailer_DealerMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DealerCode] [varchar](21) NULL,
	[DealerName] [varchar](107) NULL,
	[Location] [varchar](70) NULL,
	[District] [varchar](70) NULL,
	[AO] [varchar](35) NULL,
	[State] [varchar](38) NULL,
	[Zone] [varchar](15) NULL,
	[CCM] [varchar](46) NULL,
	[Category] [varchar](22) NULL,
	[Status] [varchar](12) NULL,
	[ReqDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
