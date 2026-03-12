/****** Object:  Table [dbo].[duplicateCodeIsseueLog]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[duplicateCodeIsseueLog](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CompID] [varchar](50) NULL,
	[MobileNo] [varchar](20) NULL,
	[SSTID] [varchar](50) NULL,
	[Status] [varchar](100) NULL,
	[ServiceID] [varchar](50) NULL,
	[MConsumer_MCodeID] [varchar](50) NULL,
	[Rec_Code1] [varchar](50) NULL,
	[Rec_Code2] [varchar](50) NULL,
	[Dial_Mode] [varchar](50) NULL,
	[IsCheckedUse_Count] [varchar](20) NULL,
	[Amount] [varchar](50) NULL,
	[CreatedDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
