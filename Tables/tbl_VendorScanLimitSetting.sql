/****** Object:  Table [dbo].[tbl_VendorScanLimitSetting]    Script Date: 9/2/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbl_VendorScanLimitSetting](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](20) NOT NULL,
	[DailyUserScanLimit] [int] NOT NULL CONSTRAINT [DF_tbl_VendorScanLimitSetting_DailyUserScanLimit] DEFAULT ((10)),
	[ScanStartTime] [time](0) NULL CONSTRAINT [DF_tbl_VendorScanLimitSetting_ScanStartTime] DEFAULT ('00:00:00'),
	[ScanEndTime] [time](0) NULL CONSTRAINT [DF_tbl_VendorScanLimitSetting_ScanEndTime] DEFAULT ('23:59:59'),
	[CustomLimitMessage] [nvarchar](500) NULL,
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_tbl_VendorScanLimitSetting_IsActive] DEFAULT ((1)),
	[CreatedDate] [datetime] NULL CONSTRAINT [DF_tbl_VendorScanLimitSetting_CreatedDate] DEFAULT (getdate()),
	[UpdatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](50) NULL,
 CONSTRAINT [PK_tbl_VendorScanLimitSetting] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_tbl_VendorScanLimitSetting_CompId] UNIQUE NONCLUSTERED 
(
	[Comp_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_tbl_VendorScanLimitSetting_CompId_Active] 
ON [dbo].[tbl_VendorScanLimitSetting] ([Comp_Id], [IsActive]) 
INCLUDE ([DailyUserScanLimit], [ScanStartTime], [ScanEndTime], [CustomLimitMessage])
GO
