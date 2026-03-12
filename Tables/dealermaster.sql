/****** Object:  Table [dbo].[dealermaster]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dealermaster](
	[DealerId] [int] IDENTITY(1,1) NOT NULL,
	[Zone] [varchar](20) NULL,
	[D_State] [varchar](50) NULL,
	[DealerCode] [varchar](20) NULL,
	[DealerType] [varchar](20) NULL,
	[DealerLocation] [varchar](50) NULL,
	[DealerTechnicianId] [varchar](20) NULL,
	[DE_Designation] [varchar](20) NULL,
	[D_Status] [varchar](20) NULL,
	[Created_Date] [datetime] NULL,
	[Created_By] [bigint] NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_By] [bigint] NULL
) ON [PRIMARY]
GO
