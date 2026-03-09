/****** Object:  Table [dbo].[BSC_Paint_UserdCodeAND_UnusedCode]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BSC_Paint_UserdCodeAND_UnusedCode](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Quarter] [varchar](50) NULL,
	[SalesValue] [money] NULL,
	[comp_id] [varchar](20) NULL,
 CONSTRAINT [PK_QuarterwiseSale] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
