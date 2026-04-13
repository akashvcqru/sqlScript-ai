/****** Object:  Table [dbo].[tbl_ClaimMaster]    Script Date: 4/13/2026 12:30:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_ClaimMaster](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ClaimName] [nvarchar](255) NULL,
 CONSTRAINT [PK_tbl_ClaimMaster] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

SET IDENTITY_INSERT [dbo].[tbl_ClaimMaster] ON 
GO
INSERT [dbo].[tbl_ClaimMaster] ([Id], [ClaimName]) VALUES (1, N'gift')
GO
INSERT [dbo].[tbl_ClaimMaster] ([Id], [ClaimName]) VALUES (2, N'imps')
GO
INSERT [dbo].[tbl_ClaimMaster] ([Id], [ClaimName]) VALUES (3, N'neft')
GO
INSERT [dbo].[tbl_ClaimMaster] ([Id], [ClaimName]) VALUES (4, N'manual')
GO
SET IDENTITY_INSERT [dbo].[tbl_ClaimMaster] OFF
GO
