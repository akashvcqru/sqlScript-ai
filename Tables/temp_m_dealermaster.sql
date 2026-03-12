/****** Object:  Table [dbo].[temp_m_dealermaster]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_m_dealermaster](
	[DealerId] [int] IDENTITY(1,1) NOT NULL,
	[Zone] [varchar](20) NULL,
	[D_State] [varchar](50) NULL,
	[DealerCode] [varchar](20) NULL,
	[DealerTechnicianId] [varchar](20) NULL,
	[D_Name] [nvarchar](100) NULL,
	[DE_Designation] [varchar](20) NULL
) ON [PRIMARY]
GO
