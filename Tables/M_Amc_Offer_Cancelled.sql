/****** Object:  Table [dbo].[M_Amc_Offer_Cancelled]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Amc_Offer_Cancelled](
	[TbleID] [bigint] IDENTITY(1,1) NOT NULL,
	[Amc_Offer_ID] [bigint] NULL,
	[Entry_Date] [datetime] NULL,
	[Cancelled_By] [nvarchar](250) NULL,
	[Remarks] [nvarchar](250) NULL,
PRIMARY KEY CLUSTERED 
(
	[TbleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
