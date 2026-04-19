CREATE TABLE [dbo].[M_Dealer_AI](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Dealer_Name] [nvarchar](200) NOT NULL,
	[Dealer_Location] [nvarchar](500) NULL,
	[Contact_Information] [nvarchar](200) NULL,
	[Invoice_Number] [nvarchar](100) NULL,
	[Latitude] [nvarchar](50) NULL,
	[Longitude] [nvarchar](50) NULL,
	[isdelete] [int] NULL DEFAULT 0,
	[Comp_ID] [nvarchar](50) NULL,
	[entry_date] [datetime] NULL DEFAULT (getdate()),
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
