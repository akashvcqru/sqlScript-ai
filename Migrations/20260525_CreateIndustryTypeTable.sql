-- Migration: Create and populate tbl_Industry_Type table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Industry_Type]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_Industry_Type](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Industry_Type] [nvarchar](100) NOT NULL UNIQUE,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_tbl_Industry_Type_IsActive] DEFAULT ((1)),
        [CreatedAt] [datetime] NOT NULL CONSTRAINT [DF_tbl_Industry_Type_CreatedAt] DEFAULT (getdate()),
        CONSTRAINT [PK_tbl_Industry_Type] PRIMARY KEY CLUSTERED 
        (
            [Id] ASC
        )
    );
END
GO

-- Populate unique industry types if they don't already exist
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Industry_Type]') AND type in (N'U'))
BEGIN
    INSERT INTO [dbo].[tbl_Industry_Type] (Industry_Type, IsActive, CreatedAt)
    SELECT val, 1, GETDATE()
    FROM (
        VALUES 
        (N'Dairy'),
        (N'FMCG'),
        (N'Home Care'),
        (N'Pharma'),
        (N'Tobacco'),
        (N'Infrastructure'),
        (N'Electronics'),
        (N'Agriculture'),
        (N'Apparel'),
        (N'Beverage'),
        (N'Lubricants'),
        (N'Alcohol'),
        (N'Publishing'),
        (N'Electricals'),
        (N'Automotive'),
        (N'Paint Industry'),
        (N'Personal Care'),
        (N'Construction'),
        (N'Luxury'),
        (N'Fashion'),
        (N'Luxury/Fashion'),
        (N'Nutrition')
    ) AS v(val)
    WHERE val NOT IN (SELECT Industry_Type FROM [dbo].[tbl_Industry_Type]);
END
GO
