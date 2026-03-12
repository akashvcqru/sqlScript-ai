/****** Object:  Table [dbo].[tblParticipant]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblParticipant](
	[Id] [int] IDENTITY(10000,1) NOT NULL,
	[ParticipantName] [varchar](70) NULL,
	[PhoneNumber] [varchar](12) NULL,
	[Gender] [varchar](6) NULL,
	[Age] [varchar](3) NULL,
	[Address] [varchar](50) NULL,
	[City] [varchar](50) NULL,
	[State] [varchar](50) NULL,
	[ProofforPurchase] [varchar](200) NULL,
	[Mode] [varchar](13) NULL,
	[IsKycCompleted] [char](1) NULL,
	[ReqDate] [datetime] NULL,
	[EditDate] [datetime] NULL,
	[AgentId] [int] NULL,
	[ProductId] [int] NULL,
	[Comment] [varchar](100) NULL,
	[Pin_code] [varchar](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
