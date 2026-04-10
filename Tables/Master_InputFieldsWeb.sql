SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Master_InputFieldsWeb] (
    FieldId INT IDENTITY(1,1) PRIMARY KEY,
    FieldName VARCHAR(100),        -- MobileNo, Name, City
    Label VARCHAR(150),
    FieldType VARCHAR(50),         -- text, number, date, file, dropdown
    DefaultValidation VARCHAR(200),-- regex or rules
    Placeholder VARCHAR(150),
    MaxLength INT,
    IsActive BIT DEFAULT 1,
    createdby VARCHAR(50),
    updatedby VARCHAR(50),
    created_date DATETIME DEFAULT GETDATE(),
    updated_date DATETIME
);
GO
