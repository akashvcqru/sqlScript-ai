/****** Object:  Table [dbo].[pro_enqtemp]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pro_enqtemp](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Dial_Mode] [nvarchar](50) NULL,
	[Enq_Date] [datetime] NULL,
	[Mode_Detail] [nvarchar](max) NULL,
	[MobileNo] [nvarchar](15) NULL,
	[Received_Code1] [nvarchar](50) NULL,
	[Received_Code2] [nvarchar](50) NULL,
	[Circle] [nvarchar](50) NULL,
	[Network] [nvarchar](50) NULL,
	[Is_Success] [nvarchar](50) NULL,
	[Device_Token] [nvarchar](max) NULL,
	[IsDraw] [int] NULL,
	[SST_ID] [bigint] NULL,
	[callerdate] [datetime] NULL,
	[callertime] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
