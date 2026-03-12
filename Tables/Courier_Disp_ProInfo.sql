/****** Object:  Table [dbo].[Courier_Disp_ProInfo]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Courier_Disp_ProInfo](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Courier_Disp_ID] [nvarchar](50) NOT NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Label_Code] [nvarchar](50) NULL,
	[Label_Name] [nvarchar](50) NULL,
	[Series_From] [nvarchar](50) NULL,
	[Series_To] [nvarchar](50) NULL,
	[Qty] [int] NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK__Courier_Disp_Pro__6442E2C9] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
