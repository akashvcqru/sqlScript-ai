/****** Object:  Table [dbo].[M_Code_winner]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Code_winner](
	[M_Code_Winnerid] [int] IDENTITY(1,1) NOT NULL,
	[M_Codeid] [int] NULL,
	[M_GiftCodeid] [int] NULL,
	[IsCoupon] [bit] NULL,
	[IsAdditionalGft] [bit] NULL,
	[Createddate] [datetime] NULL,
	[sst_id] [int] NULL,
 CONSTRAINT [PK_M_Code_winner] PRIMARY KEY CLUSTERED 
(
	[M_Code_Winnerid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
