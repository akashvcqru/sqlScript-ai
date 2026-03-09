/****** Object:  Table [dbo].[Interested_Demo]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Interested_Demo](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Comp_Name] [nvarchar](50) NULL,
	[Comp_Email] [nvarchar](50) NULL,
	[Contact_Person] [nvarchar](50) NULL,
	[Mobile_No] [nvarchar](50) NULL,
	[Reg_Date] [datetime] NULL,
	[Status] [numeric](18, 0) NULL,
	[Contact_Flag] [numeric](18, 0) NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
