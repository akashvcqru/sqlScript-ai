-- Create M_Menu_AI Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'M_Menu_AI')
BEGIN
    CREATE TABLE M_Menu_AI (
        MenuID INT IDENTITY(1,1) PRIMARY KEY,
        MenuName NVARCHAR(100) NOT NULL,
        ControlName NVARCHAR(100),
        URL NVARCHAR(200),
        IconClass NVARCHAR(100),
        ParentMenuID INT FOREIGN KEY REFERENCES M_Menu_AI(MenuID),
        MenuOrder INT DEFAULT 0,
        IsEnabled BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE()
    );
END
GO

-- Create T_Menu_Visibility_Mapping_AI Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'T_Menu_Visibility_Mapping_AI')
BEGIN
    CREATE TABLE T_Menu_Visibility_Mapping_AI (
        MappingID INT IDENTITY(1,1) PRIMARY KEY,
        MenuID INT NOT NULL FOREIGN KEY REFERENCES M_Menu_AI(MenuID),
        Comp_ID NVARCHAR(50) NOT NULL,
        Service_ID NVARCHAR(50) NOT NULL, -- Mandatory
        Status BIT NOT NULL DEFAULT 1, -- 1 = Show, 0 = Hide
        CreatedDate DATETIME DEFAULT GETDATE(),
        UpdatedDate DATETIME NULL
    );
END
GO
