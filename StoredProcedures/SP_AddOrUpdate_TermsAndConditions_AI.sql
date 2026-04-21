CREATE PROCEDURE [dbo].[SP_AddOrUpdate_TermsAndConditions_AI]  
(  
    @MobileNo   VARCHAR(20),  
    @Comp_Id    VARCHAR(20),  
    @IsAccepted BIT  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    IF EXISTS (  
        SELECT 1   
        FROM M_TermsAndConditions_Acceptance  
        WHERE MobileNo = @MobileNo  
          AND Comp_Id  = @Comp_Id  
    )  
    BEGIN  
        UPDATE M_TermsAndConditions_Acceptance  
        SET IsAccepted = @IsAccepted,  
            AcceptedOn = CASE WHEN @IsAccepted = 1 THEN GETDATE() ELSE NULL END  
        WHERE MobileNo = @MobileNo  
          AND Comp_Id  = @Comp_Id;  
    END  
    ELSE  
    BEGIN  
        INSERT INTO M_TermsAndConditions_Acceptance  
        (  
            MobileNo,  
            Comp_Id,  
            IsAccepted,  
            AcceptedOn  
        )  
        VALUES  
        (  
            @MobileNo,  
            @Comp_Id,  
            @IsAccepted,  
            CASE WHEN @IsAccepted = 1 THEN GETDATE() ELSE NULL END  
        );  
    END  
  
    SELECT 'Success' AS Status;  
END
