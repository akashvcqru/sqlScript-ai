/****** Object:  Table [dbo].[tbl_BuiltLoyaltyErrorLog]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_BuiltLoyaltyErrorLog](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[SST_Id] [int] NULL,
	[M_Consumer_MCOdeid] [bigint] NULL,
	[ErrorMessage] [nvarchar](4000) NULL,
	[ErrorDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
