/****** Object:  Table [dbo].[BigDataSendFromCompany]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BigDataSendFromCompany](
	[BigDataCompanyid] [bigint] IDENTITY(1,1) NOT NULL,
	[BigDataId] [int] NULL,
	[comp_id] [nvarchar](50) NULL,
	[M_Consumerid] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[Createdby] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedBy] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_BigDataSendFromCompany] PRIMARY KEY CLUSTERED 
(
	[BigDataCompanyid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
