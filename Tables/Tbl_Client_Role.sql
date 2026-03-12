/****** Object:  Table [dbo].[Tbl_Client_Role]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_Client_Role](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Role] [varchar](50) NOT NULL,
	[Role_Description] [varchar](50) NULL,
	[Note] [varchar](50) NULL,
	[Created_By] [int] NOT NULL,
	[Comp_id] [varchar](50) NULL,
	[Created_Date] [datetime] NULL,
	[Updated_by] [int] NULL,
	[Updated_date] [datetime] NULL
) ON [PRIMARY]
GO
