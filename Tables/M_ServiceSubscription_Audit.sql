/****** Object:  Table [dbo].[M_ServiceSubscription_Audit]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServiceSubscription_Audit](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[Subscribe_Id] [nvarchar](50) NOT NULL,
	[Service_ID] [nvarchar](10) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Plan_ID] [nvarchar](50) NULL,
	[PlanName] [nvarchar](150) NULL,
	[PlanMasterPeriod] [numeric](18, 0) NULL,
	[PlanSalePeriod] [numeric](18, 0) NULL,
	[PlanMasterPrice] [numeric](18, 0) NULL,
	[PlanSalePrice] [numeric](18, 0) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[IsAdminVerify] [int] NULL,
	[TransType] [nvarchar](50) NULL,
	[start_order] [int] NULL,
	[start_series] [int] NULL,
	[end_order] [int] NULL,
	[end_series] [int] NULL,
	[Created_Date] [datetime] NULL,
	[Created_By] [varchar](50) NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_By] [varchar](50) NULL,
	[Remarks] [varchar](100) NULL
) ON [PRIMARY]
GO
