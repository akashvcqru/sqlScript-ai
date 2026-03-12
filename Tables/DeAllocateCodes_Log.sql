/****** Object:  Table [dbo].[DeAllocateCodes_Log]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeAllocateCodes_Log](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Deallot_Codes] [numeric](18, 0) NULL,
	[Entry_Date] [datetime] NULL,
	[Reason] [nvarchar](max) NULL,
	[Ref_No] [nvarchar](50) NULL,
 CONSTRAINT [PK_DeAllocateCodes_Log] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
