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
        NotificationType VARCHAR(50) DEFAULT 'VCQRUEvent', -- 'VCQRUEvent', 'SpecialDay', 'Instant'
        SpecialDayDate DATETIME NULL,
        RedirectUrl NVARCHAR(1000) NULL,
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_Comp_Event UNIQUE (CompID, EventId)
    );
END
GO

-- Also ensure NotificationType, SpecialDayDate, RedirectUrl exist if table already exists
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'NotificationType')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD NotificationType VARCHAR(50) DEFAULT 'VCQRUEvent';
    END
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'SpecialDayDate')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD SpecialDayDate DATETIME NULL;
    END
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventSettings') AND name = 'RedirectUrl')
    BEGIN
        ALTER TABLE tbl_NotificationEventSettings ADD RedirectUrl NVARCHAR(1000) NULL;
    END
END
GO

-- Also ensure NotificationSettings column exists in BrandSettings_AI for quick JSON retrieval
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('BrandSettings_AI') AND name = 'NotificationSettings')
BEGIN
    ALTER TABLE BrandSettings_AI ADD NotificationSettings NVARCHAR(MAX) NULL;
END
GO

-- Seed Initial Standard & Special Day Notification Events for Comp-1555 and Default
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    -- Standard Events
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'claim_approve')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'claim_approve', 'Claim Approval', N'Claim Approved! 🎉', N'Dear {ConsumerName}, your claim of Rs. {Amount} has been approved successfully.', 1, 1, 0, NULL);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'claim_reject')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'claim_reject', 'Claim Rejection', N'Claim Status Update ❌', N'Dear {ConsumerName}, your claim has been rejected. Reason: {RejectReason}.', 1, 1, 0, NULL);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'gift_add')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'gift_add', 'Gift Addition', N'New Gift Available! 🎁', N'A new gift {GiftName} has been added to our catalog. Redeem your rewards now!', 1, 1, 0, NULL);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'kyc_approve')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'kyc_approve', 'KYC Approval', N'KYC Verified Successfully! ✅', N'Dear {ConsumerName}, your KYC details have been verified and approved.', 1, 1, 0, NULL);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'kyc_reject')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'kyc_reject', 'KYC Rejection', N'KYC Verification Update ⚠️', N'Dear {ConsumerName}, your KYC verification was rejected. Reason: {RejectReason}.', 1, 1, 0, NULL);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'product_add')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'product_add', 'Product Addition', N'New Product Added! 🛍️', N'A new product {ProductName} has been added to our catalog.', 1, 1, 0, NULL);

    -- Special Day Events
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'diwali_special')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'diwali_special', 'Diwali Festival Greeting', N'Happy Diwali! 🪔', N'Wishing you and your family a bright and prosperous Happy Diwali!', 1, 1, 1, '2026-11-08');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'holi_special')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'holi_special', 'Holi Festival Greeting', N'Happy Holi! 🎨', N'Wishing you and your family a colorful and joyful Happy Holi!', 1, 1, 1, '2026-03-04');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'newyear_special')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'newyear_special', 'New Year Greeting', N'Happy New Year! ✨', N'Wishing you happiness, success, and good health in the New Year!', 1, 1, 1, '2026-01-01');
END
GO
