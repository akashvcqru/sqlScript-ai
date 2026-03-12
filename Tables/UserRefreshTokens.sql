/****** Object:  Table [dbo].[UserRefreshTokens]    Script Date: 3/10/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserRefreshTokens](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](100) NOT NULL,
	[Comp_ID] [nvarchar](50) NOT NULL,
	[RefreshToken] [nvarchar](max) NOT NULL,
	[Device] [nvarchar](50) NULL,
	[ExpiryDate] [datetime] NOT NULL,
	[CreatedAt] [datetime] NOT NULL DEFAULT (getdate()),
 CONSTRAINT [PK_UserRefreshTokens] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
