SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Master_InputFieldsWeb]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Master_InputFieldsWeb] (
        FieldId INT IDENTITY(1,1) PRIMARY KEY,
        FieldName VARCHAR(100),        -- MobileNo, Name, City
        Label VARCHAR(150),
        FieldType VARCHAR(50),         -- text, number, date, file, dropdown
        DefaultValidation VARCHAR(200),-- regex or rules
        Placeholder VARCHAR(150),
        MaxLength INT,
        ListOption VARCHAR(1000) NULL,
        IsActive BIT DEFAULT 1,
        createdby VARCHAR(50),
        updatedby VARCHAR(50),
        created_date DATETIME DEFAULT GETDATE(),
        updated_date DATETIME
    );
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Master_InputFieldsWeb]') AND name = 'ListOption')
    BEGIN
        ALTER TABLE [dbo].[Master_InputFieldsWeb] ADD ListOption VARCHAR(1000) NULL;
    END
END
GO
