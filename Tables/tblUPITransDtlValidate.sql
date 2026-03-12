/****** Object:  Table [dbo].[tblUPITransDtlValidate]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblUPITransDtlValidate](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](30) NULL,
	[M_Consumerid] [int] NULL,
	[MobileNo] [varchar](13) NULL,
	[ConsumerName] [varchar](69) NULL,
	[ConsumerEmailId] [varchar](69) NULL,
	[Code1] [varchar](6) NULL,
	[Code2] [varchar](8) NULL,
	[Amount] [float] NULL,
	[IsInsetBL] [bit] NULL,
	[CreatedDate] [datetime] NOT NULL
) ON [PRIMARY]
GO
