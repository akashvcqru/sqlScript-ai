/****** Object:  Table [dbo].[tblcommission]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblcommission](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](30) NULL,
	[Service_Id] [varchar](30) NULL,
	[Slab_Id] [int] NULL,
	[Comm_Amount] [float] NULL,
	[Comm_Type] [bit] NULL,
	[Charge_Amount] [float] NULL,
	[Charge_Type] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
