/****** Object:  Table [dbo].[tbl_LOGS]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_LOGS](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [varchar](100) NULL,
	[UserEmail] [varchar](500) NULL,
	[UserID] [varchar](100) NULL,
	[Action] [varchar](100) NULL,
	[Details] [nvarchar](max) NULL,
	[Remarks] [nvarchar](max) NULL,
	[Log_Date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
