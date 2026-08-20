-- Migration script to add NotificationType column to tbl_NotificationEventSettings
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'NotificationType')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD NotificationType VARCHAR(50) DEFAULT 'VCQRUEvent';
    END
END
GO

-- Populate NotificationType based on existing IsSpecialDay column if present
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'IsSpecialDay')
BEGIN
    UPDATE tbl_NotificationEventSettings 
    SET NotificationType = 'SpecialDay' 
    WHERE IsSpecialDay = 1 AND (NotificationType IS NULL OR NotificationType = 'VCQRUEvent');
END
GO
