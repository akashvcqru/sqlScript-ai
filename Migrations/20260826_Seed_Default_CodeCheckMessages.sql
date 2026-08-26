-- =============================================
-- Migration: Seed Global Default Code Check Messages
-- Date: 2026-08-26
-- Description: Seeds fallback messages under Comp_Id = 'Default' for all services (SRV1001, SRV1029, and global fallback)
-- =============================================

USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Default messages for SRV1001 (Build Loyalty / Points)
IF NOT EXISTS (SELECT 1 FROM LandingPage_CodeCheckMessages WHERE Comp_Id = 'Default' AND Service_Id = 'SRV1001' AND Message_Type = 'Success')
BEGIN
    INSERT INTO [dbo].[LandingPage_CodeCheckMessages] 
    (Comp_Id, Service_Id, Message_Type, Message_Text, IsActive, CreatedDate, CreatedBy)
    VALUES 
        ('Default', 'SRV1001', 'Success', 'Congratulations! Your product is genuine and your loyalty points have been credited to your account.', 1, GETDATE(), 'System'),
        ('Default', 'SRV1001', 'AlreadyChecked', 'This code has already been verified earlier. Please scan a new product code.', 1, GETDATE(), 'System'),
        ('Default', 'SRV1001', 'InvalidCode', 'The code you entered is invalid. Please check the 13-digit code on your label.', 1, GETDATE(), 'System'),
        ('Default', 'SRV1001', 'FrequencyLimit', 'You have reached the maximum number of code scans for this period. Please try again later.', 1, GETDATE(), 'System');
END

-- 2. Default messages for SRV1029 (Instant Cashback / UPI)
IF NOT EXISTS (SELECT 1 FROM LandingPage_CodeCheckMessages WHERE Comp_Id = 'Default' AND Service_Id = 'SRV1029' AND Message_Type = 'Success')
BEGIN
    INSERT INTO [dbo].[LandingPage_CodeCheckMessages] 
    (Comp_Id, Service_Id, Message_Type, Message_Text, IsActive, CreatedDate, CreatedBy)
    VALUES 
        ('Default', 'SRV1029', 'Success', 'Congratulations! Your product is authentic. Your cashback will be transferred to your UPI/Bank account.', 1, GETDATE(), 'System'),
        ('Default', 'SRV1029', 'AlreadyChecked', 'This code has already been verified. Please use a different code to claim more rewards.', 1, GETDATE(), 'System'),
        ('Default', 'SRV1029', 'InvalidCode', 'The code you entered is invalid. Please check and try again.', 1, GETDATE(), 'System'),
        ('Default', 'SRV1029', 'FrequencyLimit', 'You have reached the maximum number of code scans for this period. Please try again later.', 1, GETDATE(), 'System');
END

-- 3. Global Default fallback (when Service_Id is NULL)
IF NOT EXISTS (SELECT 1 FROM LandingPage_CodeCheckMessages WHERE Comp_Id = 'Default' AND Service_Id IS NULL AND Message_Type = 'Success')
BEGIN
    INSERT INTO [dbo].[LandingPage_CodeCheckMessages] 
    (Comp_Id, Service_Id, Message_Type, Message_Text, IsActive, CreatedDate, CreatedBy)
    VALUES 
        ('Default', NULL, 'Success', 'Congratulations! Your product is genuine and your reward has been credited.', 1, GETDATE(), 'System'),
        ('Default', NULL, 'AlreadyChecked', 'This code has already been verified earlier. Please contact customer care for assistance.', 1, GETDATE(), 'System'),
        ('Default', NULL, 'InvalidCode', 'The product code you entered is invalid. Please check the 13-digit code on your label.', 1, GETDATE(), 'System');
END
GO

PRINT 'Default code check messages seeded successfully.'
