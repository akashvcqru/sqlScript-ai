CREATE OR ALTER PROCEDURE [dbo].[USP_VendorCompanyRegistration_AI]
    @CompanyName NVARCHAR(50),
    @ContactPerson NVARCHAR(50),
    @Email NVARCHAR(50),
    @Mobile NVARCHAR(50),
    @LogoPath NVARCHAR(MAX) = NULL,
    @Password NVARCHAR(50) = NULL,
    @AcceptedPolicy BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Check for duplicate email (using Delete_Flag logic if applicable)
    -- As per legacy logic, we check if there are NO rows with Delete_Flag = 1
    -- BUT, if the email exists but is NOT verified (Email_Vari_Flag = 0), we allow re-registration
    IF EXISTS (SELECT 1 FROM Comp_Reg WHERE Comp_Email = @Email AND Delete_Flag = 1 AND Email_Vari_Flag = 1)
    BEGIN
        SELECT 0 AS Success, 'This email id already registered in our system. Please enter different email id.' AS Message;
        RETURN;
    END

    -- If unverified record exists, we will delete it or just proceed to overwrite it by generating a new ID 
    -- (Or we could reuse the ID, but legacy code usually generates new ones)
    -- For safety, we delete the unverified record if it exists to avoid primary key constraints if Comp_ID was same
    DELETE FROM Comp_Reg WHERE Comp_Email = @Email AND Email_Vari_Flag = 0;

    -- 2. Check Verification Status in Tbl_EmailVerification
    DECLARE @IsVerified BIT = 0;
    IF EXISTS (SELECT 1 FROM Tbl_EmailVerification WHERE Email = @Email AND IsVerified = 1)
        SET @IsVerified = 1;

    -- 3. Generate Comp_ID
    DECLARE @Prefix NVARCHAR(50), @Start INT, @CompID NVARCHAR(50);
    SELECT @Prefix = PrPrefix, @Start = PrStart FROM Code_Gen WHERE Prfor = 'Company';
    
    IF @Prefix IS NULL
    BEGIN
        SELECT 0 AS Success, 'Configuration for Company ID generation not found.' AS Message;
        RETURN;
    END

    SET @CompID = @Prefix + '-' + CAST(@Start AS NVARCHAR(20));

    -- 4. Insert into Comp_Reg
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
        @IsVerified, -- Email_Vari_Flag based on Tbl_EmailVerification
        0, -- Update_Flag 0: New
        'L', -- Comp_Type 'L' as per legacy code
        1, -- Delete_Flag 1: Active (per legacy logic)
        @LogoPath,
        @Password
    );

    -- 4. Increment Code_Gen
    UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE [Prfor] = 'Company';

    -- 5. Insert Policy Acceptance if applicable
    IF @AcceptedPolicy = 1
    BEGIN
        INSERT INTO Tbl_UserPolicyAcceptance (Comp_Id, PolicyVersion, AcceptedOn, AcceptedBy)
        VALUES (@CompID, '1.0', GETDATE(), 'User');
    END

    -- 6. Return success
    SELECT 1 AS Success, 'Company registered successfully.' AS Message, @CompID AS Comp_ID;
END
GO
