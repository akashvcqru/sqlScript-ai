/****** Object:  Table [dbo].[CodeCheckMahEmp]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CodeCheckMahEmp](
	[completecode] [float] NULL,
	[status] [nvarchar](255) NULL,
	[Mobile_Number] [nvarchar](255) NULL,
	[amount_won] [float] NULL,
	[mode_of_verification] [nvarchar](255) NULL,
	[technicianid] [nvarchar](255) NULL,
	[dealercode] [nvarchar](255) NULL
) ON [PRIMARY]
GO
