-- Rollback: Drop SetRequestLabelLimit table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetRequestLabelLimit]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[SetRequestLabelLimit];
END
GO
