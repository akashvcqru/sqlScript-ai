/****** Object:  Table [dbo].[M_Dealer]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Dealer](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Dealer_ID] [nvarchar](50) NULL,
	[Dealer_Name] [nvarchar](150) NULL,
	[Contact_Person] [nvarchar](150) NULL,
	[Mobile_No] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[Address] [nvarchar](max) NULL,
	[City] [nvarchar](50) NULL,
	[IsActive] [numeric](18, 0) NULL,
	[Entry_Date] [nvarchar](50) NULL,
	[Password] [nvarchar](50) NULL,
	[Comp_ID] [nvarchar](50) NULL,
 CONSTRAINT [PK_M_Dealer] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
