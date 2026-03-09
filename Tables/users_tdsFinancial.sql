/****** Object:  Table [dbo].[users_tdsFinancial]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users_tdsFinancial](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Entry_Date] [datetime] NOT NULL,
	[Update_Date] [datetime] NOT NULL,
	[MobileNumber] [nvarchar](50) NOT NULL,
	[Amount] [float] NOT NULL,
	[Companyid] [varchar](30) NOT NULL,
	[M_Consumerid] [int] NOT NULL,
	[Is_Active] [int] NULL,
	[Remarks] [varchar](255) NULL
) ON [PRIMARY]
GO
