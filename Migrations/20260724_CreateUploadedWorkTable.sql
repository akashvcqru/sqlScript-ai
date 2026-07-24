-- Migration: Create tbl_UploadedWork table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UploadedWork]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_UploadedWork](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Comp_id] [nvarchar](50) NULL,
        [mobileno] [nvarchar](15) NULL,
        [imgpath] [nvarchar](500) NULL,
        [remark] [nvarchar](1000) NULL,
        [latitude] [nvarchar](50) NULL,
        [logitude] [nvarchar](50) NULL,
        [CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_tbl_UploadedWork_CreatedDate] DEFAULT (getdate()),
        CONSTRAINT [PK_tbl_UploadedWork] PRIMARY KEY CLUSTERED 
        (
            [Id] ASC
        )
    );
END
GO
