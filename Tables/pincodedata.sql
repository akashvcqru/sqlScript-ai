/****** Object:  Table [dbo].[pincodedata]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pincodedata](
	[m_consumerid] [int] NULL,
	[pincode] [varchar](20) NULL,
	[state] [nvarchar](40) NULL,
	[district] [nvarchar](80) NULL
) ON [PRIMARY]
GO
