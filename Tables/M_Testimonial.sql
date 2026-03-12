/****** Object:  Table [dbo].[M_Testimonial]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Testimonial](
	[tbl_id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Testimonial_ID] [nvarchar](100) NULL,
	[User_Id] [nvarchar](50) NULL,
	[Testimonial] [nvarchar](max) NULL,
	[Test_Image1] [nvarchar](100) NULL,
	[Test_Image2] [nvarchar](100) NULL,
	[Act_Flg] [tinyint] NULL,
	[Con_Flg] [tinyint] NULL,
	[Del_Flg] [tinyint] NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK_M_Testimonial] PRIMARY KEY CLUSTERED 
(
	[tbl_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
