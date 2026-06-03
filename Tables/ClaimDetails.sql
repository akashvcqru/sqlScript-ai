/****** Object:  Table [dbo].[ClaimDetails]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClaimDetails](
	[Row_id] [int] IDENTITY(1,1) NOT NULL,
	[Claim_date] [datetime] NOT NULL,
	[Mobileno] [varchar](12) NOT NULL,
	[Amount] [float] NULL,
	[document_status] [int] NULL,
	[action_date] [datetime] NULL,
	[Isapproved] [int] NOT NULL,
	[Comp_id] [varchar](50) NULL,
	[vendor_comment] [nvarchar](max) NULL,
	[Issent] [bit] NULL,
	[Gifts_Redeemed] [varchar](100) NULL,
	[Points_Redeemed] [int] NULL,
	[Gift_id] [int] NULL,
	[vruserType] [int] NULL,
	[UPIID] [varchar](50) NULL,
	[PaymentStatus] [varchar](20) NULL,
	[BankRefID] [varchar](50) NULL,
	[TransactionDate] [varchar](30) NULL,
	[PaymentRemarks] [varchar](150) NULL,
	[IsPaid] [bit] NULL,
	[PointsValue] [decimal](18, 2) NULL,
	[ServiceChagrge] [float] NULL,
	[RequestAmmount] [float] NULL,
	[pointcollectindate] [int] NULL,
	[TDSDeduction_Date] [datetime] NOT NULL,
	[tdsAmount] [float] NULL,
	[tdsper] [int] NULL,
	[Claim_mode] [nvarchar](200) NULL,
	[SupervisorValue] [decimal](18, 2) NULL,
	[SupervisorGet] [varchar](50) NULL,
	[SupervisorValueType] [varchar](50) NULL,
	[SupervisorMobileNo] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
