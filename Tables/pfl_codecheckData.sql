/****** Object:  Table [dbo].[pfl_codecheckData]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pfl_codecheckData](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EnqID] [int] NULL,
	[Enq_Date] [datetime] NULL,
	[Is_Success] [int] NULL,
	[Latitude] [nvarchar](50) NULL,
	[Longitude] [nvarchar](50) NULL,
	[IsVerified] [bit] NULL,
	[Dial_Mode] [nvarchar](50) NULL,
	[MobileNo] [nvarchar](20) NULL,
	[SerialNumber] [nvarchar](100) NULL,
	[Pro_Name] [nvarchar](200) NULL,
	[Batch_No] [nvarchar](100) NULL,
	[Code1V] [nvarchar](50) NULL,
	[Code2V] [nvarchar](50) NULL,
	[UniqueCode] [nvarchar](120) NULL,
	[CodeScanStatus] [nvarchar](50) NULL,
	[ImageVerifyStatus] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[Use_Count_Indication] [nvarchar](20) NULL,
	[RiskLevel] [nvarchar](20) NULL,
	[Use_Count] [int] NULL,
	[State] [nvarchar](100) NULL,
	[City] [nvarchar](100) NULL,
	[PinCode] [nvarchar](20) NULL,
	[MfgDate] [date] NULL,
	[ExpiryDate] [date] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[Pro_ID] [varchar](10) NULL,
	[Comp_Id] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
