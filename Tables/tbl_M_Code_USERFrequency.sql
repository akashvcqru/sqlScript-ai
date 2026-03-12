/****** Object:  Table [dbo].[tbl_M_Code_USERFrequency]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_M_Code_USERFrequency](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code1] [int] NULL,
	[Code2] [int] NULL,
	[Series_Order] [int] NULL,
	[Series_Serial] [int] NULL,
	[Frequency] [int] NULL,
	[UserTypeRole] [varchar](50) NULL,
	[AssignPoint] [int] NULL,
	[Use_count] [int] NULL,
	[Pro_id] [nvarchar](50) NULL,
	[Comp_id] [nvarchar](50) NULL,
	[Entry_date] [datetime] NULL,
	[TrackingId] [nvarchar](200) NULL,
	[Isactive] [bit] NULL,
	[Isdelete] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
