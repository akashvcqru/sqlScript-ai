-- Seed initial standard notification events and special day greeting events into tbl_NotificationEventSettings
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_NotificationEventSettings')
BEGIN
    -- 1. claim_approve
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'claim_approve')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'claim_approve', 'Claim Approval', N'Claim Approved! 🎉', N'Dear {ConsumerName}, your claim of Rs. {Amount} has been approved successfully.', 1, 1, 0, NULL);

    -- 2. claim_reject
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'claim_reject')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'claim_reject', 'Claim Rejection', N'Claim Status Update ❌', N'Dear {ConsumerName}, your claim has been rejected. Reason: {RejectReason}.', 1, 1, 0, NULL);

    -- 3. gift_add
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'gift_add')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'gift_add', 'Gift Addition', N'New Gift Available! 🎁', N'A new gift {GiftName} has been added to our catalog. Redeem your rewards now!', 1, 1, 0, NULL);

    -- 4. kyc_approve
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'kyc_approve')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'kyc_approve', 'KYC Approval', N'KYC Verified Successfully! ✅', N'Dear {ConsumerName}, your KYC details have been verified and approved.', 1, 1, 0, NULL);

    -- 5. kyc_reject
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'kyc_reject')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'kyc_reject', 'KYC Rejection', N'KYC Verification Update ⚠️', N'Dear {ConsumerName}, your KYC verification was rejected. Reason: {RejectReason}.', 1, 1, 0, NULL);

    -- 6. product_add
    IF NOT EXISTS (SELECT 1 FROM tbl_NotificationEventSettings WHERE CompID = 'Comp-1555' AND EventId = 'product_add')
        INSERT INTO tbl_NotificationEventSettings (CompID, EventId, EventName, TitleTemplate, BodyTemplate, IsEnabled, SendPushNotification, IsSpecialDay, SpecialDayDate)
        VALUES ('Comp-1555', 'product_add', 'Product Addition', N'New Product Added! 🛍️', N'A new product {ProductName} has been added to our catalog.', 1, 1, 0, NULL);

    -- 7. Special Day Events
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
