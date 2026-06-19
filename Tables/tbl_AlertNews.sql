/****** Object:  Table [dbo].[tbl_AlertNews]    Script Date: 6/19/2026 3:39:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_AlertNews](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Case_ID] [varchar](50) NOT NULL,
	[Case_Date] [date] NULL,
	[Year] [int] NULL,
	[Month] [varchar](20) NULL,
	[Country] [nvarchar](100) NULL,
	[State] [nvarchar](100) NULL,
	[City] [nvarchar](100) NULL,
	[Pincode] [varchar](10) NULL,
	[Brand_Name] [nvarchar](250) NULL,
	[Product_Name] [nvarchar](250) NULL,
	[Industry] [nvarchar](150) NULL,
	[Counterfeit_Type] [nvarchar](250) NULL,
	[Case_Type] [nvarchar](150) NULL,
	[Estimated_Value] [nvarchar](100) NULL,
	[Authority] [nvarchar](250) NULL,
	[Arrest_Made] [varchar](10) NULL,
	[Risk_Level] [varchar](50) NULL,
	[Consumer_Health_Risk] [varchar](10) NULL,
	[Suggested_VCQRU_Solution] [nvarchar](250) NULL,
	[Verification_Status] [nvarchar](100) NULL,
	[Verification_Notes] [nvarchar](max) NULL,
	[Source_Link] [nvarchar](max) NULL,
	[Latitude] [varchar](100) NULL,
	[Longitude] [varchar](100) NULL,
	[Entry_Date] [datetime] NULL CONSTRAINT [DF_tbl_AlertNews_Entry_Date] DEFAULT (GETDATE()),
	[Updated_Date] [datetime] NULL,
	[Act_Flag] [bit] NULL CONSTRAINT [DF_tbl_AlertNews_Act_Flag] DEFAULT ((1)),
 CONSTRAINT [PK_tbl_AlertNews] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
