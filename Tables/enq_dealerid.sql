/****** Object:  Table [dbo].[enq_dealerid]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[enq_dealerid](
	[enq_dealerid] [int] IDENTITY(1,1) NOT NULL,
	[enq_id] [int] NOT NULL,
	[dealerid] [varchar](50) NOT NULL,
	[dealer_mobile] [varchar](50) NULL,
	[createddate] [datetime] NOT NULL,
 CONSTRAINT [PK_enq_dealerid] PRIMARY KEY CLUSTERED 
(
	[enq_dealerid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
