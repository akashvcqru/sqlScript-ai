/****** Object:  Table [dbo].[M_DirectRewards]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_DirectRewards](
	[DirectReward_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DirectRewardName] [nvarchar](250) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
 CONSTRAINT [PK_M_DirectRewards] PRIMARY KEY CLUSTERED 
(
	[DirectReward_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
