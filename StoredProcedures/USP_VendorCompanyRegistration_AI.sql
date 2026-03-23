CREATE OR ALTER PROCEDURE [dbo].[USP_VendorCompanyRegistration_AI]
    @CompanyName NVARCHAR(50),
    @ContactPerson NVARCHAR(50),
    @Email NVARCHAR(50),
    @Mobile NVARCHAR(50),
    @LogoPath NVARCHAR(MAX) = NULL,
    @Password NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Check for duplicate email (using Delete_Flag logic if applicable)
    -- As per legacy logic, we check if there are NO rows with Delete_Flag = 1
    -- This implies Delete_Flag = 1 means ACTIVE.
    IF EXISTS (SELECT 1 FROM Comp_Reg WHERE Comp_Email = @Email AND Delete_Flag = 1)
    BEGIN
        SELECT 0 AS Success, 'This email id already registered in our system. Please enter different email id.' AS Message;
        RETURN;
    END

    -- 2. Generate Comp_ID
    DECLARE @Prefix NVARCHAR(50), @Start INT, @CompID NVARCHAR(50);
    SELECT @Prefix = PrPrefix, @Start = PrStart FROM Code_Gen WHERE Prfor = 'Company';
    
    IF @Prefix IS NULL
    BEGIN
        SELECT 0 AS Success, 'Configuration for Company ID generation not found.' AS Message;
        RETURN;
    END

    SET @CompID = @Prefix + '-' + CAST(@Start AS NVARCHAR(20));

    -- 3. Insert into Comp_Reg
    INSERT INTO Comp_Reg (
        Comp_ID, 
        Comp_Name, 
        Comp_Email, 
        Contact_Person, 
        Mobile_No, 
        Reg_Date, 
        Status, 
        Email_Vari_Flag, 
        Update_Flag, 
        Comp_Type, 
        Delete_Flag,
        logo_path,
        Password
    )
    VALUES (
        @CompID, 
        @CompanyName, 
        @Email, 
        @ContactPerson, 
        @Mobile,
        GETDATE(), 
        0, -- Status 0: Pending/Inactive
        0, -- Email_Vari_Flag 0: Unverified
        0, -- Update_Flag 0: New
        'L', -- Comp_Type 'L' as per legacy code
        1, -- Delete_Flag 1: Active (per legacy logic)
        @LogoPath,
        @Password
    );

    -- 4. Increment Code_Gen
    UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE [Prfor] = 'Company';

    -- 5. Return success
    SELECT 1 AS Success, 'Company registered successfully.' AS Message, @CompID AS Comp_ID;
END
GO
