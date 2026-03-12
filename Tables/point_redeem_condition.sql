/****** Object:  Table [dbo].[point_redeem_condition]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[point_redeem_condition](
	[Condition_id] [int] IDENTITY(1,1) NOT NULL,
	[comp_id] [varchar](50) NOT NULL,
	[codition_point] [int] NOT NULL,
	[condition_match] [int] NOT NULL,
	[created_date] [datetime] NULL,
	[modified_date] [datetime] NULL,
	[isactive] [int] NOT NULL,
	[selection_id] [int] NULL,
	[user_type] [int] NULL,
	[MaxClaimammount] [decimal](18, 0) NULL,
 CONSTRAINT [PK_point_redeem_condition] PRIMARY KEY CLUSTERED 
(
	[Condition_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
