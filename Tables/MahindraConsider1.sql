/****** Object:  Table [dbo].[MahindraConsider1]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MahindraConsider1](
	[Searies_Name] [nvarchar](255) NULL,
	[OilVendor] [nvarchar](255) NULL,
	[CompleteCode] [float] NULL,
	[ProductName] [nvarchar](255) NULL,
	[Use_Count] [nvarchar](255) NULL,
	[Duplicatein2ndLot] [float] NULL,
	[Consideredin3rdLot] [float] NULL,
	[AssignValue] [float] NULL,
	[CreditedAmount] [float] NULL,
	[As3rdlot] [bit] NOT NULL
) ON [PRIMARY]
GO
