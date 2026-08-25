-- =============================================
-- Migration: Update tbl_VendorDashboardRoles columns
-- 1. Remove ReportPermission column
-- 2. Rename AppSettingPermission to PermissionSettings
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND type in (N'U'))
BEGIN
    -- 1. Drop ReportPermission column if exists
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'ReportPermission')
    BEGIN
        ALTER TABLE tbl_VendorDashboardRoles DROP COLUMN ReportPermission;
        PRINT 'Dropped ReportPermission column from tbl_VendorDashboardRoles.';
    END

    -- 2. Rename AppSettingPermission to PermissionSettings if exists and PermissionSettings does not exist
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'AppSettingPermission') 
       AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'PermissionSettings')
    BEGIN
        EXEC sp_rename 'tbl_VendorDashboardRoles.AppSettingPermission', 'PermissionSettings', 'COLUMN';
        PRINT 'Renamed AppSettingPermission to PermissionSettings in tbl_VendorDashboardRoles.';
    END
    ELSE IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'PermissionSettings')
    BEGIN
        ALTER TABLE tbl_VendorDashboardRoles ADD PermissionSettings NVARCHAR(MAX) NULL;
        PRINT 'Added PermissionSettings column to tbl_VendorDashboardRoles.';
    END
END
GO
