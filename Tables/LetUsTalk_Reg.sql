/****** Object:  Table [dbo].[LetUsTalk_Reg]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LetUsTalk_Reg](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[Mobileno] [nvarchar](50) NULL,
	[Comments] [nvarchar](max) NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK__LetUsTalk_Reg__6754599E] PRIMARY KEY CLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
