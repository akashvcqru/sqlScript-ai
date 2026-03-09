/****** Object:  Table [dbo].[Tbl_Users]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_Users](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](100) NOT NULL,
	[Email] [nvarchar](100) NULL,
	[UserPassword] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[UserProfileImage] [nvarchar](max) NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedAt] [datetime2](7) NULL,
	[UpdatedBy] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
