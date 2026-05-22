-- Migration: Create tbl_MultiCompanySettings table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_MultiCompanySettings]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_MultiCompanySettings](
        [Row_Id] [int] IDENTITY(1,1) NOT NULL,
        [Comp_Id] [varchar](50) NOT NULL,
        [SubCompanies] [nvarchar](max) NOT NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_tbl_MultiCompanySettings_IsActive] DEFAULT ((1)),
        [CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_tbl_MultiCompanySettings_CreatedDate] DEFAULT (getdate()),
        [UpdatedDate] [datetime] NULL,
        CONSTRAINT [PK_tbl_MultiCompanySettings] PRIMARY KEY CLUSTERED 
        (
            [Row_Id] ASC
        )
    );
END
GO
