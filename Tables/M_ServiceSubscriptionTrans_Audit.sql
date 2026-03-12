/****** Object:  Table [dbo].[M_ServiceSubscriptionTrans_Audit]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServiceSubscriptionTrans_Audit](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[SST_Id] [bigint] NOT NULL,
	[Subscribe_Id] [nvarchar](50) NOT NULL,
	[Points] [numeric](18, 0) NULL,
	[IsCashConvert] [int] NULL,
	[IsCash] [numeric](18, 0) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[Entry_Date] [datetime] NULL,
	[Update_Flag_H] [numeric](18, 0) NULL,
	[Update_Flag_E] [numeric](18, 0) NULL,
	[Comments] [nvarchar](150) NULL,
	[Frequency] [int] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[IsDraw] [int] NULL,
	[IsReferral] [int] NULL,
	[DrawDate] [datetime] NULL,
	[WarrantyPeriod] [int] NULL,
	[AmtType] [varchar](12) NULL,
	[Minval] [numeric](18, 0) NULL,
	[Maxval] [numeric](18, 0) NULL,
	[totalamont] [numeric](18, 0) NULL,
	[Created_Date] [datetime] NULL,
	[Created_By] [varchar](50) NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_By] [varchar](50) NULL,
	[Remarks] [varchar](100) NULL
) ON [PRIMARY]
GO
