/****** Object:  Table [dbo].[ReferralLimit]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReferralLimit](
	[ReferralID] [int] IDENTITY(1,1) NOT NULL,
	[Limit] [int] NULL,
	[Compid] [nvarchar](50) NULL,
	[M_SST_id] [bigint] NULL,
	[CreatedDate] [datetime] NOT NULL,
	[CreatedBy] [int] NULL,
 CONSTRAINT [PK_ReferralLimit] PRIMARY KEY CLUSTERED 
(
	[ReferralID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
