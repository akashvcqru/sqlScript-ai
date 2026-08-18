-- Table to store FCM device tokens for multi-tenant push notifications
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserFcmTokens')
BEGIN
    CREATE TABLE UserFcmTokens (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        CompID VARCHAR(100) NOT NULL,          -- e.g. 'Comp-1555'
        MConsumerID VARCHAR(100) NOT NULL,     -- e.g. 'CONS-001'
        FCMToken VARCHAR(500) NOT NULL,        -- FCM Device Token
        DeviceType VARCHAR(20) DEFAULT 'android',
        UpdatedAt DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_Comp_User UNIQUE (CompID, MConsumerID, DeviceType)
    );
END
GO
