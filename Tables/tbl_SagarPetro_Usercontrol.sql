/****** Object:  Table [dbo].[tbl_SagarPetro_Usercontrol]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_SagarPetro_Usercontrol](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MenuId] [int] NULL,
	[Status] [bit] NULL,
	[UserRole_Id] [varchar](20) NULL,
	[RegDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
