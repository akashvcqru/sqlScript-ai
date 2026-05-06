USE [Vcqru]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[user_typemasterLandingpage]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[user_typemasterLandingpage](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[User_Type] [varchar](100) NOT NULL,
	[IsActive] [bit] NULL CONSTRAINT [DF_user_typemasterLandingpage_IsActive]  DEFAULT ((1)),
	[IsDeleted] [bit] NULL CONSTRAINT [DF_user_typemasterLandingpage_IsDeleted]  DEFAULT ((0)),
	[Create_Date] [datetime] NULL CONSTRAINT [DF_user_typemasterLandingpage_Create_Date]  DEFAULT (getdate()),
 CONSTRAINT [PK_user_typemasterLandingpage] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
