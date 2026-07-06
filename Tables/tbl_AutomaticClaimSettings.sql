CREATE TABLE [dbo].[tbl_AutomaticClaimSettings](
    [Comp_id] [nvarchar](50) NOT NULL,
    [IsAutoClaimEnable] [bit] NOT NULL CONSTRAINT [DF_tbl_AutomaticClaimSettings_IsAutoClaimEnable] DEFAULT ((0)),
    [DayOfMonth] [int] NULL,
    [ClaimType] [varchar](50) NULL,
    [Entry_Date] [datetime] NOT NULL CONSTRAINT [DF_tbl_AutomaticClaimSettings_Entry_Date] DEFAULT (getdate()),
    [Updated_Date] [datetime] NOT NULL CONSTRAINT [DF_tbl_AutomaticClaimSettings_Updated_Date] DEFAULT (getdate()),
    CONSTRAINT [PK_tbl_AutomaticClaimSettings] PRIMARY KEY CLUSTERED ([Comp_id] ASC)
);
