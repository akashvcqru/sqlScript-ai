/****** Object:  Table [dbo].[tbl_Loyalitypointsidentity]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Loyalitypointsidentity](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code1] [int] NULL,
	[Code2] [int] NULL,
	[MobileNo] [nvarchar](20) NULL,
	[Points] [int] NULL,
	[Cash] [int] NULL,
	[Compid] [varchar](20) NULL,
	[Rankno] [int] NULL,
	[BLoyalty_PointEarnedID] [bigint] NULL,
	[Updatedate] [varchar](100) NULL,
	[Entry_date] [datetime] NULL,
	[Is_correct] [bit] NULL,
	[UserId] [varchar](100) NULL,
	[NoofRecordfindduplicate] [int] NULL,
	[NoOfRecoredUpdate] [int] NULL,
	[Remarks] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
