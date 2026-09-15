/****** Object:  Table [dbo].[tbl_VendorPaymentGatewaySetting]    Script Date: 9/14/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
 CONSTRAINT [PK_tbl_VendorPaymentGatewaySetting] PRIMARY KEY CLUSTERED 
(
    [Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_tbl_VendorPaymentGatewaySetting_CompId_GatewayCode] UNIQUE NONCLUSTERED 
(
    [Comp_Id] ASC,
    [GatewayCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_tbl_VendorPaymentGatewaySetting_CompId_Active] 
ON [dbo].[tbl_VendorPaymentGatewaySetting] ([Comp_Id], [IsActive]);
GO
