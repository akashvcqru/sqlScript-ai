-- =========================================================================
-- Migration: 20260914_Create_tbl_VendorPaymentGatewaySetting.sql
-- Description: Create tbl_VendorPaymentGatewaySetting for per-vendor payment gateways (InstantPay, HDFC, Vendor Own)
-- =========================================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tbl_VendorPaymentGatewaySetting')
BEGIN
    CREATE TABLE [dbo].[tbl_VendorPaymentGatewaySetting](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Comp_Id] [varchar](20) NOT NULL,
        [GatewayType] [varchar](50) NOT NULL,
        [GatewayCode] [varchar](50) NOT NULL,
        [ConfigJson] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL CONSTRAINT [DF_tbl_VendorPaymentGatewaySetting_IsActive] DEFAULT ((1)),
        [CreatedDate] [datetime] NULL CONSTRAINT [DF_tbl_VendorPaymentGatewaySetting_CreatedDate] DEFAULT (getdate()),
        [UpdatedDate] [datetime] NULL,
        [UpdatedBy] [varchar](50) NULL,
        CONSTRAINT [PK_tbl_VendorPaymentGatewaySetting] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_tbl_VendorPaymentGatewaySetting_CompId_GatewayCode] UNIQUE NONCLUSTERED ([Comp_Id] ASC, [GatewayCode] ASC)
    );

    CREATE NONCLUSTERED INDEX [IX_tbl_VendorPaymentGatewaySetting_CompId_Active] 
    ON [dbo].[tbl_VendorPaymentGatewaySetting] ([Comp_Id], [IsActive]);
END
GO
