/****** Object:  Table [dbo].[ConsumerBackupforSBU]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConsumerBackupforSBU](
	[UserMobile] [nvarchar](15) NULL,
	[Distributor_ID] [varchar](20) NULL,
	[Employee_ID] [varchar](20) NULL,
	[Consumer_ID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
GO
