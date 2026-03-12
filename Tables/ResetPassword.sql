/****** Object:  Table [dbo].[ResetPassword]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResetPassword](
	[tbl_id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Entry_Date] [datetime] NULL,
	[User_ID] [nvarchar](50) NULL,
	[Encrypt_Value] [nvarchar](50) NULL,
	[Mail_Status] [int] NULL,
 CONSTRAINT [PK_ResetPassword] PRIMARY KEY CLUSTERED 
(
	[tbl_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
