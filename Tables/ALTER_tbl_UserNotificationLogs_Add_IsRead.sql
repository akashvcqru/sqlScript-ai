-- Alter script to add IsRead column to tbl_UserNotificationLogs
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_UserNotificationLogs')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_UserNotificationLogs') AND name = 'IsRead')
    BEGIN
        ALTER TABLE tbl_UserNotificationLogs 
        ADD IsRead BIT NOT NULL CONSTRAINT DF_tbl_UserNotificationLogs_IsRead DEFAULT 0;
    END
END
GO
