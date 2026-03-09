/****** Object:  Table [dbo].[TDSDeductionUser]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TDSDeductionUser](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[TDSDeduction_Date] [datetime] NOT NULL,
	[MobileNumber] [nvarchar](50) NOT NULL,
	[Amount] [float] NOT NULL,
	[Is_Success] [int] NULL,
	[Companyid] [varchar](30) NOT NULL,
	[M_Consumerid] [int] NOT NULL,
	[Is_Delete] [int] NULL,
	[Remarks] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
