USE [VCQRU]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[M_MultiuserRegistrationFieldNames]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[M_MultiuserRegistrationFieldNames](
	[FieldId] [int] IDENTITY(1,1) NOT NULL,
	[FieldName] [varchar](150) NULL,
	[IsActive] [bit] NULL CONSTRAINT [DF_M_MultiuserRegistrationFieldNames_IsActive]  DEFAULT ((1)),
	[CreatedBy] [varchar](50) NULL,
	[CreatedDate] [datetime] NULL CONSTRAINT [DF_M_MultiuserRegistrationFieldNames_CreatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_M_MultiuserRegistrationFieldNames] PRIMARY KEY CLUSTERED 
(
	[FieldId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
