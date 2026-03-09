/****** Object:  Table [dbo].[SubMasterLabelCode]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubMasterLabelCode](
	[SubMasterLabelcodeid] [bigint] NOT NULL,
	[TrackingNo] [int] NULL,
	[LabelRequestId] [nvarchar](50) NULL,
	[code1] [int] NULL,
	[code2] [int] NULL,
	[QrCode] [varbinary](max) NULL,
	[CreatedDate] [datetime] NULL,
	[Createdby] [int] NULL,
	[updatedate] [datetime] NULL,
	[updatedby] [int] NULL,
 CONSTRAINT [PK_SubMasterLabelCode] PRIMARY KEY CLUSTERED 
(
	[SubMasterLabelcodeid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
