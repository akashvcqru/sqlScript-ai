/****** Object:  Table [dbo].[day_span_for_loyalty]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[day_span_for_loyalty](
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[comp_id] [varchar](50) NOT NULL,
	[day_span] [int] NOT NULL,
	[createddate] [datetime] NOT NULL,
	[isactive] [int] NOT NULL,
 CONSTRAINT [PK_day_span_for_loyalty] PRIMARY KEY CLUSTERED 
(
	[row_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
