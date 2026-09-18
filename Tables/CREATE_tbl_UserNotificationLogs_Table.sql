-- Table to store detailed notification log history for each user with templates and resolved body
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_UserNotificationLogs')
BEGIN
    CREATE TABLE tbl_UserNotificationLogs (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        CompID VARCHAR(100) NOT NULL,
        MConsumerID VARCHAR(100) NULL,
        ConsumerName NVARCHAR(200) NULL,
        EventId VARCHAR(100) NULL,
        TitleTemplate NVARCHAR(500) NULL,
        BodyTemplate NVARCHAR(MAX) NULL,
        Title NVARCHAR(500) NULL,
        Body NVARCHAR(MAX) NULL,
        FCMToken VARCHAR(500) NULL,
        IsSuccess BIT NOT NULL DEFAULT 0,
        ErrorMessage NVARCHAR(MAX) NULL,
        IsRead BIT NOT NULL DEFAULT 0,
        SentAt DATETIME DEFAULT GETDATE()
    );

    CREATE NONCLUSTERED INDEX IX_tbl_UserNotificationLogs_Comp_User 
    ON tbl_UserNotificationLogs(CompID, MConsumerID, SentAt DESC);
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_UserNotificationLogs') AND name = 'IsRead')
    BEGIN
        ALTER TABLE tbl_UserNotificationLogs 
        ADD IsRead BIT NOT NULL CONSTRAINT DF_tbl_UserNotificationLogs_IsRead DEFAULT 0;
    END
END
GO

