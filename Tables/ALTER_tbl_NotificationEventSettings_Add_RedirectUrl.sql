-- Alter script to add RedirectUrl column to tbl_NotificationEventSettings
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'RedirectUrl')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD RedirectUrl NVARCHAR(1000) NULL;
    END
END
GO
