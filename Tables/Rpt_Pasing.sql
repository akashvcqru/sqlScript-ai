/****** Object:  Table [dbo].[Rpt_Pasing]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rpt_Pasing](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[SeriesName] [nvarchar](50) NULL,
	[Code1] [nvarchar](50) NULL,
	[Batch_No] [nvarchar](50) NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[PrintDate] [datetime] NULL,
	[SerialCode] [nvarchar](50) NULL,
	[Status] [int] NULL,
	[Remarks] [nvarchar](50) NULL,
	[Entry_Date] [datetime] NULL
) ON [PRIMARY]
GO
