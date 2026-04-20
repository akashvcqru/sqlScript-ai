-- Report Management Tables
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'T_Report_Master_AI')
BEGIN
    CREATE TABLE T_Report_Master_AI (
        Report_ID INT IDENTITY(1,1) PRIMARY KEY,
        Report_Name NVARCHAR(100) NOT NULL,
        Service_ID NVARCHAR(50) NOT NULL,
        Status BIT DEFAULT 1,
        Created_At DATETIME DEFAULT GETDATE()
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'T_Report_Columns_AI')
BEGIN
    CREATE TABLE T_Report_Columns_AI (
        Column_ID INT IDENTITY(1,1) PRIMARY KEY,
        Report_ID INT NOT NULL,
        Column_Name NVARCHAR(100) NOT NULL,
        Display_Name NVARCHAR(100) NOT NULL,
        Status BIT DEFAULT 1,
        Created_At DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_ReportMaster_Columns FOREIGN KEY (Report_ID) REFERENCES T_Report_Master_AI(Report_ID)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'T_Report_Visibility_Mapping_AI')
BEGIN
    CREATE TABLE T_Report_Visibility_Mapping_AI (
        Mapping_ID INT IDENTITY(1,1) PRIMARY KEY,
        Comp_ID NVARCHAR(50) NOT NULL,
        Service_ID NVARCHAR(50) NOT NULL,
        Report_ID INT NOT NULL,
        Is_Enabled BIT DEFAULT 0,
        Updated_At DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Mapping_Report FOREIGN KEY (Report_ID) REFERENCES T_Report_Master_AI(Report_ID)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'T_Column_Visibility_Mapping_AI')
BEGIN
    CREATE TABLE T_Column_Visibility_Mapping_AI (
        Mapping_ID INT IDENTITY(1,1) PRIMARY KEY,
        Comp_ID NVARCHAR(50) NOT NULL,
        Service_ID NVARCHAR(50) NOT NULL,
        Report_ID INT NOT NULL,
        Column_ID INT NOT NULL,
        Is_Enabled BIT DEFAULT 0,
        Updated_At DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_ColumnMapping_Report FOREIGN KEY (Report_ID) REFERENCES T_Report_Master_AI(Report_ID),
        CONSTRAINT FK_ColumnMapping_Column FOREIGN KEY (Column_ID) REFERENCES T_Report_Columns_AI(Column_ID)
    );
END
GO

-- Stored Procedures

-- 1. Get reports for a specific service
CREATE OR ALTER PROCEDURE USP_GetReportsByService_AI
    @Service_ID NVARCHAR(50),
    @Comp_ID NVARCHAR(50) = NULL
AS
BEGIN
    SELECT RM.Report_ID, RM.Report_Name, RM.Service_ID,
           CAST(CASE WHEN @Comp_ID IS NULL THEN NULL ELSE ISNULL(VM.Is_Enabled, 0) END AS BIT) AS IsChecked
    FROM T_Report_Master_AI RM
    LEFT JOIN T_Report_Visibility_Mapping_AI VM ON RM.Report_ID = VM.Report_ID AND VM.Comp_ID = @Comp_ID AND VM.Service_ID = @Service_ID
    WHERE RM.Service_ID = @Service_ID AND RM.Status = 1;
END
GO

-- 2. Get columns for a specific report
CREATE OR ALTER PROCEDURE USP_GetReportColumns_AI
    @Report_ID INT,
    @Comp_ID NVARCHAR(50) = NULL,
    @Service_ID NVARCHAR(50) = NULL
AS
BEGIN
    SELECT RC.Column_ID, RC.Report_ID, RC.Column_Name, RC.Display_Name,
           CAST(CASE WHEN @Comp_ID IS NULL THEN NULL ELSE ISNULL(CM.Is_Enabled, 0) END AS BIT) AS IsChecked
    FROM T_Report_Columns_AI RC
    LEFT JOIN T_Column_Visibility_Mapping_AI CM ON RC.Column_ID = CM.Column_ID AND CM.Comp_ID = @Comp_ID AND CM.Service_ID = @Service_ID AND CM.Report_ID = @Report_ID
    WHERE RC.Report_ID = @Report_ID AND RC.Status = 1;
END
GO

-- 3. Add or update report visibility
CREATE OR ALTER PROCEDURE USP_AddUpdateReportVisibility_AI
    @Comp_ID NVARCHAR(50),
    @Service_ID NVARCHAR(50),
    @Report_ID INT,
    @Is_Enabled BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM T_Report_Visibility_Mapping_AI WHERE Comp_ID = @Comp_ID AND Service_ID = @Service_ID AND Report_ID = @Report_ID)
    BEGIN
        UPDATE T_Report_Visibility_Mapping_AI 
        SET Is_Enabled = @Is_Enabled, Updated_At = GETDATE()
        WHERE Comp_ID = @Comp_ID AND Service_ID = @Service_ID AND Report_ID = @Report_ID;
    END
    ELSE
    BEGIN
        INSERT INTO T_Report_Visibility_Mapping_AI (Comp_ID, Service_ID, Report_ID, Is_Enabled)
        VALUES (@Comp_ID, @Service_ID, @Report_ID, @Is_Enabled);
    END
END
GO

-- 4. Add or update column visibility
CREATE OR ALTER PROCEDURE USP_AddUpdateColumnVisibility_AI
    @Comp_ID NVARCHAR(50),
    @Service_ID NVARCHAR(50),
    @Report_ID INT,
    @Column_ID INT,
    @Is_Enabled BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM T_Column_Visibility_Mapping_AI WHERE Comp_ID = @Comp_ID AND Service_ID = @Service_ID AND Report_ID = @Report_ID AND Column_ID = @Column_ID)
    BEGIN
        UPDATE T_Column_Visibility_Mapping_AI 
        SET Is_Enabled = @Is_Enabled, Updated_At = GETDATE()
        WHERE Comp_ID = @Comp_ID AND Service_ID = @Service_ID AND Report_ID = @Report_ID AND Column_ID = @Column_ID;
    END
    ELSE
    BEGIN
        INSERT INTO T_Column_Visibility_Mapping_AI (Comp_ID, Service_ID, Report_ID, Column_ID, Is_Enabled)
        VALUES (@Comp_ID, @Service_ID, @Report_ID, @Column_ID, @Is_Enabled);
    END
END
GO

-- 5. Get report visibility for a company/service (Admin)
CREATE OR ALTER PROCEDURE USP_GetCompanyReportVisibility_AI
    @Comp_ID NVARCHAR(50),
    @Service_ID NVARCHAR(50)
AS
BEGIN
    SELECT RM.Report_ID, RM.Report_Name, ISNULL(VM.Is_Enabled, 0) AS Is_Enabled
    FROM T_Report_Master_AI RM
    LEFT JOIN T_Report_Visibility_Mapping_AI VM ON RM.Report_ID = VM.Report_ID AND VM.Comp_ID = @Comp_ID AND VM.Service_ID = @Service_ID
    WHERE RM.Service_ID = @Service_ID;
END
GO

-- 6. Get column visibility for a company/service/report (Admin)
CREATE OR ALTER PROCEDURE USP_GetCompanyColumnVisibility_AI
    @Comp_ID NVARCHAR(50),
    @Service_ID NVARCHAR(50),
    @Report_ID INT
AS
BEGIN
    SELECT RC.Column_ID, RC.Column_Name, RC.Display_Name, ISNULL(CM.Is_Enabled, 0) AS Is_Enabled
    FROM T_Report_Columns_AI RC
    LEFT JOIN T_Column_Visibility_Mapping_AI CM ON RC.Column_ID = CM.Column_ID AND CM.Comp_ID = @Comp_ID AND CM.Service_ID = @Service_ID AND CM.Report_ID = @Report_ID
    WHERE RC.Report_ID = @Report_ID;
END
GO

-- 7. Get application-side report settings (App)
-- Fetches only enabled reports and their enabled columns
CREATE OR ALTER PROCEDURE USP_GetAppReportSettings_AI
    @Comp_ID NVARCHAR(50),
    @Service_ID NVARCHAR(50)
AS
BEGIN
    SELECT RM.Report_ID, RM.Report_Name, RC.Column_ID, RC.Column_Name, RC.Display_Name
    FROM T_Report_Master_AI RM
    INNER JOIN T_Report_Visibility_Mapping_AI VM ON RM.Report_ID = VM.Report_ID AND VM.Comp_ID = @Comp_ID AND VM.Service_ID = @Service_ID AND VM.Is_Enabled = 1
    INNER JOIN T_Report_Columns_AI RC ON RM.Report_ID = RC.Report_ID
    INNER JOIN T_Column_Visibility_Mapping_AI CM ON RC.Column_ID = CM.Column_ID AND CM.Comp_ID = @Comp_ID AND CM.Service_ID = @Service_ID AND CM.Report_ID = RM.Report_ID AND CM.Is_Enabled = 1
    WHERE RM.Service_ID = @Service_ID;
END
GO
