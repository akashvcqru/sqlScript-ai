/****** Object:  Table [dbo].[M_Consumer_Referred]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Consumer_Referred](
	[BReferredUserid] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [bigint] NULL,
	[Referred_M_Consumerid] [bigint] NULL,
 CONSTRAINT [PK_M_Consumer_Referred] PRIMARY KEY CLUSTERED 
(
	[BReferredUserid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
