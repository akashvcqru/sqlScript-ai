/****** Object:  Table [dbo].[tblUPITransactionDetails200226]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblUPITransactionDetails200226](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](30) NULL,
	[M_Consumerid] [int] NULL,
	[MobileNo] [varchar](13) NULL,
	[ConsumerName] [varchar](69) NULL,
	[ConsumerEmailId] [varchar](69) NULL,
	[Code1] [varchar](6) NULL,
	[Code2] [varchar](8) NULL,
	[Amount] [float] NULL,
	[Comm_Amount] [float] NULL,
	[Comm_Type] [bit] NULL,
	[TComm_Amount] [float] NULL,
	[Charge_Amount] [float] NULL,
	[Charge_Type] [bit] NULL,
	[TCharge_Amount] [float] NULL,
	[GstAmount] [float] NULL,
	[RefenceId] [varchar](30) NULL,
	[OrderId] [varchar](30) NULL,
	[Status] [varchar](30) NULL,
	[Remarks] [varchar](70) NULL,
	[FinalStatus] [varchar](30) NULL,
	[FinalRemarks] [varchar](70) NULL,
	[EditDate] [datetime] NULL,
	[ReqDate] [datetime] NULL,
	[UPI_Id] [varchar](70) NULL,
	[Points_Val] [float] NULL,
	[tdsAmount] [float] NULL,
	[tdsper] [int] NULL,
	[TdsType] [varchar](5) NULL,
	[RepocessStatus] [bit] NULL,
	[TicketStatus] [varchar](20) NULL,
	[TicketComment] [varchar](200) NULL,
	[ifsc_code] [nvarchar](20) NULL,
	[account_no] [nvarchar](30) NULL,
	[benef_name] [nvarchar](100) NULL
) ON [PRIMARY]
GO
