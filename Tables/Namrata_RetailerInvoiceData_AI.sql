CREATE TABLE [dbo].[Namrata_RetailerInvoiceData_AI](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [M_Consumerid] [int] NOT NULL,
    [comp_id] [varchar](20) NOT NULL,
    [invoiceAmount] [decimal](18, 2) NOT NULL,
    [PointPersent] [decimal](18, 2) NOT NULL,
    [points] [int] NOT NULL,
    [invoiceid] [varchar](20) NULL,
    [remark] [varchar](200) NULL,
    [createdate] [datetime] DEFAULT GETDATE(),
    [updateddate] [datetime] DEFAULT GETDATE(),
    PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO
