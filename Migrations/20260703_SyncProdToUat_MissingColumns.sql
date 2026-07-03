-- ============================================================
-- UAT Schema Sync Script
-- Generated: 2026-07-03 14:31:10
-- Adds 349 columns present on PROD but missing on UAT
-- All statements use IF NOT EXISTS -- safe to re-run
-- ============================================================

USE [vcqru];
GO

-- ---- Table: BrandData_MHCroneJob ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[BrandData_MHCroneJob]') AND name = 'Total_Cash_Utilization_Prev')
BEGIN
    ALTER TABLE [dbo].[BrandData_MHCroneJob] ADD [Total_Cash_Utilization_Prev] decimal(18, 2) NULL;
    PRINT 'Added: BrandData_MHCroneJob.Total_Cash_Utilization_Prev';
END
GO

-- ---- Table: ClaimDetails ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails]') AND name = 'IsHighValue')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails] ADD [IsHighValue] bit NOT NULL;
    PRINT 'Added: ClaimDetails.IsHighValue';
END
GO

-- ---- Table: ClaimDetails_26_06_2026 ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Points_Redeemed')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Points_Redeemed] int NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Points_Redeemed';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Service_ID')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Service_ID] varchar(20) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Service_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'SupervisorMobileNo')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [SupervisorMobileNo] varchar(50) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.SupervisorMobileNo';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'TransactionDate')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [TransactionDate] varchar(30) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.TransactionDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'tdsAmount')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [tdsAmount] float NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.tdsAmount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Mobileno')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Mobileno] varchar(12) NOT NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Mobileno';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'PointsValue')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [PointsValue] decimal(18, 2) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.PointsValue';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Claim_date')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Claim_date] datetime NOT NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Claim_date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'vruserType')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [vruserType] int NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.vruserType';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'action_date')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [action_date] datetime NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.action_date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Gift_id')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Gift_id] int NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Gift_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Row_id')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Row_id] int NOT NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Row_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'PaymentRemarks')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [PaymentRemarks] varchar(150) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.PaymentRemarks';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Comp_id')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Comp_id] varchar(50) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Comp_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'tdsper')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [tdsper] int NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.tdsper';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'BankRefID')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [BankRefID] varchar(50) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.BankRefID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'pointcollectindate')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [pointcollectindate] int NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.pointcollectindate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'SupervisorGet')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [SupervisorGet] varchar(50) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.SupervisorGet';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'UPIID')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [UPIID] varchar(50) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.UPIID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'TDSDeduction_Date')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [TDSDeduction_Date] datetime NOT NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.TDSDeduction_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'SupervisorValueType')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [SupervisorValueType] varchar(50) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.SupervisorValueType';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'RequestAmmount')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [RequestAmmount] float NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.RequestAmmount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Gifts_Redeemed')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Gifts_Redeemed] varchar(100) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Gifts_Redeemed';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Amount')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Amount] float NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Amount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'PaymentStatus')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [PaymentStatus] varchar(20) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.PaymentStatus';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Claim_mode')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Claim_mode] nvarchar(200) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Claim_mode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'IsPaid')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [IsPaid] bit NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.IsPaid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Isapproved')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Isapproved] int NOT NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Isapproved';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'vendor_comment')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [vendor_comment] nvarchar(max) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.vendor_comment';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'ServiceChagrge')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [ServiceChagrge] float NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.ServiceChagrge';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'SupervisorValue')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [SupervisorValue] decimal(18, 2) NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.SupervisorValue';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'document_status')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [document_status] int NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.document_status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ClaimDetails_26_06_2026]') AND name = 'Issent')
BEGIN
    ALTER TABLE [dbo].[ClaimDetails_26_06_2026] ADD [Issent] bit NULL;
    PRINT 'Added: ClaimDetails_26_06_2026.Issent';
END
GO

-- ---- Table: Comp_Reg ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'CodeType')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [CodeType] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.CodeType';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'APPURL')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [APPURL] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.APPURL';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'AppName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [AppName] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.AppName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'delete_Remarks')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [delete_Remarks] varchar(500) NULL;
    PRINT 'Added: Comp_Reg.delete_Remarks';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'Confidence_Level')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [Confidence_Level] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.Confidence_Level';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'GrowthAndPartnershipRepesentative')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [GrowthAndPartnershipRepesentative] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.GrowthAndPartnershipRepesentative';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'LandingPageOrApp')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [LandingPageOrApp] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.LandingPageOrApp';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'LandingPageURL')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [LandingPageURL] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.LandingPageURL';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'Validation_Source')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [Validation_Source] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.Validation_Source';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]') AND name = 'BrandName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] ADD [BrandName] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg.BrandName';
END
GO

-- ---- Table: Comp_Reg_03_06_2026 ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'fssai_license_active_flag')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [fssai_license_active_flag] bit NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.fssai_license_active_flag';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'logo_path')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [logo_path] nvarchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.logo_path';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorName] nvarchar(55) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Comp_Type')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Comp_Type] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Comp_Type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Draft_Id')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Draft_Id] int NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Draft_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'gst_BusinessConstitution')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [gst_BusinessConstitution] nvarchar(200) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.gst_BusinessConstitution';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Landline')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Landline] varchar(20) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Landline';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'ResiAddress')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [ResiAddress] nvarchar(255) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.ResiAddress';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'comp_pan_status')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [comp_pan_status] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.comp_pan_status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'SalutationId')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [SalutationId] int NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.SalutationId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'gst_RegistrationDate')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [gst_RegistrationDate] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.gst_RegistrationDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Reg_Date')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Reg_Date] datetime NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Reg_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Pincode')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Pincode] varchar(10) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Pincode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorEmail')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorEmail] varchar(100) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorEmail';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'gst_TaxPayerType')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [gst_TaxPayerType] nvarchar(100) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.gst_TaxPayerType';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'City_ID')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [City_ID] numeric(18, 0) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.City_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'gst_RegistrationStatus')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [gst_RegistrationStatus] bit NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.gst_RegistrationStatus';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Fax')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Fax] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Fax';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorPhoto')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorPhoto] varchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorPhoto';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorAddress')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorAddress] varchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorAddress';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'CompanyIndustry')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [CompanyIndustry] varchar(200) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.CompanyIndustry';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Phone_No')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Phone_No] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Phone_No';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'MsmeNo')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [MsmeNo] nvarchar(20) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.MsmeNo';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'PANCardImage')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [PANCardImage] varchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.PANCardImage';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'CompanyPANDocument')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [CompanyPANDocument] varchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.CompanyPANDocument';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorPan')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorPan] nvarchar(20) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorPan';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'gst_BusinessAddress')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [gst_BusinessAddress] nvarchar(600) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.gst_BusinessAddress';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Delete_Flag')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Delete_Flag] int NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Delete_Flag';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'AadharNumber')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [AadharNumber] varchar(12) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.AadharNumber';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'delete_Remarks')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [delete_Remarks] varchar(500) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.delete_Remarks';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Gstin')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Gstin] nvarchar(20) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Gstin';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Mobile_No')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Mobile_No] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Mobile_No';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'WebSite')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [WebSite] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.WebSite';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Industry_Type')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Industry_Type] varchar(100) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Industry_Type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'CompanyAddress')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [CompanyAddress] varchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.CompanyAddress';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'GSTRegistrationCertificate')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [GSTRegistrationCertificate] varchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.GSTRegistrationCertificate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'FssiNo')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [FssiNo] nvarchar(20) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.FssiNo';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Comp_Cat_Id')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Comp_Cat_Id] numeric(18, 0) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Comp_Cat_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'SignAgreements')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [SignAgreements] varchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.SignAgreements';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'LastLogin')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [LastLogin] datetime NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.LastLogin';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Upgrade_Date')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Upgrade_Date] datetime NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Upgrade_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Email_Vari_Flag')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Email_Vari_Flag] numeric(18, 0) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Email_Vari_Flag';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Address')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Address] nvarchar(max) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Address';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Contact_Person')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Contact_Person] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Contact_Person';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'CurrentStep')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [CurrentStep] int NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.CurrentStep';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Comp_ID')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Comp_ID] nvarchar(50) NOT NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Comp_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Designation')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Designation] varchar(100) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Designation';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'SalesPersonName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [SalesPersonName] nvarchar(200) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.SalesPersonName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Comp_Email')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Comp_Email] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Comp_Email';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'gst_LegalBusinessName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [gst_LegalBusinessName] nvarchar(200) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.gst_LegalBusinessName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'MinLimitAmount')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [MinLimitAmount] decimal(18, 2) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.MinLimitAmount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Update_Flag')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Update_Flag] numeric(18, 0) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Update_Flag';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'comp_pan_type')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [comp_pan_type] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.comp_pan_type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorLastName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorLastName] varchar(100) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorLastName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'gst_TradeName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [gst_TradeName] nvarchar(200) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.gst_TradeName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'IsRetailer')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [IsRetailer] int NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.IsRetailer';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Password')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Password] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Password';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorFatherName')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorFatherName] nvarchar(55) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorFatherName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'StateId')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [StateId] int NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.StateId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'DirectorMobile')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [DirectorMobile] varchar(20) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.DirectorMobile';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Status')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Status] numeric(18, 0) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'CompanyPAN')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [CompanyPAN] varchar(20) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.CompanyPAN';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg_03_06_2026]') AND name = 'Comp_Name')
BEGIN
    ALTER TABLE [dbo].[Comp_Reg_03_06_2026] ADD [Comp_Name] nvarchar(50) NULL;
    PRINT 'Added: Comp_Reg_03_06_2026.Comp_Name';
END
GO

-- ---- Table: ConsumerPointsCashDetails_03_06_2026 ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Pro_id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Pro_id] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Pro_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'expireCodeAmount')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [expireCodeAmount] decimal(18, 2) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.expireCodeAmount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Longitude] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Longitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Is_Success')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Is_Success] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Is_Success';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'SST_Id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [SST_Id] bigint NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.SST_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Service_ID')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Service_ID] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Service_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'distributedid')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [distributedid] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.distributedid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Pro_Name')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Pro_Name] nvarchar(200) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Pro_Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Enq_Date')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Enq_Date] datetime NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Enq_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Points')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Points] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Points';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'MobileNo')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [MobileNo] varchar(20) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.MobileNo';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Latitude] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Latitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Code2')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Code2] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Code2';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'PE_ID')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [PE_ID] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.PE_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Dial_Mode')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Dial_Mode] varchar(60) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Dial_Mode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Comp_id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Comp_id] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Comp_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Cash')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Cash] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Cash';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'Code1')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [Code1] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.Code1';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'M_ConsumerId')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [M_ConsumerId] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.M_ConsumerId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_03_06_2026]') AND name = 'employeedid')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_03_06_2026] ADD [employeedid] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_03_06_2026.employeedid';
END
GO

-- ---- Table: ConsumerPointsCashDetails_04_06_2026tJ ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Pro_Name')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Pro_Name] nvarchar(200) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Pro_Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Code2')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Code2] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Code2';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Latitude] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Latitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Points')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Points] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Points';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Enq_Date')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Enq_Date] datetime NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Enq_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Comp_id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Comp_id] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Comp_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'MobileNo')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [MobileNo] varchar(20) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.MobileNo';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Is_Success')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Is_Success] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Is_Success';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'SST_Id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [SST_Id] bigint NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.SST_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'M_ConsumerId')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [M_ConsumerId] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.M_ConsumerId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Service_ID')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Service_ID] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Service_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Pro_id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Pro_id] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Pro_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'PE_ID')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [PE_ID] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.PE_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Dial_Mode')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Dial_Mode] varchar(60) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Dial_Mode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'distributedid')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [distributedid] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.distributedid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Code1')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Code1] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Code1';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Cash')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Cash] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Cash';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [Longitude] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.Longitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'expireCodeAmount')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [expireCodeAmount] decimal(18, 2) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.expireCodeAmount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_04_06_2026tJ]') AND name = 'employeedid')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_04_06_2026tJ] ADD [employeedid] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_04_06_2026tJ.employeedid';
END
GO

-- ---- Table: ConsumerPointsCashDetails_May ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Enq_Date')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Enq_Date] datetime NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Enq_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'MobileNo')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [MobileNo] varchar(20) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.MobileNo';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Comp_id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Comp_id] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Comp_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'PE_ID')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [PE_ID] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.PE_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Is_Success')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Is_Success] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Is_Success';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'expireCodeAmount')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [expireCodeAmount] decimal(18, 2) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.expireCodeAmount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'SST_Id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [SST_Id] bigint NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.SST_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Pro_id')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Pro_id] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Pro_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Code2')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Code2] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Code2';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Cash')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Cash] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Cash';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Longitude] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Longitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'M_ConsumerId')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [M_ConsumerId] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.M_ConsumerId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Pro_Name')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Pro_Name] nvarchar(200) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Pro_Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Dial_Mode')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Dial_Mode] varchar(60) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Dial_Mode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Service_ID')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Service_ID] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Service_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Code1')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Code1] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Code1';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'employeedid')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [employeedid] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.employeedid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'distributedid')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [distributedid] varchar(100) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.distributedid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Latitude] nvarchar(50) NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Latitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ConsumerPointsCashDetails_May]') AND name = 'Points')
BEGIN
    ALTER TABLE [dbo].[ConsumerPointsCashDetails_May] ADD [Points] int NULL;
    PRINT 'Added: ConsumerPointsCashDetails_May.Points';
END
GO

-- ---- Table: device_typemasterLandingpage ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[device_typemasterLandingpage]') AND name = 'Comp_ID')
BEGIN
    ALTER TABLE [dbo].[device_typemasterLandingpage] ADD [Comp_ID] varchar(50) NULL;
    PRINT 'Added: device_typemasterLandingpage.Comp_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[device_typemasterLandingpage]') AND name = 'device_type')
BEGIN
    ALTER TABLE [dbo].[device_typemasterLandingpage] ADD [device_type] varchar(100) NOT NULL;
    PRINT 'Added: device_typemasterLandingpage.device_type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[device_typemasterLandingpage]') AND name = 'Create_Date')
BEGIN
    ALTER TABLE [dbo].[device_typemasterLandingpage] ADD [Create_Date] datetime NULL;
    PRINT 'Added: device_typemasterLandingpage.Create_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[device_typemasterLandingpage]') AND name = 'IsActive')
BEGIN
    ALTER TABLE [dbo].[device_typemasterLandingpage] ADD [IsActive] bit NULL;
    PRINT 'Added: device_typemasterLandingpage.IsActive';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[device_typemasterLandingpage]') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE [dbo].[device_typemasterLandingpage] ADD [IsDeleted] bit NULL;
    PRINT 'Added: device_typemasterLandingpage.IsDeleted';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[device_typemasterLandingpage]') AND name = 'ID')
BEGIN
    ALTER TABLE [dbo].[device_typemasterLandingpage] ADD [ID] int NOT NULL;
    PRINT 'Added: device_typemasterLandingpage.ID';
END
GO

-- ---- Table: employeesheet1926 ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Agency Remarks Pancard')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Agency Remarks Pancard] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Agency Remarks Pancard';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Zone')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Zone] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Zone';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Dealer Type')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Dealer Type] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Dealer Type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'KYC Status')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [KYC Status] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.KYC Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Bank KYC Processed by Agency On')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Bank KYC Processed by Agency On] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Bank KYC Processed by Agency On';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'PanCard KYC Updated on')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [PanCard KYC Updated on] datetime NULL;
    PRINT 'Added: employeesheet1926.PanCard KYC Updated on';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'PAN No')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [PAN No] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.PAN No';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Location')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Location] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Location';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Dealer Operational Status')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Dealer Operational Status] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Dealer Operational Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Emp UID No')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Emp UID No] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Emp UID No';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Bank KYC Status')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Bank KYC Status] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Bank KYC Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Branch Type')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Branch Type] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Branch Type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'AadharCardNumber')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [AadharCardNumber] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.AadharCardNumber';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Vendor Code')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Vendor Code] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Vendor Code';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Resigned Date')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Resigned Date] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Resigned Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'PAN KYC Status')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [PAN KYC Status] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.PAN KYC Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Residence Location')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Residence Location] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Residence Location';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Name')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Name] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Branch Category')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Branch Category] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Branch Category';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Authentication Date')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Authentication Date] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Authentication Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'DOB')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [DOB] datetime NULL;
    PRINT 'Added: employeesheet1926.DOB';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Pancard KYC Processed by Agency On')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Pancard KYC Processed by Agency On] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Pancard KYC Processed by Agency On';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Gender')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Gender] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Gender';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Joining Date')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Joining Date] datetime NULL;
    PRINT 'Added: employeesheet1926.Joining Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Bank Account No')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Bank Account No] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Bank Account No';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Dealer Code')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Dealer Code] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Dealer Code';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Status')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Status] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'State')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [State] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.State';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Authentication Remarks')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Authentication Remarks] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Authentication Remarks';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Based At')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Based At] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Based At';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Vendor Status')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Vendor Status] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Vendor Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'SAP Vendor Code Confirmation Recd On')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [SAP Vendor Code Confirmation Recd On] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.SAP Vendor Code Confirmation Recd On';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'IFSCCode')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [IFSCCode] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.IFSCCode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Bank KYC Updated on')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Bank KYC Updated on] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Bank KYC Updated on';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Emp Code')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Emp Code] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Emp Code';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Dealer AO')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Dealer AO] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Dealer AO';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Dealer Name')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Dealer Name] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Dealer Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Contact No')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Contact No] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Contact No';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Star ID')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Star ID] float NULL;
    PRINT 'Added: employeesheet1926.Star ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Age')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Age] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Age';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Father Name')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Father Name] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Father Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Employee Count')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Employee Count] float NULL;
    PRINT 'Added: employeesheet1926.Employee Count';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Agency Remarks Bank')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Agency Remarks Bank] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Agency Remarks Bank';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Designation')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Designation] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Designation';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[employeesheet1926]') AND name = 'Authentication Status')
BEGIN
    ALTER TABLE [dbo].[employeesheet1926] ADD [Authentication Status] nvarchar(255) NULL;
    PRINT 'Added: employeesheet1926.Authentication Status';
END
GO

-- ---- Table: mail_sendWalletBalanceLow ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[mail_sendWalletBalanceLow]') AND name = 'ID')
BEGIN
    ALTER TABLE [dbo].[mail_sendWalletBalanceLow] ADD [ID] bigint NOT NULL;
    PRINT 'Added: mail_sendWalletBalanceLow.ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[mail_sendWalletBalanceLow]') AND name = 'EmailId')
BEGIN
    ALTER TABLE [dbo].[mail_sendWalletBalanceLow] ADD [EmailId] varchar(250) NULL;
    PRINT 'Added: mail_sendWalletBalanceLow.EmailId';
END
GO

-- ---- Table: masterdarta1926 ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Dealer_Code')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Dealer_Code] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Dealer_Code';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Tech_Master Id')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Tech_Master Id] float NULL;
    PRINT 'Added: masterdarta1926.Tech_Master Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Dealer_State Name')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Dealer_State Name] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Dealer_State Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Status')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Status] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Dealer AO')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Dealer AO] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Dealer AO';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Enrolment_Date')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Enrolment_Date] datetime NULL;
    PRINT 'Added: masterdarta1926.Enrolment_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Dealer Village')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Dealer Village] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Dealer Village';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Dealer_Zone')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Dealer_Zone] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Dealer_Zone';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Dealer_Tehsil Name')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Dealer_Tehsil Name] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Dealer_Tehsil Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Dealer Name')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Dealer Name] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Dealer Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Tech Master Name')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Tech Master Name] nvarchar(255) NULL;
    PRINT 'Added: masterdarta1926.Tech Master Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[masterdarta1926]') AND name = 'Mobile_Number')
BEGIN
    ALTER TABLE [dbo].[masterdarta1926] ADD [Mobile_Number] float NULL;
    PRINT 'Added: masterdarta1926.Mobile_Number';
END
GO

-- ---- Table: Namrata_RetailerInvoiceData_AI ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Namrata_RetailerInvoiceData_AI]') AND name = 'invoiceid')
BEGIN
    ALTER TABLE [dbo].[Namrata_RetailerInvoiceData_AI] ADD [invoiceid] varchar(20) NULL;
    PRINT 'Added: Namrata_RetailerInvoiceData_AI.invoiceid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Namrata_RetailerInvoiceData_AI]') AND name = 'remark')
BEGIN
    ALTER TABLE [dbo].[Namrata_RetailerInvoiceData_AI] ADD [remark] varchar(200) NULL;
    PRINT 'Added: Namrata_RetailerInvoiceData_AI.remark';
END
GO

-- ---- Table: T_ReassignCode ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Comp_Id')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Comp_Id] nvarchar(50) NULL;
    PRINT 'Added: T_ReassignCode.Comp_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Order_To')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Order_To] int NULL;
    PRINT 'Added: T_ReassignCode.Series_Order_To';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Points')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Points] int NULL;
    PRINT 'Added: T_ReassignCode.Points';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'ExpiryDate')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [ExpiryDate] datetime NULL;
    PRINT 'Added: T_ReassignCode.ExpiryDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'ServiceId')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [ServiceId] nvarchar(50) NULL;
    PRINT 'Added: T_ReassignCode.ServiceId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'AssignDate')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [AssignDate] datetime NULL;
    PRINT 'Added: T_ReassignCode.AssignDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Comments')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Comments] nvarchar(250) NULL;
    PRINT 'Added: T_ReassignCode.Comments';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'ID')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [ID] int NOT NULL;
    PRINT 'Added: T_ReassignCode.ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'BatchNumber')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [BatchNumber] nvarchar(50) NULL;
    PRINT 'Added: T_ReassignCode.BatchNumber';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Order_From')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Order_From] int NULL;
    PRINT 'Added: T_ReassignCode.Series_Order_From';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'ToSeries')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [ToSeries] nvarchar(100) NULL;
    PRINT 'Added: T_ReassignCode.ToSeries';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Serial_To')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Serial_To] int NULL;
    PRINT 'Added: T_ReassignCode.Series_Serial_To';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'OldProductId')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [OldProductId] nvarchar(50) NULL;
    PRINT 'Added: T_ReassignCode.OldProductId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'T_Pro_Row_ID')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [T_Pro_Row_ID] int NULL;
    PRINT 'Added: T_ReassignCode.T_Pro_Row_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'FromSeries')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [FromSeries] nvarchar(100) NULL;
    PRINT 'Added: T_ReassignCode.FromSeries';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Series_Serial_From')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Series_Serial_From] int NULL;
    PRINT 'Added: T_ReassignCode.Series_Serial_From';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'Entry_Date')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [Entry_Date] datetime NULL;
    PRINT 'Added: T_ReassignCode.Entry_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[T_ReassignCode]') AND name = 'ReassignCodeProId')
BEGIN
    ALTER TABLE [dbo].[T_ReassignCode] ADD [ReassignCodeProId] nvarchar(50) NULL;
    PRINT 'Added: T_ReassignCode.ReassignCodeProId';
END
GO

-- ---- Table: tbl_AlertNews ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Act_Flag')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Act_Flag] bit NULL;
    PRINT 'Added: tbl_AlertNews.Act_Flag';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'State')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [State] nvarchar(100) NULL;
    PRINT 'Added: tbl_AlertNews.State';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Longitude] varchar(100) NULL;
    PRINT 'Added: tbl_AlertNews.Longitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Brand_Name')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Brand_Name] nvarchar(250) NULL;
    PRINT 'Added: tbl_AlertNews.Brand_Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Source_Link')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Source_Link] nvarchar(max) NULL;
    PRINT 'Added: tbl_AlertNews.Source_Link';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'City')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [City] nvarchar(100) NULL;
    PRINT 'Added: tbl_AlertNews.City';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Month')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Month] varchar(20) NULL;
    PRINT 'Added: tbl_AlertNews.Month';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'ID')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [ID] int NOT NULL;
    PRINT 'Added: tbl_AlertNews.ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Risk_Level')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Risk_Level] varchar(50) NULL;
    PRINT 'Added: tbl_AlertNews.Risk_Level';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Verification_Status')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Verification_Status] nvarchar(100) NULL;
    PRINT 'Added: tbl_AlertNews.Verification_Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Case_Type')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Case_Type] nvarchar(150) NULL;
    PRINT 'Added: tbl_AlertNews.Case_Type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Estimated_Value')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Estimated_Value] nvarchar(100) NULL;
    PRINT 'Added: tbl_AlertNews.Estimated_Value';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Authority')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Authority] nvarchar(250) NULL;
    PRINT 'Added: tbl_AlertNews.Authority';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Industry')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Industry] nvarchar(150) NULL;
    PRINT 'Added: tbl_AlertNews.Industry';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Pincode')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Pincode] varchar(10) NULL;
    PRINT 'Added: tbl_AlertNews.Pincode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Case_Date')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Case_Date] date NULL;
    PRINT 'Added: tbl_AlertNews.Case_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Country')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Country] nvarchar(100) NULL;
    PRINT 'Added: tbl_AlertNews.Country';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Product_Name')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Product_Name] nvarchar(250) NULL;
    PRINT 'Added: tbl_AlertNews.Product_Name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Verification_Notes')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Verification_Notes] nvarchar(max) NULL;
    PRINT 'Added: tbl_AlertNews.Verification_Notes';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Latitude] varchar(100) NULL;
    PRINT 'Added: tbl_AlertNews.Latitude';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Arrest_Made')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Arrest_Made] varchar(10) NULL;
    PRINT 'Added: tbl_AlertNews.Arrest_Made';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Suggested_VCQRU_Solution')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Suggested_VCQRU_Solution] nvarchar(250) NULL;
    PRINT 'Added: tbl_AlertNews.Suggested_VCQRU_Solution';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Updated_Date')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Updated_Date] datetime NULL;
    PRINT 'Added: tbl_AlertNews.Updated_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Entry_Date')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Entry_Date] datetime NULL;
    PRINT 'Added: tbl_AlertNews.Entry_Date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Year')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Year] int NULL;
    PRINT 'Added: tbl_AlertNews.Year';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Consumer_Health_Risk')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Consumer_Health_Risk] varchar(10) NULL;
    PRINT 'Added: tbl_AlertNews.Consumer_Health_Risk';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Case_ID')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Case_ID] varchar(50) NOT NULL;
    PRINT 'Added: tbl_AlertNews.Case_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AlertNews]') AND name = 'Counterfeit_Type')
BEGIN
    ALTER TABLE [dbo].[tbl_AlertNews] ADD [Counterfeit_Type] nvarchar(250) NULL;
    PRINT 'Added: tbl_AlertNews.Counterfeit_Type';
END
GO

-- ---- Table: tbl_AutomaticClaimSettings ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AutomaticClaimSettings]') AND name = 'Id')
BEGIN
    ALTER TABLE [dbo].[tbl_AutomaticClaimSettings] ADD [Id] int NOT NULL;
    PRINT 'Added: tbl_AutomaticClaimSettings.Id';
END
GO

-- ---- Table: tbl_DeletedUsers ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DeletedUsers]') AND name = 'Id')
BEGIN
    ALTER TABLE [dbo].[tbl_DeletedUsers] ADD [Id] int NOT NULL;
    PRINT 'Added: tbl_DeletedUsers.Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DeletedUsers]') AND name = 'comp_id')
BEGIN
    ALTER TABLE [dbo].[tbl_DeletedUsers] ADD [comp_id] varchar(20) NULL;
    PRINT 'Added: tbl_DeletedUsers.comp_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DeletedUsers]') AND name = 'IsActive')
BEGIN
    ALTER TABLE [dbo].[tbl_DeletedUsers] ADD [IsActive] int NULL;
    PRINT 'Added: tbl_DeletedUsers.IsActive';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DeletedUsers]') AND name = 'Updated_date')
BEGIN
    ALTER TABLE [dbo].[tbl_DeletedUsers] ADD [Updated_date] datetime NULL;
    PRINT 'Added: tbl_DeletedUsers.Updated_date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DeletedUsers]') AND name = 'M_Consumerid')
BEGIN
    ALTER TABLE [dbo].[tbl_DeletedUsers] ADD [M_Consumerid] int NULL;
    PRINT 'Added: tbl_DeletedUsers.M_Consumerid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_DeletedUsers]') AND name = 'Entry_date')
BEGIN
    ALTER TABLE [dbo].[tbl_DeletedUsers] ADD [Entry_date] datetime NULL;
    PRINT 'Added: tbl_DeletedUsers.Entry_date';
END
GO

-- ---- Table: Tbl_Draft_comp_Reg ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Tbl_Draft_comp_Reg]') AND name = 'SalesPersonName')
BEGIN
    ALTER TABLE [dbo].[Tbl_Draft_comp_Reg] ADD [SalesPersonName] nvarchar(200) NULL;
    PRINT 'Added: Tbl_Draft_comp_Reg.SalesPersonName';
END
GO

-- ---- Table: tbl_HighValuePaymentConfig ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_HighValuePaymentConfig]') AND name = 'Isactive')
BEGIN
    ALTER TABLE [dbo].[tbl_HighValuePaymentConfig] ADD [Isactive] bit NOT NULL;
    PRINT 'Added: tbl_HighValuePaymentConfig.Isactive';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_HighValuePaymentConfig]') AND name = 'Comp_ID')
BEGIN
    ALTER TABLE [dbo].[tbl_HighValuePaymentConfig] ADD [Comp_ID] varchar(50) NOT NULL;
    PRINT 'Added: tbl_HighValuePaymentConfig.Comp_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_HighValuePaymentConfig]') AND name = 'Amount')
BEGIN
    ALTER TABLE [dbo].[tbl_HighValuePaymentConfig] ADD [Amount] decimal(18, 2) NOT NULL;
    PRINT 'Added: tbl_HighValuePaymentConfig.Amount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_HighValuePaymentConfig]') AND name = 'Row_ID')
BEGIN
    ALTER TABLE [dbo].[tbl_HighValuePaymentConfig] ADD [Row_ID] int NOT NULL;
    PRINT 'Added: tbl_HighValuePaymentConfig.Row_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_HighValuePaymentConfig]') AND name = 'Created_Date')
BEGIN
    ALTER TABLE [dbo].[tbl_HighValuePaymentConfig] ADD [Created_Date] datetime NOT NULL;
    PRINT 'Added: tbl_HighValuePaymentConfig.Created_Date';
END
GO

-- ---- Table: tbl_Industry_Type ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Industry_Type]') AND name = 'CreatedDate')
BEGIN
    ALTER TABLE [dbo].[tbl_Industry_Type] ADD [CreatedDate] datetime NOT NULL;
    PRINT 'Added: tbl_Industry_Type.CreatedDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Industry_Type]') AND name = 'Industry_Id')
BEGIN
    ALTER TABLE [dbo].[tbl_Industry_Type] ADD [Industry_Id] int NOT NULL;
    PRINT 'Added: tbl_Industry_Type.Industry_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Industry_Type]') AND name = 'Industry_Name')
BEGIN
    ALTER TABLE [dbo].[tbl_Industry_Type] ADD [Industry_Name] nvarchar(100) NOT NULL;
    PRINT 'Added: tbl_Industry_Type.Industry_Name';
END
GO

-- ---- Table: tbl_sbuCompany ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_sbuCompany]') AND name = 'MainCompID')
BEGIN
    ALTER TABLE [dbo].[tbl_sbuCompany] ADD [MainCompID] varchar(50) NOT NULL;
    PRINT 'Added: tbl_sbuCompany.MainCompID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_sbuCompany]') AND name = 'SubCompanyName')
BEGIN
    ALTER TABLE [dbo].[tbl_sbuCompany] ADD [SubCompanyName] varchar(200) NOT NULL;
    PRINT 'Added: tbl_sbuCompany.SubCompanyName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_sbuCompany]') AND name = 'entry_date')
BEGIN
    ALTER TABLE [dbo].[tbl_sbuCompany] ADD [entry_date] datetime NOT NULL;
    PRINT 'Added: tbl_sbuCompany.entry_date';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_sbuCompany]') AND name = 'SubCompTypeType')
BEGIN
    ALTER TABLE [dbo].[tbl_sbuCompany] ADD [SubCompTypeType] varchar(100) NULL;
    PRINT 'Added: tbl_sbuCompany.SubCompTypeType';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_sbuCompany]') AND name = 'SubComp_ID')
BEGIN
    ALTER TABLE [dbo].[tbl_sbuCompany] ADD [SubComp_ID] varchar(50) NOT NULL;
    PRINT 'Added: tbl_sbuCompany.SubComp_ID';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_sbuCompany]') AND name = 'ID')
BEGIN
    ALTER TABLE [dbo].[tbl_sbuCompany] ADD [ID] int NOT NULL;
    PRINT 'Added: tbl_sbuCompany.ID';
END
GO

-- ---- Table: tbl_UserReferralCodes ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'usermobileno')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [usermobileno] varchar(20) NULL;
    PRINT 'Added: tbl_UserReferralCodes.usermobileno';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'UpdatedDate')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [UpdatedDate] datetime NULL;
    PRINT 'Added: tbl_UserReferralCodes.UpdatedDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'IsUsed')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [IsUsed] bit NULL;
    PRINT 'Added: tbl_UserReferralCodes.IsUsed';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'Comp_id')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [Comp_id] varchar(50) NOT NULL;
    PRINT 'Added: tbl_UserReferralCodes.Comp_id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'Id')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [Id] int NOT NULL;
    PRINT 'Added: tbl_UserReferralCodes.Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'CreatedDate')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [CreatedDate] datetime NULL;
    PRINT 'Added: tbl_UserReferralCodes.CreatedDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'UsedByPoints')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [UsedByPoints] int NULL;
    PRINT 'Added: tbl_UserReferralCodes.UsedByPoints';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'RefCode')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [RefCode] varchar(100) NOT NULL;
    PRINT 'Added: tbl_UserReferralCodes.RefCode';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'SharedByPoints')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [SharedByPoints] int NULL;
    PRINT 'Added: tbl_UserReferralCodes.SharedByPoints';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_UserReferralCodes]') AND name = 'M_Consumerid')
BEGIN
    ALTER TABLE [dbo].[tbl_UserReferralCodes] ADD [M_Consumerid] varchar(50) NOT NULL;
    PRINT 'Added: tbl_UserReferralCodes.M_Consumerid';
END
GO

-- ---- Table: tblUPITransactionDetails_26_06_2026 ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'ReqDate')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [ReqDate] datetime NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.ReqDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'TCharge_Amount')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [TCharge_Amount] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.TCharge_Amount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'UPI_Id')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [UPI_Id] varchar(70) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.UPI_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Code1')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Code1] varchar(6) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Code1';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Comm_Amount')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Comm_Amount] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Comm_Amount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'TComm_Amount')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [TComm_Amount] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.TComm_Amount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Id')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Id] int NOT NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'FinalStatus')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [FinalStatus] varchar(30) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.FinalStatus';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'MobileNo')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [MobileNo] varchar(13) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.MobileNo';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'EditDate')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [EditDate] datetime NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.EditDate';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Comm_Type')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Comm_Type] bit NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Comm_Type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Amount')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Amount] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Amount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Comp_Id')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Comp_Id] varchar(30) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Comp_Id';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Charge_Amount')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Charge_Amount] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Charge_Amount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'TicketStatus')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [TicketStatus] varchar(20) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.TicketStatus';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'RefenceId')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [RefenceId] varchar(30) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.RefenceId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'RepocessStatus')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [RepocessStatus] bit NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.RepocessStatus';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'tdsper')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [tdsper] int NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.tdsper';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'TicketComment')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [TicketComment] varchar(200) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.TicketComment';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'OrderId')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [OrderId] varchar(30) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.OrderId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'benef_name')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [benef_name] nvarchar(100) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.benef_name';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'ConsumerEmailId')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [ConsumerEmailId] varchar(69) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.ConsumerEmailId';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'M_Consumerid')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [M_Consumerid] int NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.M_Consumerid';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'FinalRemarks')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [FinalRemarks] varchar(70) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.FinalRemarks';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'ifsc_code')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [ifsc_code] nvarchar(20) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.ifsc_code';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Charge_Type')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Charge_Type] bit NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Charge_Type';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Status')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Status] varchar(30) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Status';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Points_Val')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Points_Val] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Points_Val';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'ConsumerName')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [ConsumerName] varchar(69) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.ConsumerName';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'account_no')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [account_no] nvarchar(30) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.account_no';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Code2')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Code2] varchar(8) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Code2';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'TdsType')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [TdsType] varchar(5) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.TdsType';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'Remarks')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [Remarks] varchar(70) NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.Remarks';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'GstAmount')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [GstAmount] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.GstAmount';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails_26_06_2026]') AND name = 'tdsAmount')
BEGIN
    ALTER TABLE [dbo].[tblUPITransactionDetails_26_06_2026] ADD [tdsAmount] float NULL;
    PRINT 'Added: tblUPITransactionDetails_26_06_2026.tdsAmount';
END
GO

-- ---- Table: WarrentyDetails ----
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WarrentyDetails]') AND name = 'DeviceType')
BEGIN
    ALTER TABLE [dbo].[WarrentyDetails] ADD [DeviceType] varchar(100) NULL;
    PRINT 'Added: WarrentyDetails.DeviceType';
END
GO

