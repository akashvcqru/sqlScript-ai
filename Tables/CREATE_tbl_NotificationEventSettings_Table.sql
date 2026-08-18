-- Table to store company-wise notification event configuration and templates
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    CREATE TABLE tbl_NotificationEventSettings (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        CompID VARCHAR(100) NOT NULL,              -- e.g. 'Comp-1555'
        EventId VARCHAR(100) NOT NULL,             -- e.g. 'claim_approved'
        EventName VARCHAR(200) NOT NULL,           -- e.g. 'Claim Approval Alert'
        TitleTemplate NVARCHAR(500) NOT NULL,      -- e.g. 'Claim Approved!'
        BodyTemplate NVARCHAR(MAX) NOT NULL,       -- e.g. 'Dear {ConsumerName}, your claim of Rs. {Amount} has been approved.'
        IsEnabled BIT DEFAULT 1,
        SendPushNotification BIT DEFAULT 1,
        SendSms BIT DEFAULT 0,
        SendWhatsApp BIT DEFAULT 0,
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_Comp_Event UNIQUE (CompID, EventId)
    );
END
GO

-- Also ensure NotificationSettings column exists in BrandSettings_AI for quick JSON retrieval
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('BrandSettings_AI') AND name = 'NotificationSettings')
BEGIN
    ALTER TABLE BrandSettings_AI ADD NotificationSettings NVARCHAR(MAX) NULL;
END
GO
