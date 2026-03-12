/****** Object:  Table [dbo].[Employee_Meeting]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employee_Meeting](
	[MeetingID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyName] [nvarchar](100) NULL,
	[PersonName] [nvarchar](100) NULL,
	[Email] [nvarchar](50) NULL,
	[MobileNo] [nvarchar](50) NULL,
	[MeetingDate] [datetime] NULL,
	[MeetingTime] [nvarchar](50) NULL,
	[MeetingStatus] [smallint] NULL,
	[FollowUpdate] [datetime] NULL,
	[FollowupTime] [nvarchar](50) NULL,
	[FollowUpPerson] [nvarchar](100) NULL,
	[FollowUpDesignation] [nvarchar](100) NULL,
	[FollowUpEmail] [nvarchar](50) NULL,
	[FollowUpMobile] [nvarchar](50) NULL,
	[VisitStatus] [nvarchar](300) NULL,
	[Employeeid] [int] NULL,
	[EmployeeSupervisor] [int] NULL,
	[MeetingMasterID] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedBy] [int] NULL,
	[IsActive] [bit] NULL,
	[IsDelete] [bit] NULL,
 CONSTRAINT [PK_Employee_Meeting] PRIMARY KEY CLUSTERED 
(
	[MeetingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
