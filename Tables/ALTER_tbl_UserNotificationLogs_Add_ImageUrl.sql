-- Migration script to add ImageUrl column to tbl_UserNotificationLogs table
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_UserNotificationLogs')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_UserNotificationLogs') AND name = 'ImageUrl')
    BEGIN
        ALTER TABLE tbl_UserNotificationLogs ADD ImageUrl NVARCHAR(1000) NULL;
    END
END;
