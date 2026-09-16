-- Alter script to add ImageUrl column to tbl_NotificationEventSettings and tbl_InstantPushNotifications
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'ImageUrl')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD ImageUrl NVARCHAR(1000) NULL;
    END
END
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_InstantPushNotifications')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_InstantPushNotifications') AND name = 'ImageUrl')
    BEGIN
        ALTER TABLE tbl_InstantPushNotifications ADD ImageUrl NVARCHAR(1000) NULL;
    END
END
GO
