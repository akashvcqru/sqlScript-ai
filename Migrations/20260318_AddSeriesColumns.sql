-- Migration Script: Add Series Columns to M_ServiceSubscriptionTrans
-- Date: 2026-03-18

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTrans]') AND name = 'StartOrder')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTrans] ADD [StartOrder] INT NULL;
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTrans]') AND name = 'StartSeries')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTrans] ADD [StartSeries] INT NULL;
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTrans]') AND name = 'EndOrder')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTrans] ADD [EndOrder] INT NULL;
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTrans]') AND name = 'EndSeries')
BEGIN
    ALTER TABLE [dbo].[M_ServiceSubscriptionTrans] ADD [EndSeries] INT NULL;
END
GO
