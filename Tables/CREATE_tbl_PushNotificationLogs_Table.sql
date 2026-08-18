-- Table to store push notification logs and FCM return data
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_PushNotificationLogs')
BEGIN
    CREATE TABLE tbl_PushNotificationLogs (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        CompID VARCHAR(100) NOT NULL,
        MConsumerID VARCHAR(100) NULL,
        EventId VARCHAR(100) NULL,
        Title NVARCHAR(500) NULL,
        MessageBody NVARCHAR(MAX) NULL,
        IsSuccess BIT NOT NULL DEFAULT 0,
        Response NVARCHAR(MAX) NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        SentAt DATETIME DEFAULT GETDATE()
    );
END
GO
