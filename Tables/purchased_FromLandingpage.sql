USE [Vcqru]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[purchased_FromLandingpage]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[purchased_FromLandingpage](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[purchased_From] [varchar](100) NOT NULL,
	[Comp_ID] [varchar](50) NULL,
	[IsActive] [bit] NULL CONSTRAINT [DF_purchased_FromLandingpage_IsActive]  DEFAULT ((1)),
	[IsDeleted] [bit] NULL CONSTRAINT [DF_purchased_FromLandingpage_IsDeleted]  DEFAULT ((0)),
	[Create_Date] [datetime] NULL CONSTRAINT [DF_purchased_FromLandingpage_Create_Date]  DEFAULT (getdate()),
 CONSTRAINT [PK_purchased_FromLandingpage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
