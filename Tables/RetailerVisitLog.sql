/****** Object:  Table [dbo].[RetailerVisitLog]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RetailerVisitLog](
	[SalesPersonId] [int] NOT NULL,
	[SalesPersonName] [nvarchar](200) NOT NULL,
	[RetailerName] [nvarchar](300) NOT NULL,
	[VisitDate] [datetime] NOT NULL,
	[VisitNotes] [nvarchar](max) NULL,
	[CreatedOn] [datetime] NULL,
	[VisitId] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [varchar](10) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
