-- Migration: Set default 1 for IsActive column in M_ServiceSubscription table
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscription]') AND name = 'IsActive')
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_M_ServiceSubscription_IsActive')
    BEGIN
        ALTER TABLE [dbo].[M_ServiceSubscription] 
        ADD CONSTRAINT [DF_M_ServiceSubscription_IsActive] DEFAULT ((1)) FOR [IsActive];
    END
END
GO
