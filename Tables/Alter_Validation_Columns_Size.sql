USE [Vcqru]
GO

-- Expand validation column sizes to 1000 characters
ALTER TABLE Master_InputFieldsWeb ALTER COLUMN DefaultValidation VARCHAR(1000) NULL;
ALTER TABLE LandingPage_FieldConfig ALTER COLUMN CustomValidation VARCHAR(1000) NULL;
GO
