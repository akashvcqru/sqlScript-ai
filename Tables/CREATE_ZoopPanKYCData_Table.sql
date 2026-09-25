IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ZoopPanKYCData]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ZoopPanKYCData](
        [id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [M_Consumerid] [varchar](50) NULL,
        [comp_id] [varchar](50) NULL,
        [pancardNumber] [varchar](20) NULL,
        [input_pan_name] [nvarchar](255) NULL,
        [pan_holder_name] [nvarchar](255) NULL,
        [pan_status] [varchar](50) NULL,
        [response_code] [varchar](50) NULL,
        [request_id] [varchar](100) NULL,
        [success] [varchar](50) NULL,
        [zoop_response] [nvarchar](max) NULL,
        [CreatedDate] [datetime] NULL DEFAULT (getdate())
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_ZoopPanKYCData_pancardNumber' AND object_id = OBJECT_ID(N'[dbo].[ZoopPanKYCData]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ZoopPanKYCData_pancardNumber] ON [dbo].[ZoopPanKYCData]([pancardNumber] ASC);
END
GO
