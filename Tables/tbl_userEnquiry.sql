/****** Object:  Table [dbo].[tbl_userEnquiry]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_userEnquiry](
	[Enquiry_id] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](100) NOT NULL,
	[Mobileno] [nvarchar](50) NULL,
	[EmailId] [nvarchar](100) NULL,
	[Pincode] [bigint] NULL,
	[City] [nvarchar](70) NULL,
	[State] [nvarchar](70) NULL,
	[Area_Of_Concern] [nvarchar](70) NULL,
	[Entry_date] [nvarchar](70) NULL,
	[status] [bit] NOT NULL,
	[created_at] [datetime] NOT NULL,
	[Comp_ID] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[Enquiry_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
