/****** Object:  Table [dbo].[M_ServiceSubscriptionTrans]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServiceSubscriptionTrans](
	[SST_Id] [bigint] IDENTITY(1,1) NOT NULL,
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
 CONSTRAINT [PK_M_ServiceSubscriptionTrans] PRIMARY KEY CLUSTERED 
(
	[SST_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
