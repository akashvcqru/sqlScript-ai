/****** Object:  Table [dbo].[BRefferalEarnedBenifit_NotInUse]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BRefferalEarnedBenifit_NotInUse](
	[BReferralEarnedBenifitID] [int] IDENTITY(1,1) NOT NULL,
	[sst_id] [int] NULL,
	[M_Consumerid] [int] NULL,
	[Points] [int] NULL,
	[Cash] [int] NULL,
	[Gift] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NULL,
	[Createdby] [int] NULL,
 CONSTRAINT [PK_BRefferalEarnedBenifit] PRIMARY KEY CLUSTERED 
(
	[BReferralEarnedBenifitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
