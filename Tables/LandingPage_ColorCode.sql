IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[LandingPage]') AND name = 'ColorCode')
BEGIN
    ALTER TABLE [dbo].[LandingPage] ADD [ColorCode] NVARCHAR(50) NULL;
END
GO
