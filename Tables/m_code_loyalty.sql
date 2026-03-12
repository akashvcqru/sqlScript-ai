/****** Object:  Table [dbo].[m_code_loyalty]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[m_code_loyalty](
	[m_coe_loualtyid] [int] IDENTITY(1,1) NOT NULL,
	[code1] [numeric](5, 0) NULL,
	[code2] [numeric](8, 0) NULL,
	[loyalty] [int] NULL,
	[subscribe_id] [nvarchar](50) NULL,
	[service_id] [nvarchar](50) NULL,
	[pro_id] [nvarchar](50) NULL,
	[entry_date] [datetime] NULL,
 CONSTRAINT [PK_m_code_loyalty] PRIMARY KEY CLUSTERED 
(
	[m_coe_loualtyid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
