/****** Object:  Table [dbo].[ConsumerPointsCashDetails_010822026]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConsumerPointsCashDetails_010822026](
	[MobileNo] [varchar](20) NULL,
	[Code1] [varchar](100) NULL,
	[Code2] [varchar](100) NULL,
	[Enq_Date] [datetime] NULL,
	[SST_Id] [bigint] NULL,
	[Points] [int] NULL,
	[Cash] [int] NULL,
	[Pro_id] [varchar](100) NULL,
	[Comp_id] [varchar](100) NULL,
	[M_ConsumerId] [int] NULL,
	[Is_Success] [nvarchar](50) NULL,
	[Pro_Name] [nvarchar](200) NULL,
	[Service_ID] [nvarchar](50) NULL,
	[Latitude] [nvarchar](50) NULL,
	[Longitude] [nvarchar](50) NULL,
	[PE_ID] [int] NULL,
	[Dial_Mode] [varchar](60) NULL,
	[employeedid] [varchar](100) NULL,
	[distributedid] [varchar](100) NULL
) ON [PRIMARY]
GO
