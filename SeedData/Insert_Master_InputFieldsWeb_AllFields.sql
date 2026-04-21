USE [Vcqru]
GO

-- =============================================
-- Script: Insert Master_InputFieldsWeb Fields
-- Description: Insert all field definitions for landing page forms
-- Created: 2026-04-16
-- Updated By: admin@vcqru.com
-- =============================================

SET IDENTITY_INSERT [dbo].[Master_InputFieldsWeb] OFF;
GO

-- Insert all field definitions
INSERT INTO [dbo].[Master_InputFieldsWeb] (
    FieldName, 
    Label, 
    FieldType, 
    DefaultValidation, 
    Placeholder, 
    MaxLength, 
    IsActive, 
    createdby, 
    created_date
)
VALUES
-- Core Identity Fields
('vCode', '13 Digit Code', 'text', '^[0-9]{13}$', 'Enter 13 digit code', 13, 1, 'admin@vcqru.com', GETDATE()),
('mobile', 'Mobile Number', 'text', '^[0-9]{10}$', 'Enter 10 digit mobile number', 10, 1, 'admin@vcqru.com', GETDATE()),
('EmailAddrs', 'Email Address', 'email', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', 'Enter email address', 100, 1, 'admin@vcqru.com', GETDATE()),

-- Personal Information Fields
('name', 'Name', 'text', NULL, 'Enter full name', 100, 1, 'admin@vcqru.com', GETDATE()),
('gender', 'Gender', 'dropdown', NULL, 'Select gender', 20, 1, 'admin@vcqru.com', GETDATE()),
('Age', 'Age', 'number', '^[0-9]{1,3}$', 'Enter age', 3, 1, 'admin@vcqru.com', GETDATE()),
('designation', 'Designation', 'text', NULL, 'Enter designation', 100, 1, 'admin@vcqru.com', GETDATE()),

-- Address Fields
('Address', 'Address', 'text', NULL, 'Enter full address', 200, 1, 'admin@vcqru.com', GETDATE()),
('PinCode', 'Pin Code', 'text', '^[0-9]{6}$', 'Enter 6 digit pin code', 6, 1, 'admin@vcqru.com', GETDATE()),
('city', 'City', 'text', NULL, 'Enter city name', 50, 1, 'admin@vcqru.com', GETDATE()),
('state', 'State', 'text', NULL, 'Enter state name', 50, 1, 'admin@vcqru.com', GETDATE()),
('district', 'District', 'text', NULL, 'Enter district name', 50, 1, 'admin@vcqru.com', GETDATE()),
('village', 'Village', 'text', NULL, 'Enter village name', 50, 1, 'admin@vcqru.com', GETDATE()),
('country', 'Country', 'text', NULL, 'Enter country name', 50, 1, 'admin@vcqru.com', GETDATE()),

-- Bank Account Fields
('AccountNumber', 'Account Number', 'text', '^[0-9]{9,18}$', 'Enter bank account number', 18, 1, 'admin@vcqru.com', GETDATE()),
('AccountHolderName', 'Account Holder Name', 'text', NULL, 'Enter account holder name', 100, 1, 'admin@vcqru.com', GETDATE()),
('BankName', 'Bank Name', 'text', NULL, 'Enter bank name', 100, 1, 'admin@vcqru.com', GETDATE()),
('BranchName', 'Branch Name', 'text', NULL, 'Enter branch name', 100, 1, 'admin@vcqru.com', GETDATE()),
('IfscCode', 'IFSC Code', 'text', '^[A-Z]{4}0[A-Z0-9]{6}$', 'Enter IFSC code', 11, 1, 'admin@vcqru.com', GETDATE()),
('UPI', 'UPI Address', 'text', NULL, 'Enter UPI address', 100, 1, 'admin@vcqru.com', GETDATE()),

-- Government ID Fields
('pancard_number', 'PAN Card Number', 'text', '^[A-Z]{5}[0-9]{4}[A-Z]{1}$', 'Enter PAN card number', 10, 1, 'admin@vcqru.com', GETDATE()),
('aadhar_number', 'Aadhar Number', 'text', '^[0-9]{12}$', 'Enter 12 digit Aadhar number', 12, 1, 'admin@vcqru.com', GETDATE()),

-- Referral and Dealer Fields
('Refercode', 'Referral Code', 'text', NULL, 'Enter referral code', 50, 1, 'admin@vcqru.com', GETDATE()),
('dealerid', 'Dealer ID', 'text', NULL, 'Enter dealer ID', 50, 1, 'admin@vcqru.com', GETDATE()),
('dealermobile', 'Dealer Mobile', 'text', '^[0-9]{10}$', 'Enter dealer mobile number', 10, 1, 'admin@vcqru.com', GETDATE()),

-- Employee and Distribution Fields
('empId', 'Employee ID', 'text', NULL, 'Enter employee ID', 50, 1, 'admin@vcqru.com', GETDATE()),
('disId', 'Distributor ID', 'text', NULL, 'Enter distributor ID', 50, 1, 'admin@vcqru.com', GETDATE()),

-- Business/Shop Fields
('bookname', 'Book Name', 'text', NULL, 'Enter book name', 100, 1, 'admin@vcqru.com', GETDATE()),
('bookShop', 'Book Shop', 'text', NULL, 'Enter book shop name', 100, 1, 'admin@vcqru.com', GETDATE()),
('ccenter', 'Collection Center', 'text', NULL, 'Enter collection center', 100, 1, 'admin@vcqru.com', GETDATE()),
('SellerName', 'Seller Name', 'text', NULL, 'Enter seller name', 100, 1, 'admin@vcqru.com', GETDATE()),
('Shopname', 'Shop Name', 'text', NULL, 'Enter shop name', 100, 1, 'admin@vcqru.com', GETDATE()),

-- Security and Verification Fields
('passcode', 'Passcode', 'password', NULL, 'Enter passcode', 50, 1, 'admin@vcqru.com', GETDATE()),

-- Feedback Fields
('Rating', 'Rating', 'number', '^[1-5]$', 'Rate from 1 to 5', 1, 1, 'admin@vcqru.com', GETDATE()),
('Feedback', 'Feedback', 'textarea', NULL, 'Enter your feedback', 500, 1, 'admin@vcqru.com', GETDATE()),

-- Additional Fields
('Other_Role', 'Other Role', 'text', NULL, 'Enter other role', 100, 1, 'admin@vcqru.com', GETDATE()),
('ExtraField1', 'Extra Field 1', 'text', NULL, 'Extra field for future use', 100, 1, 'admin@vcqru.com', GETDATE());

GO

-- Verify insertion
SELECT 
    FieldId,
    FieldName,
    Label,
    FieldType,
    IsActive,
    created_date
FROM [dbo].[Master_InputFieldsWeb]
ORDER BY created_date DESC;

GO
