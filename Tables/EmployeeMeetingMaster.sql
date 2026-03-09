/****** Object:  Table [dbo].[EmployeeMeetingMaster]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeMeetingMaster](
	[Emp_MeetingMasterId] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](100) NULL,
	[EmployeeSupervisor] [int] NULL,
	[Createddate] [datetime] NULL,
	[Createdby] [int] NULL,
 CONSTRAINT [PK_EmployeeMeetingMaster] PRIMARY KEY CLUSTERED 
(
	[Emp_MeetingMasterId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
