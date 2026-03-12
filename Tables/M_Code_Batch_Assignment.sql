/****** Object:  Table [dbo].[M_Code_Batch_Assignment]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Code_Batch_Assignment](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[M_codeid] [int] NOT NULL,
	[Gen_Date] [datetime] NULL,
	[Code1V] [nvarchar](100) NULL,
	[Code2V] [nvarchar](100) NULL,
	[Use_Count] [int] NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Series_Order] [int] NULL,
	[Series_Serial] [int] NULL,
	[SerialNumber] [nvarchar](100) NOT NULL,
	[Batch_No] [nvarchar](50) NULL,
	[Pro_Name] [nvarchar](200) NULL,
	[Date Of Mfg] [date] NULL,
	[Expire Date] [date] NULL,
	[From] [nvarchar](100) NULL,
	[To] [nvarchar](100) NULL,
	[Total Use] [int] NULL,
	[BatchSerialPosition] [int] NULL,
	[RequestDate] [datetime] NULL,
	[New_SerialCode] [nvarchar](100) NULL,
	[Old_SerialCode] [nvarchar](100) NULL,
	[CreatedDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
