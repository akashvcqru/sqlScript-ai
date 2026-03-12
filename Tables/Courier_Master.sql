/****** Object:  Table [dbo].[Courier_Master]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Courier_Master](
	[CourierPkid] [int] IDENTITY(1,1) NOT NULL,
	[Courier_ID] [nvarchar](50) NOT NULL,
	[Courier_Name] [nvarchar](200) NULL,
	[Courier_Email] [nvarchar](200) NULL,
	[Courier_Mobile] [nvarchar](50) NULL,
	[Courier_Address] [nvarchar](max) NULL,
	[Flag] [int] NULL,
	[User_ID] [nvarchar](50) NULL,
 CONSTRAINT [PK_Courier_Master] PRIMARY KEY CLUSTERED 
(
	[CourierPkid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
