-- Migration: Add MonthlyBenefits column to BrandSettings_AI table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[BrandSettings_AI]') AND name = 'MonthlyBenefits')
BEGIN
    ALTER TABLE [dbo].[BrandSettings_AI] ADD [MonthlyBenefits] [nvarchar](max) NULL;
END
GO
