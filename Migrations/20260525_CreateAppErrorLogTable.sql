-- Migration: Create tbl_AppErrorLog table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AppErrorLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_AppErrorLog](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [DeviceInfo] [nvarchar](max) NULL,
        [ApiResponse] [nvarchar](max) NULL,
        [ApiName] [nvarchar](250) NULL,
        [Username] [nvarchar](250) NULL,
        [UserMobile] [varchar](20) NULL,
        [PageName] [nvarchar](250) NULL,
        [ErrorResponse] [nvarchar](max) NULL,
        [ApplicationType] [varchar](50) NOT NULL,
        [CreatedAt] [datetime] NOT NULL CONSTRAINT [DF_tbl_AppErrorLog_CreatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_tbl_AppErrorLog] PRIMARY KEY CLUSTERED 
        (
            [Id] ASC
        )
    );
END
GO
