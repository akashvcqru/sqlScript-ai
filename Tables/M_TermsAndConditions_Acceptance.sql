/****** Object:  Table [dbo].[M_TermsAndConditions_Acceptance]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_TermsAndConditions_Acceptance](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MobileNo] [varchar](20) NOT NULL,
	[Comp_Id] [varchar](20) NOT NULL,
	[IsAccepted] [bit] NOT NULL,
	[AcceptedOn] [datetime] NULL,
	[CreatedOn] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
