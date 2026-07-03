/****** Object:  Table [dbo].[tbl_DeletedUsers]    Script Date: 6/22/2026 4:30:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_DeletedUsers](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [int] NULL,
	[comp_id] [varchar](20) NULL,
	[Entry_date] [datetime] NULL,
	[IsActive] [int] NULL,
	[Updated_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[tbl_DeletedUsers] ADD DEFAULT (getdate()) FOR [Entry_date]
GO
ALTER TABLE [dbo].[tbl_DeletedUsers] ADD DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[tbl_DeletedUsers] ADD DEFAULT (getdate()) FOR [Updated_date]
GO
