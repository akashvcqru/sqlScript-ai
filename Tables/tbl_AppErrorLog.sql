/****** Object:  Table [dbo].[tbl_AppErrorLog]    Script Date: 5/25/2026 6:38:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_AppErrorLog](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DeviceInfo] [nvarchar](max) NULL,
	[ApiResponse] [nvarchar](max) NULL,
	[ApiName] [nvarchar](250) NULL,
	[Username] [nvarchar](250) NULL,
	[UserMobile] [varchar](20) NULL,
	[PageName] [nvarchar](250) NULL,
	[ErrorResponse] [nvarchar](max) NULL,
	[ApplicationType] [varchar](50) NOT NULL,
	[CreatedAt] [datetime] NOT NULL CONSTRAINT [DF_tbl_AppErrorLog_CreatedAt] DEFAULT (getdate()),
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
