/****** Object:  Table [dbo].[Pro_Enq]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pro_Enq](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Dial_Mode] [nvarchar](50) NULL,
	[Enq_Date] [datetime] NULL,
	[Mode_Detail] [nvarchar](140) NULL,
	[MobileNo] [nvarchar](50) NULL,
	[Received_Code1] [nvarchar](5) NULL,
	[Received_Code2] [nvarchar](8) NULL,
	[Circle] [nvarchar](50) NULL,
	[Network] [nvarchar](50) NULL,
	[Is_Success] [nvarchar](50) NULL,
	[Device_Token] [nvarchar](255) NULL,
	[IsDraw] [int] NULL,
	[SST_ID] [bigint] NULL,
	[callerdate] [datetime] NULL,
	[callertime] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[state] [varchar](50) NULL,
	[Others] [varchar](255) NULL,
	[Retailer_Name] [varchar](255) NULL,
	[Image] [varchar](max) NULL,
	[Latitude] [varchar](50) NULL,
	[Longitude] [varchar](50) NULL,
	[IsActive] [int] NOT NULL,
	[IsDelete] [int] NOT NULL,
	[Created_Date] [datetime] NULL,
	[Created_By] [varchar](50) NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_By] [varchar](50) NULL,
	[Remarks] [varchar](100) NULL,
	[Comp_ID] [varchar](30) NULL,
	[IsVerified] [bit] NULL,
	[PinCode] [nvarchar](20) NULL,
 CONSTRAINT [PK_Pro_Enq] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
