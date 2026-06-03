-- Migration: Create tbl_PincodeDetails table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_PincodeDetails]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_PincodeDetails](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Pincode] [varchar](10) NOT NULL UNIQUE,
        [State] [nvarchar](100) NULL,
        [City] [nvarchar](100) NULL,
        [CreatedAt] [datetime] NOT NULL CONSTRAINT [DF_tbl_PincodeDetails_CreatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_tbl_PincodeDetails] PRIMARY KEY CLUSTERED 
        (
            [Id] ASC
        )
    );
END
GO
