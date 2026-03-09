/****** Object:  Table [dbo].[tblFundTransferDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblFundTransferDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ReportNumber] [varchar](30) NULL,
	[TotalRecords] [int] NULL,
	[TotalAmount] [int] NULL,
	[DateRange] [varchar](80) NULL,
	[IsFilegenerate] [bit] NULL,
	[FilegeneratedDate] [datetime] NULL,
	[GeneratedBy] [varchar](40) NULL,
	[IsDelete] [bit] NULL,
	[DeletedBy] [varchar](30) NULL,
	[DeleteDate] [datetime] NULL,
	[NeedApproval] [bit] NULL,
	[ApprovalBy] [varchar](15) NULL,
	[ApprovalDate] [datetime] NULL,
	[IsPayoutReleased] [bit] NULL,
	[PayoutReleasedBy] [varchar](30) NULL,
	[TotalPayoutReleasedRecords] [int] NULL,
	[TotalPayoutReleasedAmount] [decimal](18, 2) NULL,
	[PayoutReleasedDate] [datetime] NULL,
	[IsApproved] [bit] NULL,
	[PayoutReleasedPath] [varchar](150) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
