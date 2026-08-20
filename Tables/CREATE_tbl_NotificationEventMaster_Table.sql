-- Table to store push notification master events and special day definitions
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventMaster')
BEGIN
    CREATE TABLE tbl_NotificationEventMaster (
        Row_id INT IDENTITY(1,1) PRIMARY KEY,
        event_id VARCHAR(100) NOT NULL UNIQUE,       -- e.g. 'claim_approve', 'diwali_special'
        event_name VARCHAR(200) NOT NULL,            -- e.g. 'Claim Approval', 'Diwali Greeting'
        is_special_day BIT DEFAULT 0,                -- 0 for standard push event, 1 for special day
        CreatedDate DATETIME DEFAULT GETDATE()
    );
END
GO

-- Seed Data for Push Notification Events and Special Days
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventMaster')
BEGIN
    -- Standard Events
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'claim_approve')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('claim_approve', 'Claim Approval', 0);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'claim_reject')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('claim_reject', 'Claim Rejection', 0);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'gift_add')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('gift_add', 'Gift Addition', 0);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'kyc_approve')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('kyc_approve', 'KYC Approval', 0);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'kyc_reject')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('kyc_reject', 'KYC Rejection', 0);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'product_add')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('product_add', 'Product Addition', 0);

    -- Special Day Events
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'diwali_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('diwali_special', 'Diwali Festival Greeting', 1);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'holi_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('holi_special', 'Holi Festival Greeting', 1);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'newyear_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('newyear_special', 'New Year Greeting', 1);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'independence_day_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('independence_day_special', 'Independence Day Greeting', 1);

    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventMaster WHERE event_id = 'republic_day_special')
        INSERT INTO tbl_NotificationEventMaster (event_id, event_name, is_special_day) VALUES ('republic_day_special', 'Republic Day Greeting', 1);
END
GO
