/****** Object:  Table [dbo].[tblPPolicyHistory]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblPPolicyHistory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](20) NULL,
	[PolicyId] [int] NULL,
	[IsAccept] [bit] NULL,
	[ReqDate] [datetime] NULL,
	[DeviceDetails] [varchar](30) NULL,
	[MacID] [varchar](30) NULL,
	[IPAddress] [nvarchar](max) NULL,
	[Browser] [varchar](30) NULL,
	[SkipCount] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
