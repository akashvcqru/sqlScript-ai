/****** Object:  StoredProcedure [dbo].[USP_ManageCompUser_AI]    Script Date: 2026-06-15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create Roles table if not exists
IF OBJECT_ID('Roles', 'U') IS NULL
BEGIN
    CREATE TABLE Roles (
        RoleId INT PRIMARY KEY IDENTITY(1,1),
        RoleName VARCHAR(50) NOT NULL,
        Description NVARCHAR(255),
        IsActive BIT DEFAULT 1
    );

    INSERT INTO Roles (RoleName, Description) VALUES ('Company Admin', 'Full access to all company features');
    INSERT INTO Roles (RoleName, Description) VALUES ('Report Viewer', 'Can only view specific assigned reports');
END
GO

-- Create Comp_Users table if not exists
IF OBJECT_ID('Comp_Users', 'U') IS NULL
BEGIN
    CREATE TABLE Comp_Users (
        UserId INT PRIMARY KEY IDENTITY(1,1),
        Comp_ID VARCHAR(255) NOT NULL,
        RoleId INT NOT NULL,
        UserEmail VARCHAR(150) NOT NULL,
        Password VARCHAR(255) NOT NULL,
        FirstName VARCHAR(100),
        LastName VARCHAR(100),
        MobileNo VARCHAR(20),
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE(),
        LastLoginDate DATETIME,
        
        FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
    );
END
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_ManageCompUser_AI]
    @Action VARCHAR(20),
    @UserId INT = NULL,
    @Comp_ID VARCHAR(255) = NULL,
    @RoleId INT = NULL,
    @UserEmail VARCHAR(150) = NULL,
    @Password VARCHAR(255) = NULL,
    @FirstName VARCHAR(100) = NULL,
    @LastName VARCHAR(100) = NULL,
    @MobileNo VARCHAR(20) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'GET'
    BEGIN
        SELECT 
            u.UserId,
            u.Comp_ID,
            u.RoleId,
            r.RoleName,
            u.UserEmail,
            u.FirstName,
            u.LastName,
            u.MobileNo,
            u.IsActive,
            u.CreatedDate
        FROM Comp_Users u
        INNER JOIN Roles r ON u.RoleId = r.RoleId
        WHERE u.Comp_ID = @Comp_ID;
    END
    ELSE IF @Action = 'INSERT'
    BEGIN
        -- Check if email already exists for any company
        IF EXISTS (SELECT 1 FROM Comp_Users WHERE UserEmail = @UserEmail)
        BEGIN
            SELECT 0 AS success, 'User with this email already exists.' AS message;
            RETURN;
        END

        -- Also check old Comp_Reg to be perfectly safe
        IF EXISTS (SELECT 1 FROM Comp_Reg WHERE Comp_Email = @UserEmail)
        BEGIN
            SELECT 0 AS success, 'User with this email already exists in main registration.' AS message;
            RETURN;
        END

        INSERT INTO Comp_Users (Comp_ID, RoleId, UserEmail, Password, FirstName, LastName, MobileNo, IsActive, CreatedDate)
        VALUES (@Comp_ID, @RoleId, @UserEmail, @Password, @FirstName, @LastName, @MobileNo, @IsActive, GETDATE());

        SELECT 1 AS success, 'User created successfully.' AS message, SCOPE_IDENTITY() AS UserId;
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
        -- Check if user belongs to this company before updating
        IF NOT EXISTS (SELECT 1 FROM Comp_Users WHERE UserId = @UserId AND Comp_ID = @Comp_ID)
        BEGIN
            SELECT 0 AS success, 'User not found or unauthorized.' AS message;
            RETURN;
        END

        -- Check email conflict if changing email
        IF EXISTS (SELECT 1 FROM Comp_Users WHERE UserEmail = @UserEmail AND UserId != @UserId)
        BEGIN
            SELECT 0 AS success, 'Another user with this email already exists.' AS message;
            RETURN;
        END

        UPDATE Comp_Users
        SET 
            RoleId = ISNULL(@RoleId, RoleId),
            UserEmail = ISNULL(@UserEmail, UserEmail),
            FirstName = ISNULL(@FirstName, FirstName),
            LastName = ISNULL(@LastName, LastName),
            MobileNo = ISNULL(@MobileNo, MobileNo),
            IsActive = ISNULL(@IsActive, IsActive)
        WHERE UserId = @UserId;

        SELECT 1 AS success, 'User updated successfully.' AS message, @UserId AS UserId;
    END
END
GO
