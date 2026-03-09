/****** Object:  Table [dbo].[M_CouponProvider]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_CouponProvider](
	[CouponProvider_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CouponProviderName] [nvarchar](250) NULL,
	[CouponProviderEmail] [nvarchar](150) NULL,
	[CouponProviderContactPerson] [nvarchar](150) NULL,
	[CouponProviderContactNo] [nvarchar](20) NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
 CONSTRAINT [PK_M_CouponProvider] PRIMARY KEY CLUSTERED 
(
	[CouponProvider_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
