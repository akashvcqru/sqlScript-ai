/****** Object:  Table [dbo].[RunSurveyQuestion]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RunSurveyQuestion](
	[Questionid] [int] IDENTITY(1,1) NOT NULL,
	[Question] [nvarchar](500) NULL,
	[IsActive] [int] NULL,
	[Createddate] [datetime] NULL,
	[Createdby] [int] NULL,
	[comp_id] [nvarchar](50) NULL,
	[IsDelete] [int] NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_RunSurveyQuestion] PRIMARY KEY CLUSTERED 
(
	[Questionid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
