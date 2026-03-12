/****** Object:  Table [dbo].[Allcation_Demo]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Allcation_Demo](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Email_ID] [nvarchar](50) NULL,
	[Comp_Name] [nvarchar](50) NULL,
	[Contact_No] [nvarchar](50) NULL,
	[Contact_Name] [nvarchar](50) NULL,
	[Packet_Name] [nvarchar](50) NULL,
	[Entry_Date] [datetime] NULL,
	[Entry_Flag] [nvarchar](50) NULL
) ON [PRIMARY]
GO
