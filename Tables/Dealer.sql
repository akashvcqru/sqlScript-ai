/****** Object:  Table [dbo].[Dealer]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dealer](
	[DealerID] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](200) NULL,
	[Address] [nvarchar](250) NULL,
	[Email] [nvarchar](50) NULL,
	[mobileno] [nvarchar](50) NULL,
	[pwd] [nvarchar](50) NULL,
	[Location] [nvarchar](80) NULL,
	[pincode] [nvarchar](50) NULL,
	[Type] [tinyint] NULL,
	[createddate] [datetime] NULL,
	[createdby] [int] NULL,
	[modifieddate] [datetime] NULL,
	[modifiedby] [int] NULL,
	[active] [bit] NULL,
	[delete] [bit] NULL,
	[compid] [nvarchar](50) NULL,
 CONSTRAINT [PK_Dealer] PRIMARY KEY CLUSTERED 
(
	[DealerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
