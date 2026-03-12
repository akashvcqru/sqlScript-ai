/****** Object:  Table [dbo].[WhatsApp_RegField]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WhatsApp_RegField](
	[RegField_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [varchar](20) NULL,
	[Service_id] [varchar](20) NULL,
	[Field_name] [varchar](100) NULL,
	[field_status] [int] NULL,
	[Field_value] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[RegField_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
