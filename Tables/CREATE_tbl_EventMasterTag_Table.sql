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

-- Seed Data for Event Tags (Exact 48 tags matching user specification)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_EventMasterTag')
BEGIN
    -- 1-6: claim_approve
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'currentclaimpoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'currentclaimpoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'totalpoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'totalpoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'balancepoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'balancepoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'claimedpoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'claimedpoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_approve' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_approve', 'company');

    -- 7-12: claim_reject
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'currentclaimpoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'currentclaimpoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'totalpoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'totalpoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'balancepoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'balancepoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'claimedpoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'claimedpoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'claim_reject' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('claim_reject', 'company');

    -- 13-17: gift_add
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'gift_add' AND tag_name = 'giftpoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('gift_add', 'giftpoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'gift_add' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('gift_add', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'gift_add' AND tag_name = 'giftname')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('gift_add', 'giftname');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'gift_add' AND tag_name = 'balancepoints')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('gift_add', 'balancepoints');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'gift_add' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('gift_add', 'company');

    -- 18, 21-22: kyc_approve
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_approve' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_approve', 'company');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_approve' AND tag_name = 'kycstatus')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_approve', 'kycstatus');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_approve' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_approve', 'name');

    -- 19, 23-24: kyc_reject
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_reject' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_reject', 'company');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_reject' AND tag_name = 'kycstatus')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_reject', 'kycstatus');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'kyc_reject' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('kyc_reject', 'name');

    -- 20, 25-26: product_add
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'product_add' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('product_add', 'company');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'product_add' AND tag_name = 'productName')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('product_add', 'productName');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'product_add' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('product_add', 'name');

    -- 27-36: Special Day Events
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'diwali_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('diwali_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'diwali_special' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('diwali_special', 'company');

    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'holi_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('holi_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'holi_special' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('holi_special', 'company');

    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'newyear_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('newyear_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'newyear_special' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('newyear_special', 'company');

    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'independence_day_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('independence_day_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'independence_day_special' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('independence_day_special', 'company');

    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'republic_day_special' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('republic_day_special', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'republic_day_special' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('republic_day_special', 'company');

    -- 37-38: instant_broadcast
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'instant_broadcast' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('instant_broadcast', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'instant_broadcast' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('instant_broadcast', 'company');

    -- 39-40: app_rating
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'app_rating' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('app_rating', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'app_rating' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('app_rating', 'company');

    -- 41-44: successfullpayment
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'company');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'Transferamount')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'Transferamount');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'successfullpayment' AND tag_name = 'transactionid')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('successfullpayment', 'transactionid');

    -- 45-48: failpayment
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'name')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'name');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'company')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'company');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'Transferamount')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'Transferamount');
    IF NOT EXISTS (SELECT 1 FROM tbl_EventMasterTag WHERE event_id = 'failpayment' AND tag_name = 'transactionid')
        INSERT INTO tbl_EventMasterTag (event_id, tag_name) VALUES ('failpayment', 'transactionid');
END
GO
