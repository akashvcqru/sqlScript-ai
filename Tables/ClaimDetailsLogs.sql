/****** Object:  Table [dbo].[ClaimDetailsLogs]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClaimDetailsLogs](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ClaimId] [bigint] NOT NULL,
	[Comp_id] [varchar](100) NOT NULL,
	[M_ConsumerId] [bigint] NOT NULL,
	[UserType] [varchar](100) NULL,
	[PreviusStatus] [int] NULL,
	[CurrentStatus] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[Remarks] [nvarchar](1000) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
