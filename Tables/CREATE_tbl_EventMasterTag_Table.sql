-- Table to store tags for Notification Event Master
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_EventMasterTag')
BEGIN
    CREATE TABLE tbl_EventMasterTag (
        Row_id INT IDENTITY(1,1) PRIMARY KEY,
        event_id VARCHAR(100) NOT NULL,
        tag_name VARCHAR(100) NOT NULL,
        CreatedDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_tbl_EventMasterTag UNIQUE (event_id, tag_name)
    );
END
GO

-- Seed Data for Event Tags
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_EventMasterTag')
BEGIN
    -- claim_approve
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'points')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'points');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'name');

    -- claim_reject
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'points')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'points');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'name');

    -- gift_add
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'gift_add' AND tag_name = 'points')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('gift_add', 'points');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'gift_add' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('gift_add', 'name');

    -- kyc_approve
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_approve' AND tag_name = 'kycstatus')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_approve', 'kycstatus');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_approve' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_approve', 'name');

    -- kyc_reject
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_reject' AND tag_name = 'kycstatus')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_reject', 'kycstatus');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_reject' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_reject', 'name');

    -- product_add
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'product_add' AND tag_name = 'productName')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('product_add', 'productName');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'product_add' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('product_add', 'name');

    -- Special Day & Instant Events
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'diwali_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('diwali_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'holi_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('holi_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'newyear_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('newyear_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'independence_day_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('independence_day_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'republic_day_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('republic_day_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'instant_broadcast' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('instant_broadcast', 'name');

    -- Payment Events
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'company');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'amount')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'amount');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'transactionid')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'transactionid');

    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'company');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'amount')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'amount');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'transactionid')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'transactionid');
END
GO
