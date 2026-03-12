/****** Object:  Table [dbo].[M_CodeCouponAssign]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_CodeCouponAssign](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[M_CodeID] [numeric](12, 0) NULL,
	[GiftAssignFlag] [bit] NULL,
	[Couponid] [nvarchar](50) NULL,
	[CouponCode] [nvarchar](50) NULL,
	[EntryDate] [datetime] NULL,
	[RandomOrSequence] [nvarchar](50) NULL,
	[SequenceOrderNo] [int] NULL,
	[M_ServiceRuleid] [bigint] NULL,
	[SST_id] [int] NULL,
	[CouponTransID] [int] NULL,
	[IsUsed] [bit] NULL,
	[IsGiftDelivered] [bit] NULL,
	[IsCheckedForDueDate] [bit] NULL,
 CONSTRAINT [PK_M_CodeCouponAssign] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
