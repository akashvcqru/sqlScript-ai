-- Table to store log history of Instant Push Notifications sent via SaveNotificationEvents API
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_InstantPushNotifications')
BEGIN
    CREATE TABLE tbl_InstantPushNotifications (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        CompID VARCHAR(100) NOT NULL,
        EventId VARCHAR(100) NOT NULL,
        EventName NVARCHAR(200) NOT NULL,
        Title NVARCHAR(500) NOT NULL,
        Body NVARCHAR(MAX) NOT NULL,
        RedirectUrl NVARCHAR(1000) NULL,
        ImageUrl NVARCHAR(1000) NULL,
        SentAt DATETIME DEFAULT GETDATE(),
        Status VARCHAR(50) DEFAULT 'Success'
    );
END
GO

