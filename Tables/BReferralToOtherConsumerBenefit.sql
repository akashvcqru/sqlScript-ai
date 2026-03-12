/****** Object:  Table [dbo].[BReferralToOtherConsumerBenefit]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BReferralToOtherConsumerBenefit](
	[BReferralToOtherConsumerID] [bigint] IDENTITY(1,1) NOT NULL,
	[BReferralMCodeCheckid] [bigint] NULL,
	[M_Consumerid] [bigint] NULL,
	[Points] [int] NULL,
	[isCash] [int] NULL,
	[Gift] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NULL,
	[Createdby] [int] NULL,
 CONSTRAINT [PK_BReferralToOtherConsumerID] PRIMARY KEY CLUSTERED 
(
	[BReferralToOtherConsumerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
