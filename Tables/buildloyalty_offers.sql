/****** Object:  Table [dbo].[buildloyalty_offers]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[buildloyalty_offers](
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[m_consumerid] [int] NOT NULL,
	[points] [int] NULL,
	[iscash] [int] NULL,
	[servicename] [varchar](50) NULL,
	[updateddate] [datetime] NULL,
 CONSTRAINT [PK_buildloyalty_offers] PRIMARY KEY CLUSTERED 
(
	[row_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
