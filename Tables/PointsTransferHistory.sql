CREATE TABLE [dbo].[PointsTransferHistory](
    [Id] [bigint] IDENTITY(1,1) NOT NULL,
    [fromMobileno] [varchar](15) NULL,
    [toMobileno] [varchar](15) NULL,
    [transaction_type] [varchar](50) NULL,
    [points] [int] NULL,
    [comp_id] [varchar](50) NULL,
    [date] [datetime] NULL,
    [ClaimDetailsId] [int] NULL,
    [BLoyaltyPointsEarnedId] [bigint] NULL,
    CONSTRAINT [PK_PointsTransferHistory] PRIMARY KEY CLUSTERED ([Id] ASC)
) ON [PRIMARY]
GO
