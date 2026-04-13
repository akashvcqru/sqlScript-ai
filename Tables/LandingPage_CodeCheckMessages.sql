CREATE TABLE [dbo].[LandingPage_CodeCheckMessages] (
    [Id] [int] IDENTITY(1,1) NOT NULL,
    [Comp_Id] [varchar](50) NOT NULL,
    [Service_Id] [varchar](50) NULL,
    [Message_Type] [varchar](20) NOT NULL, -- 'Success', 'Already', 'Invalid'
    [Message_Text] [nvarchar](max) NOT NULL,
    [IsActive] [bit] DEFAULT 1,
    [CreatedDate] [datetime] DEFAULT GETDATE(),
    [UpdatedDate] [datetime] NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
