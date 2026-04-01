SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LandingPage_FieldConfig] (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Comp_Id VARCHAR(50) NOT NULL,
    Service_Id VARCHAR(50) NOT NULL,
    FieldId INT,
    IsRequired BIT DEFAULT 0,
    DisplayOrder INT DEFAULT 0,
    IsVisible BIT DEFAULT 1,
    CustomLabel VARCHAR(150),
    CustomValidation VARCHAR(200),
    DefaultValue VARCHAR(200),
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO
