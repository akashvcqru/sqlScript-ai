CREATE TABLE [dbo].[NamrataPointsTransferHistory_AI](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [tomobileno] [varchar](15) NOT NULL,
    [frommobileno] [varchar](15) NOT NULL,
    [toM_Consumerid] [int] NOT NULL,
    [fromM_Consumerid] [int] NOT NULL,
    [transferedpoints] [int] NOT NULL,
    [comp_id] [varchar](50) NULL,
    [date] [datetime] DEFAULT GETDATE(),
    PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO
