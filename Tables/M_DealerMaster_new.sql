/****** Object:  Table [dbo].[M_DealerMaster_new]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_DealerMaster_new](
	[DealerId] [float] NULL,
	[Zone] [nvarchar](255) NULL,
	[D_State] [nvarchar](255) NULL,
	[DealerCode] [nvarchar](255) NULL,
	[DealerType] [nvarchar](255) NULL,
	[DealerLocation] [nvarchar](255) NULL,
	[DealerTechnicianId] [nvarchar](255) NULL,
	[DE_Designation] [nvarchar](255) NULL,
	[D_Status] [nvarchar](255) NULL,
	[Created_Date] [nvarchar](255) NULL,
	[Created_By] [nvarchar](255) NULL,
	[Updated_Date] [nvarchar](255) NULL,
	[Updated_By] [nvarchar](255) NULL
) ON [PRIMARY]
GO
