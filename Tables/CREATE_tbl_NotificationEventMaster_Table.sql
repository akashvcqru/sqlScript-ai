-- Table to store push notification master events and special day definitions
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventMaster')
BEGIN
    CREATE TABLE tbl_NotificationEventMaster (
        Row_id INT IDENTITY(1,1) PRIMARY KEY,
        event_id VARCHAR(100) NOT NULL UNIQUE,       -- e.g. 'claim_approve', 'diwali_special', 'instant_alert'
        event_name VARCHAR(200) NOT NULL,            -- e.g. 'Claim Approval', 'Diwali Greeting', 'Instant Broadcast'
        notification_type VARCHAR(50) DEFAULT 'VCQRUEvent', -- 'VCQRUEvent', 'SpecialDay', 'Instant'
        CreatedDate DATETIME DEFAULT GETDATE()
    );
END
GO

-- Migration if table exists
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventMaster')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('tbl_NotificationEventMaster') AND name = 'notification_type')
    BEGIN
        ALTER TABLE tbl_NotificationEventMaster ADD notification_type VARCHAR(50) DEFAULT 'VCQRUEvent';
    END
END
GO

-- Seed Data for Push Notification Events, Special Days, and Instant Broadcasts
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventMaster')
BEGIN
    -- VCQRU Standard Events
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'claim_approve')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('claim_approve', 'Claim Approval', 'VCQRUEvent');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'claim_reject')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('claim_reject', 'Claim Rejection', 'VCQRUEvent');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'gift_add')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('gift_add', 'Gift Addition', 'VCQRUEvent');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'kyc_approve')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('kyc_approve', 'KYC Approval', 'VCQRUEvent');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'kyc_reject')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('kyc_reject', 'KYC Rejection', 'VCQRUEvent');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'product_add')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('product_add', 'Product Addition', 'VCQRUEvent');

    -- Special Day Events
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'diwali_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('diwali_special', 'Diwali Festival Greeting', 'SpecialDay');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'holi_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('holi_special', 'Holi Festival Greeting', 'SpecialDay');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'newyear_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('newyear_special', 'New Year Greeting', 'SpecialDay');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'independence_day_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('independence_day_special', 'Independence Day Greeting', 'SpecialDay');

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'republic_day_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('republic_day_special', 'Republic Day Greeting', 'SpecialDay');

    -- Instant Broadcast Events
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'instant_broadcast')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, notification_type) VALUES ('instant_broadcast', 'Instant Broadcast Notification', 'Instant');
END
GO
