CREATE PROCEDURE [dbo].[USP_Insert_MobileToAccount_Result_AI]  
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
        @MobileNo,  
        @Message,  
        @Name_At_Bank,  
        @Account_Number,  
        @IFSC_Code,  
        @VPA,  
        @Bank_Reference,  
        @Reference_Id,  
        @Status,  
        @Requested_At,  
        @Completed_At,  
        @Source  
    );  
END
