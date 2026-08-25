-- =============================================
-- Script: Create / Alter Vendor and Admin Dashboard Roles & Users Tables
-- =============================================

-- 1. tbl_VendorDashboardRoles
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND type in (N'U'))
BEGIN
    CREATE TABLE tbl_VendorDashboardRoles
    (
        RoleId INT IDENTITY(1,1) PRIMARY KEY,
        Comp_id VARCHAR(20) NOT NULL,
        RoleName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        IsDelete BIT NOT NULL DEFAULT 0,
        PermissionSettings NVARCHAR(MAX) NULL,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedDate DATETIME NULL
    );
END
ELSE
BEGIN
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'CompanyId')
    BEGIN
        EXEC sp_rename 'tbl_VendorDashboardRoles.CompanyId', 'Comp_id', 'COLUMN';
    END
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'IsDelete')
    BEGIN
        ALTER TABLE tbl_VendorDashboardRoles ADD IsDelete BIT NOT NULL DEFAULT 0;
    END
    -- Drop ReportPermission if it exists
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'ReportPermission')
    BEGIN
        ALTER TABLE tbl_VendorDashboardRoles DROP COLUMN ReportPermission;
    END
    -- Rename AppSettingPermission to PermissionSettings if exists
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'AppSettingPermission') 
       AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'PermissionSettings')
    BEGIN
        EXEC sp_rename 'tbl_VendorDashboardRoles.AppSettingPermission', 'PermissionSettings', 'COLUMN';
    END
    ELSE IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardRoles]') AND name = 'PermissionSettings')
    BEGIN
        ALTER TABLE tbl_VendorDashboardRoles ADD PermissionSettings NVARCHAR(MAX) NULL;
    END
END
GO

-- 2. tbl_AdminDashboardRoles
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AdminDashboardRoles]') AND type in (N'U'))
BEGIN
    CREATE TABLE tbl_AdminDashboardRoles
    (
        RoleId INT IDENTITY(1,1) PRIMARY KEY,
        RoleName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(500) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedDate DATETIME NULL
    );
END
GO

-- 3. tbl_VendorDashboardUsers
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardUsers]') AND type in (N'U'))
BEGIN
    CREATE TABLE tbl_VendorDashboardUsers
    (
        Row_Id INT IDENTITY(1,1) PRIMARY KEY,
        Comp_id VARCHAR(20) NOT NULL, 
        UserId INT NOT NULL,
        UserName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(255) NULL,
        MobileNo NVARCHAR(20) NULL,
        Password  NVARCHAR(500) NULL,
        RoleId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedDate DATETIME NULL
    );
END
ELSE
BEGIN
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[tbl_VendorDashboardUsers]') AND name = 'CompanyId')
    BEGIN
        EXEC sp_rename 'tbl_VendorDashboardUsers.CompanyId', 'Comp_id', 'COLUMN';
    END
END
GO

-- 4. tbl_AdminDashboardUsers
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_AdminDashboardUsers]') AND type in (N'U'))
BEGIN
    CREATE TABLE tbl_AdminDashboardUsers
    (
        Row_Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        UserName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(255) NULL,
        MobileNo NVARCHAR(20) NULL,
        Password  NVARCHAR(500) NULL,
        RoleId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedDate DATETIME NULL
    );
END
GO
