/****** Object:  Table [dbo].[loyalty_calculation]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[loyalty_calculation](
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[comp_id] [varchar](50) NOT NULL,
	[calculation_value] [int] NOT NULL,
	[createddate] [datetime] NOT NULL,
	[enddate] [datetime] NULL,
	[isactive] [int] NOT NULL,
	[isdelete] [int] NOT NULL,
 CONSTRAINT [PK_loyalty_calculation] PRIMARY KEY CLUSTERED 
(
	[row_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
