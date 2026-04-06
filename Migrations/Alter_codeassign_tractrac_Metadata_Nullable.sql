-- Migration: Make metadata fields nullable in codeassign_tractrac
-- This is needed because these fields are now handled in the Update API instead of the Add API.

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Dealer_Name')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Dealer_Name] NVARCHAR(150) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Dealer_Location')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Dealer_Location] NVARCHAR(150) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Contact_Information')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Contact_Information] NVARCHAR(150) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Invoice_Number')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Invoice_Number] NVARCHAR(50) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Latitude] NVARCHAR(50) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Longitude] NVARCHAR(50) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'MRP')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [MRP] NUMERIC(18, 2) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Mfd_Date')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Mfd_Date] DATETIME NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND name = 'Exp_Date')
BEGIN
    ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [Exp_Date] DATETIME NULL;
END
GO

-- Migration for M_ServiceSubscriptionTracTrace_MasterCodeLess
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Dealer_Name')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Dealer_Name] NVARCHAR(150) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Dealer_Location')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Dealer_Location] NVARCHAR(150) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Mobile')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Mobile] NVARCHAR(150) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Email')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Email] NVARCHAR(150) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Invoice_Number')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Invoice_Number] NVARCHAR(50) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Latitude] NVARCHAR(50) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Longitude] NVARCHAR(50) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'MRP')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [MRP] NUMERIC(18, 2) NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Mfd_Date')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Mfd_Date] DATETIME NULL;
END
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND name = 'Exp_Date')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess] ALTER COLUMN [Exp_Date] DATETIME NULL;
END
GO
