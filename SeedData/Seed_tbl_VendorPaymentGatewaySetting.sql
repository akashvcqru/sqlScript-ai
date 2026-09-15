-- =========================================================================
-- Script: Seed_tbl_VendorPaymentGatewaySetting.sql
-- Description: Detailed HDFC Sandbox & Live + InstantPay configs (only 1 GLOBAL active)
-- =========================================================================


-- 1. INSTANTPAY: GLOBAL ACTIVE (IsActive = 1)
UPDATE tbl_VendorPaymentGatewaySetting
SET IsActive = 1,
    IsTestMode = 1,  -- 1 = Test Mode, 0 = Live Mode
    ConfigJson = N'{
      "Test": {
        "BaseUrl": "https://api.instantpay.in/payments/payout",
        "ClientId": "YWY3OTAzYzNlM2ExZTJlOZh0WjOBBKD33wYkrJweAJ4=",
        "ClientSecret": "d30a82979eae9c531c473cb64a566e894b97548a5dd4db7f99d8a7c985d5bc58",
        "EndpointIp": "20.193.251.23",
        "RequestTemplate": "InstantPay"
      },
      "Live": {
        "BaseUrl": "https://api.instantpay.in/payments/payout",
        "ClientId": "YWY3OTAzYzNlM2ExZTJlOZh0WjOBBKD33wYkrJweAJ4=",
        "ClientSecret": "d30a82979eae9c531c473cb64a566e894b97548a5dd4db7f99d8a7c985d5bc58",
        "EndpointIp": "20.193.251.23",
        "RequestTemplate": "InstantPay"
      }
    }',
    UpdatedDate = GETDATE(),
    UpdatedBy = 'Admin'
WHERE Comp_Id = 'GLOBAL' AND GatewayCode = 'InstantPay';
GO


-- 2. HDFC BANK: GLOBAL STANDBY (IsActive = 0)
-- Real HDFC Sandbox and Production credentials
UPDATE tbl_VendorPaymentGatewaySetting
SET IsActive = 0,    -- 0 = Standby / Inactive (so only 1 GLOBAL is active)
    IsTestMode = 1,  -- 1 = Sandbox Mode, 0 = Live Production Mode
    ConfigJson = N'{
      "Test": {
        "HDFCBaseUrl": "https://api-uat.hdfcbank.com",
        "HDFCScope": "CBXMGRT6",
        "HDFCApiKey": "PNliIxBIhZjP5bYGCdyRQaw5soDLRyr9KOzPmyaJIQ2vo6yR",
        "HDFCAuthorizationKey": "UE5saUl4QkloWmpQNWJZR0NkeVJRYXc1c29ETFJ5cjlLT3pQbXlhSklRMnZvNnlSOkJRQURFNDVCQW5idzZpcHhuM2xveE1zOGMyaWxSZ2EyWUVUa2RDQ3V4UXdVbUR4TThlcXppSDREc1owa28zaXA=",
        "RequestTemplate": "HDFC"
      },
      "Live": {
        "HDFCBaseUrl": "https://apis.hdfc.bank.in",
        "HDFCScope": "VCQRUPCX",
        "HDFCApiKey": "nP1zc0g9KwDlGONMUqIipwI7U6GYAzaUeydjXSR0CBNL6yo8",
        "HDFCAuthorizationKey": "blAxemMwZzlLd0RsR09OTVVxSWlwd0k3VTZHWUF6YVVleWRqWFNSMENCTkw2eW84Ojh5eXNsZGtWRllLTE1CcHFNOGROWE9obUdZRUNSVVRxMmVkRmVxemNnR2xyQWJIdDJkNTFvamZQdDhMZFNxYmM=",
        "RequestTemplate": "HDFC"
      }
    }',
    UpdatedDate = GETDATE(),
    UpdatedBy = 'Admin'
WHERE Comp_Id = 'GLOBAL' AND GatewayCode = 'HDFC';
GO

-- 3. VERIFY: View the clean table
SELECT 
    Id, 
    Comp_Id, 
    GatewayType, 
    GatewayCode, 
    IsActive, 
    IsTestMode, 
    UpdatedDate 
FROM tbl_VendorPaymentGatewaySetting;
GO
