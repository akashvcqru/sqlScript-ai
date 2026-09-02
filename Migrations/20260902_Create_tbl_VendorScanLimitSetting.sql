-- =========================================================================
-- Migration: 20260902_Create_tbl_VendorScanLimitSetting.sql
-- Description: Create tbl_VendorScanLimitSetting to store vendor-wise daily code scan limits
-- =========================================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tbl_VendorScanLimitSetting')
BEGIN
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
        CONSTRAINT [PK_tbl_VendorScanLimitSetting] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_tbl_VendorScanLimitSetting_CompId] UNIQUE NONCLUSTERED ([Comp_Id] ASC)
    );

    CREATE NONCLUSTERED INDEX [IX_tbl_VendorScanLimitSetting_CompId_Active] 
    ON [dbo].[tbl_VendorScanLimitSetting] ([Comp_Id], [IsActive]) 
    INCLUDE ([DailyUserScanLimit], [ScanStartTime], [ScanEndTime], [CustomLimitMessage]);
END
GO
