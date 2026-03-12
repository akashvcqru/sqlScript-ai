/****** Object:  Table [dbo].[MobileToAccount_Audit]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MobileToAccount_Audit](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MobileNo] [varchar](10) NOT NULL,
	[Message] [varchar](50) NULL,
	[Name_At_Bank] [varchar](150) NULL,
	[Account_Number] [varchar](30) NULL,
	[IFSC_Code] [varchar](20) NULL,
	[VPA] [varchar](100) NULL,
	[Bank_Reference] [varchar](50) NULL,
	[Requested_At] [datetime] NULL,
	[Completed_At] [datetime] NULL,
	[Source] [varchar](20) NULL,
	[CreatedOn] [datetime] NOT NULL,
 CONSTRAINT [PK_MobileToAccount_Audit] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
