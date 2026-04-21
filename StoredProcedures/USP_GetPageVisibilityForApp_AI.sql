-- USP_GetPageVisibilityForApp_AI
-- Fetch only enabled menus for a given company and service
-- (Dashboard/App view)
CREATE PROCEDURE USP_GetPageVisibilityForApp_AI
    @Comp_ID NVARCHAR(50),
    @Service_ID NVARCHAR(50)
AS
BEGIN
    SELECT 
        m.MenuID,
        m.MenuName,
        m.ControlName,
        m.URL,
        m.IconClass,
        m.ParentMenuID
    FROM M_Menu_AI m
    INNER JOIN T_Menu_Visibility_Mapping_AI mv ON m.MenuID = mv.MenuID 
    WHERE mv.Comp_ID = @Comp_ID 
        AND mv.Service_ID = @Service_ID
        AND mv.Status = 1
        AND m.IsEnabled = 1
    ORDER BY m.MenuOrder;
END
GO
