SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ZoopBankKYCData](
    [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [M_Consumerid] [varchar](50) NULL,
    [comp_id] [varchar](50) NULL,
    [success] [varchar](50) NULL,
    [beneficiary_name] [nvarchar](255) NULL,
    [bank_ref_no] [nvarchar](100) NULL,
    [response_code] [varchar](50) NULL,
    [zoop_response] [nvarchar](max) NULL,
    [IFSC_Code] [varchar](50) NULL,
    [AccountNo] [varchar](50) NULL,
    [CreatedDate] [datetime] NULL DEFAULT (getdate())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
