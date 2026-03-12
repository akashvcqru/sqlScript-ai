/****** Object:  Table [dbo].[M_Promotional]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Promotional](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Promo_ID] [nvarchar](50) NOT NULL,
	[Promo_Name] [nvarchar](50) NOT NULL,
	[Time_Days] [nvarchar](50) NULL,
	[Amount] [numeric](18, 2) NULL,
	[Plan_Discount] [numeric](18, 2) NULL,
	[Entry_Date] [datetime] NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK__M_Promotional__57A801BA] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
