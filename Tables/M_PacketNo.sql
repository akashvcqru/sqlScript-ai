/****** Object:  Table [dbo].[M_PacketNo]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_PacketNo](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[PacketNo] [nvarchar](15) NULL,
	[IsUsed] [int] NULL
) ON [PRIMARY]
GO
