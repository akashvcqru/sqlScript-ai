CREATE OR ALTER PROCEDURE [dbo].[USP_Insert_MobileToAccount_Result_AI]  
(  
    @MobileNo VARCHAR(10),  
  
    @Message VARCHAR(50) = NULL,  
    @Name_At_Bank VARCHAR(150) = NULL,  
    @Account_Number VARCHAR(30) = NULL,  
    @IFSC_Code VARCHAR(20) = NULL,  
    @VPA VARCHAR(100) = NULL,  
    @Bank_Reference VARCHAR(50) = NULL,  
    @Reference_Id VARCHAR(100) = NULL,  
    @Status VARCHAR(20) = NULL,  
  
    @Requested_At DATETIME = NULL,  
    @Completed_At DATETIME = NULL,  
  
    @Source VARCHAR(20) = NULL  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    -- 1. Insert into MobileToAccount_Audit
    INSERT INTO MobileToAccount_Audit  
    (  
        MobileNo,  
        Message,  
        Name_At_Bank,  
        Account_Number,  
        IFSC_Code,  
        VPA,  
        Bank_Reference,  
        Reference_Id,  
        Status,  
        Requested_At,  
        Completed_At,  
        Source  
    )  
    VALUES  
    (  
        LEFT(@MobileNo, 10),  
        LEFT(@Message, 50),  
        LEFT(@Name_At_Bank, 150),  
        LEFT(@Account_Number, 30),  
        LEFT(@IFSC_Code, 20),  
        LEFT(@VPA, 100),  
        LEFT(@Bank_Reference, 50),  
        LEFT(@Reference_Id, 100),  
        LEFT(@Status, 20),  
        @Requested_At,  
        @Completed_At,  
        LEFT(@Source, 20)  
    );  

    -- 2. If status is success and account & IFSC details are present, populate M_BankAccount & M_BankAccount_Audit for the Consumer
    IF (LOWER(ISNULL(@Status, '')) = 'success' AND ISNULL(@Account_Number, '') <> '' AND ISNULL(@IFSC_Code, '') <> '' AND ISNULL(@Account_Number, '') NOT LIKE '%XXXX%')
    BEGIN
        DECLARE @M_Consumerid INT = NULL;

        SELECT TOP 1 @M_Consumerid = M_Consumerid
        FROM M_Consumer
        WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10)
          AND IsDelete = 0;

        IF (@M_Consumerid IS NOT NULL)
        BEGIN
            DECLARE @Bank_ID NVARCHAR(50) = NULL;

            -- Check if M_BankAccount record exists for this consumer
            IF EXISTS (SELECT 1 FROM M_BankAccount WHERE M_Consumerid = @M_Consumerid)
            BEGIN
                SELECT TOP 1 @Bank_ID = Bank_ID 
                FROM M_BankAccount 
                WHERE M_Consumerid = @M_Consumerid 
                ORDER BY Row_ID DESC;

                UPDATE M_BankAccount
                SET Account_No = @Account_Number,
                    IFSC_Code = UPPER(@IFSC_Code),
                    Account_HolderNm = ISNULL(NULLIF(@Name_At_Bank, ''), Account_HolderNm)
                WHERE M_Consumerid = @M_Consumerid;
            END
            ELSE
            BEGIN
                -- Generate Bank_ID if creating new entry
                SELECT TOP 1 @Bank_ID = PrPrefix + CONVERT(VARCHAR, PrStart)
                FROM Code_Gen
                WHERE Prfor = 'Account' AND PrFlag = 1;

                IF (@Bank_ID IS NULL OR @Bank_ID = '')
                BEGIN
                    SET @Bank_ID = 'ACC' + CAST(FLOOR(RAND() * 89999 + 10000) AS VARCHAR(10));
                END
                ELSE
                BEGIN
                    UPDATE Code_Gen 
                    SET PrStart = PrStart + 1 
                    WHERE Prfor = 'Account' AND PrFlag = 1;
                END

                INSERT INTO M_BankAccount
                (
                    Bank_ID,
                    M_Consumerid,
                    Account_No,
                    IFSC_Code,
                    Account_HolderNm,
                    Entry_Date,
                    Flag
                )
                VALUES
                (
                    @Bank_ID,
                    @M_Consumerid,
                    @Account_Number,
                    UPPER(@IFSC_Code),
                    @Name_At_Bank,
                    GETDATE(),
                    1
                );
            END

            -- Insert audit record into M_BankAccount_Audit table
            IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'M_BankAccount_Audit')
            BEGIN
                INSERT INTO M_BankAccount_Audit
                (
                    Bank_ID,
                    M_Consumerid,
                    Account_No,
                    IFSC_Code,
                    Account_HolderNm,
                    Entry_Date,
                    Flag,
                    IsActive,
                    IsDelete,
                    Created_by,
                    Created_Date,
                    Remarks
                )
                VALUES
                (
                    ISNULL(@Bank_ID, 'ACC_AUTO'),
                    @M_Consumerid,
                    @Account_Number,
                    UPPER(@IFSC_Code),
                    @Name_At_Bank,
                    GETDATE(),
                    1,
                    1,
                    0,
                    'Tutelar_API',
                    GETDATE(),
                    'Auto updated via Tutelar EKYC lookup'
                );
            END
        END
    END
END
GO
