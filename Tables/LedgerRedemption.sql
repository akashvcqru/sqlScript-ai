/****** Object:  Table [dbo].[LedgerRedemption]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LedgerRedemption](
	[Date] [datetime] NULL,
	[Date1] [float] NULL,
	[Month] [float] NULL,
	[Year] [float] NULL,
	[Particulars] [nvarchar](255) NULL,
	[VoucherType] [nvarchar](255) NULL,
	[GSTINorUIN] [nvarchar](255) NULL,
	[MobileNo] [nvarchar](255) NULL,
	[CouponScanwithHandlingCharges] [float] NULL
) ON [PRIMARY]
GO
