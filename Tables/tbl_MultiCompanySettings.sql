SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
