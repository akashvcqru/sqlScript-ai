IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_FirebaseProject_AI')
BEGIN
    CREATE TABLE tbl_FirebaseProject_AI (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Comp_ID VARCHAR(50) NOT NULL,
        Project_ID VARCHAR(100) NULL,
        Credential_Json NVARCHAR(MAX) NOT NULL,
        Is_Active BIT NOT NULL DEFAULT 1,
        Remarks NVARCHAR(500) NULL,
        Created_Date DATETIME NOT NULL DEFAULT GETDATE(),
        Updated_Date DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT UQ_FirebaseProject_CompID UNIQUE (Comp_ID)
    );
END;
GO
