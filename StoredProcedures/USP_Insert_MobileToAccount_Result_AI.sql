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
END
GO
