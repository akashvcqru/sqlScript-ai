-- USP_AddOrUpdateMenuVisibility_AI
-- Upsert logic for menu visibility status
CREATE PROCEDURE USP_AddOrUpdateMenuVisibility_AI
    @MenuID INT,
    @Comp_ID NVARCHAR(50),
    @Service_ID NVARCHAR(50),
    @Status BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM T_Menu_Visibility_Mapping_AI 
               WHERE MenuID = @MenuID AND Comp_ID = @Comp_ID AND Service_ID = @Service_ID)
    BEGIN
        UPDATE T_Menu_Visibility_Mapping_AI
        SET Status = @Status,
            UpdatedDate = GETDATE()
        WHERE MenuID = @MenuID AND Comp_ID = @Comp_ID AND Service_ID = @Service_ID;
    END
    ELSE
    BEGIN
        INSERT INTO T_Menu_Visibility_Mapping_AI (MenuID, Comp_ID, Service_ID, Status, CreatedDate)
        VALUES (@MenuID, @Comp_ID, @Service_ID, @Status, GETDATE());
    END
END
GO
