/****** Object:  Table [dbo].[App_fields]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[App_fields](
	[field_id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [nvarchar](50) NOT NULL,
	[Service_id] [nvarchar](50) NOT NULL,
	[Field_name] [nvarchar](100) NOT NULL,
	[field_status] [int] NULL,
	[Field_value] [nvarchar](100) NULL
) ON [PRIMARY]
GO
