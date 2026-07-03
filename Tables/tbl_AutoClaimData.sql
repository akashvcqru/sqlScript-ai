CREATE TABLE [dbo].[tbl_AutoClaimData](
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [M_Consumerid] [int] NOT NULL,
    [Comp_id] [nvarchar](50) NOT NULL,
    [Points] [int] NOT NULL,
    [Claim_Type] [nvarchar](50) NULL,
    [Status] [nvarchar](50) NULL,
    [Remarks] [nvarchar](max) NULL,
    [Entry_Date] [datetime] NOT NULL CONSTRAINT [DF_tbl_AutoClaimData_Entry_Date] DEFAULT (getdate()),
    CONSTRAINT [PK_tbl_AutoClaimData] PRIMARY KEY CLUSTERED ([Id] ASC)
);
