/****** Object:  Table [dbo].[Tbl_Role_reg]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_Role_reg](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Role_id] [int] NOT NULL,
	[Register_Role_id] [int] NOT NULL,
	[Created_by] [int] NOT NULL,
	[Created_date] [datetime] NOT NULL,
	[Updated_by] [int] NULL,
	[Updated_date] [datetime] NULL
) ON [PRIMARY]
GO
