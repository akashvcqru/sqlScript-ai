/****** Object:  Table [dbo].[dealer_credit_limits]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dealer_credit_limits](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [int] NOT NULL,
	[Comp_id] [varchar](10) NULL,
	[total_credit_limit] [decimal](12, 2) NOT NULL,
	[current_credit_limit] [decimal](12, 2) NOT NULL,
	[last_updated_at] [datetime] NULL,
	[remarks] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
