/****** Object:  Table [dbo].[tbl_assigncodelocation]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_assigncodelocation](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code1] [varchar](20) NULL,
	[Code2] [varchar](20) NULL,
	[Pro_ID] [varchar](20) NULL,
	[Series_Order] [varchar](20) NULL,
	[Series_Serial] [varchar](20) NULL,
	[Comp_ID] [varchar](50) NULL,
	[status] [bit] NULL,
	[entry_date] [datetime] NULL,
	[dealer_name] [varchar](100) NULL,
	[M_CodeID] [int] NULL,
	[Passcode] [varchar](8) NULL,
	[fromseries] [varchar](50) NULL,
	[toseries] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_MCodeID] UNIQUE NONCLUSTERED 
(
	[M_CodeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
