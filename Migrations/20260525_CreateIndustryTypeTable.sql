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
    DECLARE @cols NVARCHAR(MAX) = '';
    DECLARE @vals NVARCHAR(MAX) = '';
    DECLARE @checkCol NVARCHAR(100) = '';

    -- Check Industry_Type column
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'Industry_Type') IS NOT NULL
    BEGIN
        SET @cols = @cols + ', [Industry_Type]';
        SET @vals = @vals + ', val';
        SET @checkCol = 'Industry_Type';
    END

    -- Check Industry_Name column
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'Industry_Name') IS NOT NULL
    BEGIN
        SET @cols = @cols + ', [Industry_Name]';
        SET @vals = @vals + ', val';
        IF @checkCol = ''
            SET @checkCol = 'Industry_Name';
    END

    -- Check Industry_Id column (must be specified if present and not an identity column)
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'Industry_Id') IS NOT NULL 
       AND COLUMNPROPERTY(OBJECT_ID('dbo.tbl_Industry_Type'), 'Industry_Id', 'IsIdentity') = 0
    BEGIN
        SET @cols = @cols + ', [Industry_Id]';
        SET @vals = @vals + ', idx';
    END

    -- Check IsActive column
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'IsActive') IS NOT NULL
    BEGIN
        SET @cols = @cols + ', [IsActive]';
        SET @vals = @vals + ', 1';
    END

    -- Check CreatedAt column
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'CreatedAt') IS NOT NULL
    BEGIN
        SET @cols = @cols + ', [CreatedAt]';
        SET @vals = @vals + ', GETDATE()';
    END

    -- Check CreatedDate column
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'CreatedDate') IS NOT NULL
    BEGIN
        SET @cols = @cols + ', [CreatedDate]';
        SET @vals = @vals + ', GETDATE()';
    END

    -- If we have columns to insert and a check column for uniqueness
    IF LEN(@cols) > 0 AND @checkCol <> ''
    BEGIN
        -- Strip leading comma and space
        SET @cols = SUBSTRING(@cols, 3, LEN(@cols) - 2);
        SET @vals = SUBSTRING(@vals, 3, LEN(@vals) - 2);

        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
        INSERT INTO [dbo].[tbl_Industry_Type] (' + @cols + N')
        SELECT ' + @vals + N'
        FROM (
            SELECT val, ROW_NUMBER() OVER (ORDER BY val) AS idx
            FROM (
                VALUES 
                (N''Dairy''),
                (N''FMCG''),
                (N''Home Care''),
                (N''Pharma''),
                (N''Tobacco''),
                (N''Infrastructure''),
                (N''Electronics''),
                (N''Agriculture''),
                (N''Apparel''),
                (N''Beverage''),
                (N''Lubricants''),
                (N''Alcohol''),
                (N''Publishing''),
                (N''Electricals''),
                (N''Automotive''),
                (N''Paint Industry''),
                (N''Personal Care''),
                (N''Construction''),
                (N''Luxury''),
                (N''Fashion''),
                (N''Luxury/Fashion''),
                (N''Nutrition'')
            ) AS temp(val)
        ) AS v
        WHERE val NOT IN (SELECT ' + QUOTENAME(@checkCol) + N' FROM [dbo].[tbl_Industry_Type]);
        ';
        EXEC sp_executesql @sql;
    END

    -- Healing Step 1: If Industry_Name is present and some values are empty/null, populate them from Industry_Type
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'Industry_Name') IS NOT NULL AND COL_LENGTH('dbo.tbl_Industry_Type', 'Industry_Type') IS NOT NULL
    BEGIN
        DECLARE @updateSql NVARCHAR(MAX) = N'
        UPDATE [dbo].[tbl_Industry_Type]
        SET [Industry_Name] = [Industry_Type]
        WHERE [Industry_Name] IS NULL OR [Industry_Name] = '''';
        ';
        EXEC sp_executesql @updateSql;
    END

    -- Healing Step 2: If Industry_Id is present, not identity, and has 0 or duplicates, populate it using Id
    IF COL_LENGTH('dbo.tbl_Industry_Type', 'Industry_Id') IS NOT NULL 
       AND COLUMNPROPERTY(OBJECT_ID('dbo.tbl_Industry_Type'), 'Industry_Id', 'IsIdentity') = 0
    BEGIN
        DECLARE @updateIdSql NVARCHAR(MAX) = N'
        UPDATE [dbo].[tbl_Industry_Type]
        SET [Industry_Id] = [Id]
        WHERE [Industry_Id] IS NULL OR [Industry_Id] = 0;
        ';
        EXEC sp_executesql @updateIdSql;
    END
END
GO
