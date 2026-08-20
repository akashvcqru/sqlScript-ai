-- Alter script to add IsSpecialDay and SpecialDayDate columns to tbl_NotificationEventSettings
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'IsSpecialDay')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD IsSpecialDay BIT DEFAULT 0;
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'SpecialDayDate')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD SpecialDayDate DATETIME NULL;
    END
END
GO
