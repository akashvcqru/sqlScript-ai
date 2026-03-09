/****** Object:  Table [dbo].[tempreport]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tempreport](
	[employeeID] [varchar](20) NULL,
	[distributorID] [varchar](20) NULL,
	[State] [varchar](50) NULL,
	[currency_sign] [nvarchar](3) NULL,
	[enq_date] [datetime] NULL,
	[tr_status] [varchar](9) NOT NULL,
	[Amount won] [nvarchar](15) NULL,
	[Code check] [nvarchar](50) NULL,
	[code2] [nvarchar](50) NULL,
	[Product] [nvarchar](50) NULL
) ON [PRIMARY]
GO
