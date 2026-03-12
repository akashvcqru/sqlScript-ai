/****** Object:  Table [dbo].[UserData_CroneJob]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserData_CroneJob](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](20) NULL,
	[M_ConsumerId] [int] NOT NULL,
	[kycremark] [nvarchar](200) NULL,
	[ConsumerName] [nvarchar](200) NULL,
	[MobileNo] [nvarchar](20) NULL,
	[DealerCode] [nvarchar](50) NULL,
	[DealerTechnicianId] [nvarchar](50) NULL,
	[VRKbl_KYC_status] [tinyint] NULL,
	[Entry_Date] [datetime] NULL,
	[InsertedDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
