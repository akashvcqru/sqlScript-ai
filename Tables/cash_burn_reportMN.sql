/****** Object:  Table [dbo].[cash_burn_reportMN]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cash_burn_reportMN](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[SchemeName] [nvarchar](50) NOT NULL,
	[Lot] [nvarchar](20) NOT NULL,
	[RedemptionPeriod] [nvarchar](30) NOT NULL,
	[ApprovalDate] [date] NULL,
	[CountOfUser] [int] NOT NULL,
	[ApprovalGrossAmount] [decimal](18, 2) NOT NULL,
	[GrossAmount] [decimal](18, 2) NULL,
	[TDSDeducted] [decimal](18, 2) NULL,
	[NetPaidAmount] [decimal](18, 2) NULL,
	[NoOfUserPaidSuccessful] [int] NOT NULL,
	[TransactionDates] [nvarchar](200) NULL,
	[CreatedDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
