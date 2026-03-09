/****** Object:  Table [dbo].[tbl_Vendorvisekycstatus_120126]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Vendorvisekycstatus_120126](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_consumerId] [int] NULL,
	[Comp_id] [varchar](20) NULL,
	[VRKbl_KYC_status] [int] NULL,
	[Entry_date] [datetime] NULL,
	[Approved_Date] [datetime] NULL,
	[kycremark] [varchar](500) NULL,
	[Referral_Code] [nvarchar](100) NULL,
	[MobileNo] [varchar](100) NULL,
	[Vrkabel_User_Type] [varchar](10) NULL,
	[IsDelete] [int] NOT NULL,
	[IsActive] [int] NOT NULL,
	[Register_Under] [varchar](500) NULL,
	[Name] [varchar](500) NULL,
	[EmailId] [varchar](500) NULL,
	[usercity] [varchar](500) NULL,
	[userpin] [int] NULL,
	[userstate] [varchar](500) NULL,
	[userupi] [varchar](500) NULL,
	[Outlet_name] [varchar](500) NULL,
	[Owner_name] [varchar](500) NULL,
	[Segmanet_name] [varchar](500) NULL,
	[Branddetails] [varchar](max) NULL,
	[Dealer_M_consumerid] [bigint] NULL,
	[shop_file] [nvarchar](1000) NULL,
	[transaction_status] [varchar](300) NULL,
	[dealer_state] [varchar](150) NULL,
	[DealerType] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
