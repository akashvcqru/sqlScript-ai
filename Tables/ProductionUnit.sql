/****** Object:  Table [dbo].[ProductionUnit]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProductionUnit](
	[ProductionUnitID] [int] IDENTITY(1,1) NOT NULL,
	[Compid] [nvarchar](50) NULL,
	[name] [nvarchar](80) NULL,
	[createddate] [datetime] NULL,
	[createdby] [nvarchar](50) NULL,
	[updateddate] [datetime] NULL,
	[updatedby] [nvarchar](50) NULL,
	[noofitemsinCartoon] [int] NULL,
 CONSTRAINT [PK_ProductionUnit] PRIMARY KEY CLUSTERED 
(
	[ProductionUnitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
