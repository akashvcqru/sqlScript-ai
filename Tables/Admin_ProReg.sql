USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Admin_ProReg](
    [Id] [INT] IDENTITY(1,1) NOT NULL,
    [Name] [NVARCHAR](250) NOT NULL,
    [Description] [NVARCHAR](MAX) NULL,
    [Points] [INT] NOT NULL CONSTRAINT [DF_Admin_ProReg_Points] DEFAULT ((0)),
    [Image1] [NVARCHAR](500) NULL,
    [Image2] [NVARCHAR](500) NULL,
    [Image3] [NVARCHAR](500) NULL,
    [Image4] [NVARCHAR](500) NULL,
    [Image5] [NVARCHAR](500) NULL,
    [CreatedDate] [DATETIME] NOT NULL CONSTRAINT [DF_Admin_ProReg_CreatedDate] DEFAULT (GETDATE()),
    [UpdatedDate] [DATETIME] NULL,
    [IsDelete] [BIT] NOT NULL CONSTRAINT [DF_Admin_ProReg_IsDelete] DEFAULT ((0)),
    [DeletedDate] [DATETIME] NULL,
    CONSTRAINT [PK_Admin_ProReg] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
