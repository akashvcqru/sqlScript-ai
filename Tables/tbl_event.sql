/****** Object:  Table [dbo].[tbl_event]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_event](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[imgpath] [varchar](500) NULL,
	[galerry_id] [int] NULL,
	[event_name] [nvarchar](150) NULL,
	[event_content] [nvarchar](max) NULL,
	[event_date] [nvarchar](150) NULL,
	[created_date] [datetime] NULL,
	[more_images] [nvarchar](max) NULL,
	[img_1] [nvarchar](150) NULL,
	[img_2] [nvarchar](150) NULL,
	[img_3] [nvarchar](150) NULL,
	[img_4] [nvarchar](150) NULL,
	[img_5] [nvarchar](150) NULL,
	[event_city] [nvarchar](150) NULL,
	[event_address] [nvarchar](250) NULL,
	[from_date] [nchar](40) NULL,
	[to_date] [nchar](40) NULL,
	[is_activee] [int] NULL,
 CONSTRAINT [PK__tbl_even__3213E83F0BB8FD81] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
