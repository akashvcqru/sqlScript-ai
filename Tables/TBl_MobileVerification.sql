/****** Object:  Table [dbo].[TBl_MobileVerification]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBl_MobileVerification](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MobileNumber] [varchar](20) NOT NULL,
	[VerificationCode] [varchar](10) NOT NULL,
	[ExpiryTime] [datetime] NOT NULL,
	[IsVerified] [bit] NULL,
	[VerifiedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
