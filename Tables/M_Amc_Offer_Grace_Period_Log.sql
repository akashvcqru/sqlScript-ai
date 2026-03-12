/****** Object:  Table [dbo].[M_Amc_Offer_Grace_Period_Log]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Amc_Offer_Grace_Period_Log](
	[TbleID] [bigint] IDENTITY(1,1) NOT NULL,
	[Amc_Offer_ID] [bigint] NULL,
	[Days] [bigint] NULL,
	[Manage_By] [nvarchar](150) NULL,
	[Remarks] [nvarchar](250) NULL,
 CONSTRAINT [PK_M_Amc_Offer_Grace_Period_Log] PRIMARY KEY CLUSTERED 
(
	[TbleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
