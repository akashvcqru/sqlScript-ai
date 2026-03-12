/****** Object:  Table [dbo].[BReferralMCodeCheck]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BReferralMCodeCheck](
	[BReferralMCodeCheckid] [bigint] IDENTITY(1,1) NOT NULL,
	[sst_id] [bigint] NOT NULL,
	[M_Consumer_MCOdeid] [bigint] NULL,
	[M_Consumerid] [bigint] NULL,
	[ReferralCode] [nvarchar](50) NULL,
	[IsPointsAssigned] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[Createdby] [int] NULL,
	[ReferralCode_UserID] [bigint] NULL,
 CONSTRAINT [PK_BReferralMCodeCheck] PRIMARY KEY CLUSTERED 
(
	[BReferralMCodeCheckid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
