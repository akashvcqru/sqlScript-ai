/****** Object:  Table [dbo].[Temp_Transactions]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_Transactions](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PtransId] [varchar](50) NULL,
	[OrderId] [varchar](100) NULL,
	[Comp_Id] [varchar](50) NULL,
	[ConsumerId] [varchar](50) NULL,
	[Mobile_No] [varchar](12) NULL,
	[Rec_Code1] [varchar](5) NULL,
	[Rec_Code2] [varchar](8) NULL,
	[Amount] [decimal](18, 2) NULL,
	[AccountNo] [varchar](50) NULL,
	[BeneName] [varchar](50) NULL,
	[IFSCCode] [varchar](20) NULL,
	[Status] [varchar](20) NULL,
	[TransactionDate] [nvarchar](max) NULL,
	[ResponseMessage] [nvarchar](max) NULL,
	[CreateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
