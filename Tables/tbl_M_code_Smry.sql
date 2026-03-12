/****** Object:  Table [dbo].[tbl_M_code_Smry]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_M_code_Smry](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_codeId] [numeric](18, 0) NULL,
	[Received_Code1] [varchar](5) NULL,
	[Received_Code2] [varchar](8) NULL,
	[Pro_ID] [varchar](6) NULL,
	[Comp_ID] [varchar](15) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
