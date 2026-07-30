/****** Object:  Table [dbo].[m_dealermaster]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[m_dealermaster](
	[DealerId] [int] IDENTITY(1,1) NOT NULL,
	[Zone] [varchar](20) NULL,
	[D_State] [varchar](50) NULL,
	[DealerCode] [varchar](20) NULL,
	[DealerType] [varchar](20) NULL,
	[DealerLocation] [varchar](50) NULL,
	[DealerTechnicianId] [varchar](20) NULL,
	[DE_Designation] [varchar](21) NULL,
	[D_Status] [varchar](20) NULL,
	[Created_Date] [datetime] NULL,
	[Created_By] [bigint] NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_By] [nvarchar](255) NULL,
	[D_Name] [nvarchar](100) NULL,
	[Comp_id] [nvarchar](50) NULL,
	[City] [varchar](100) NULL,
	[Mobile_Num] [nvarchar](20) NULL,
	[Proprietor1] [varchar](100) NULL,
	[Proprietor2] [varchar](100) NULL,
	[Proprietor3] [varchar](100) NULL
) ON [PRIMARY]
GO
