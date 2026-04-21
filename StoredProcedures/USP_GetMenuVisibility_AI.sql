-- USP_GetMenuVisibility_AI
-- Fetch all menus with their visibility status for a given company and service
-- (Management/Admin view)
CREATE PROCEDURE USP_GetMenuVisibility_AI
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
        m.ParentMenuID,
        m.MenuOrder,
        COALESCE(mv.Status, 0) AS Status,
        mv.UpdatedDate
    FROM M_Menu_AI m
    LEFT JOIN T_Menu_Visibility_Mapping_AI mv ON m.MenuID = mv.MenuID 
        AND mv.Comp_ID = @Comp_ID 
        AND mv.Service_ID = @Service_ID
    WHERE m.IsEnabled = 1
    ORDER BY m.MenuOrder;
END
GO
