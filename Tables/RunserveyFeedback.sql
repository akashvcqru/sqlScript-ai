/****** Object:  Table [dbo].[RunserveyFeedback]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RunserveyFeedback](
	[RunSurveyConsumerAnsid] [int] IDENTITY(1,1) NOT NULL,
	[Questionid] [int] NULL,
	[intRate] [int] NULL,
	[M_Consumer_MCodeid] [bigint] NULL,
	[Createddate] [datetime] NULL,
	[createdby] [int] NULL,
	[Compid] [nvarchar](50) NULL,
 CONSTRAINT [PK_RunserveyFeedback] PRIMARY KEY CLUSTERED 
(
	[RunSurveyConsumerAnsid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
