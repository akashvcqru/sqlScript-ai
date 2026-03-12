/****** Object:  Table [dbo].[M_Amc_Offer_Log]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Amc_Offer_Log](
	[TbleID] [bigint] IDENTITY(1,1) NOT NULL,
	[Amc_Offer_ID] [bigint] NULL,
	[Date_From] [datetime] NULL,
	[Date_To] [datetime] NULL,
	[Entry_Date] [datetime] NULL,
	[Manage_By] [nvarchar](150) NULL,
	[Trans_Type] [nvarchar](150) NULL,
	[Remarks] [nvarchar](250) NULL
) ON [PRIMARY]
GO
