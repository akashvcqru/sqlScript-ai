CREATE PROCEDURE [dbo].[USP_SaveApiErrorLog_AI]  
(  
    @Comp_Id        VARCHAR(20),  
    @M_ConsumerId   INT,  
    @ErrorMessage   NVARCHAR(MAX)  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    INSERT INTO dbo.API_ErrorLog  
    (  
        Comp_Id,  
        M_ConsumerId,  
        ErrorMessage  
    )  
    VALUES  
    (  
        @Comp_Id,  
        @M_ConsumerId,  
        @ErrorMessage  
    );  
END;
