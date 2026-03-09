/****** Object:  Table [dbo].[TrackTraceMaster]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TrackTraceMaster](
	[TrackTraceMasterid] [int] IDENTITY(1,1) NOT NULL,
	[Typeid] [int] NULL,
	[Typevalue] [int] NULL,
	[Compid] [nvarchar](50) NULL,
	[M_ServicesubscriptionTransid] [bigint] NULL,
	[isActive] [bit] NULL,
	[isdelete] [bit] NULL,
	[orderno] [int] NULL,
 CONSTRAINT [PK_SequenceTrackTraceMaster] PRIMARY KEY CLUSTERED 
(
	[TrackTraceMasterid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
