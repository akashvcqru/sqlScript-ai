USE [Vcqru]
GO
/****** Object:  Table [dbo].[DealerDetailMiniMax]    Script Date: 10-09-2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DealerDetailMiniMax](
	[Dealer_ID] [int] IDENTITY(1,1) NOT NULL,
	[Dealer_Name] [nvarchar](100) NOT NULL,
	[Status] [bit] NULL CONSTRAINT [DF_DealerDetailMiniMax_Status] DEFAULT ((1)),
	[Entry_Date] [datetime] NULL CONSTRAINT [DF_DealerDetailMiniMax_Entry_Date] DEFAULT (getdate()),
	[Comp_ID] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Dealer_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Composite Unique Index on (Comp_ID, Dealer_Name) for multi-tenancy
CREATE UNIQUE NONCLUSTERED INDEX [UX_DealerDetailMiniMax_Comp_Dealer] 
ON [dbo].[DealerDetailMiniMax] ([Comp_ID] ASC, [Dealer_Name] ASC)
WHERE [Comp_ID] IS NOT NULL;
GO
