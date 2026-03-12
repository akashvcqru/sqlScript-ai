/****** Object:  Table [dbo].[tbl_Edu_dtls]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Edu_dtls](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [int] NULL,
	[Mobileno] [varchar](13) NULL,
	[Standered] [varchar](100) NULL,
	[Collage_name] [varchar](500) NULL,
	[Bank_name] [varchar](500) NULL,
	[Accountno] [varchar](100) NULL,
	[Ifsc_code] [varchar](30) NULL,
	[Fathername] [varchar](100) NULL,
	[Mothername] [varchar](100) NULL,
	[Entry_date] [datetime] NULL,
	[Marital_status] [int] NULL,
	[DOB] [varchar](20) NULL,
	[Branch_Name] [varchar](60) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
