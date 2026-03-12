/****** Object:  Table [dbo].[UserClaimPreferences]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserClaimPreferences](
	[Row_Id] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [int] NOT NULL,
	[Comp_Id] [varchar](20) NOT NULL,
	[ClaimMode] [varchar](20) NOT NULL,
	[Created_At] [datetime] NOT NULL,
 CONSTRAINT [PK_UserClaimPreferences] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
