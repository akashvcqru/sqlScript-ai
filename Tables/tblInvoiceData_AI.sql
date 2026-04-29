USE [VCQRU_Dev]; -- Update with correct DB name if needed
GO

CREATE TABLE [dbo].[tblInvoiceData_AI](
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [M_Consumerid] [int] NOT NULL,
    [Comp_id] [nvarchar](50) NOT NULL,
    [InvoiceFile] [nvarchar](max) NOT NULL,
    [InvoicePoints] [int] NOT NULL,
    [Amount] [decimal](18, 2) NOT NULL,
    [Created_Date] [datetime] NOT NULL DEFAULT (GETDATE()),
    [Status] [int] NOT NULL DEFAULT ((0)),
 CONSTRAINT [PK_tblInvoiceData_AI] PRIMARY KEY CLUSTERED 
(
    [Id] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
