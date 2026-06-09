SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Antigravity
-- Create date: 2026-06-09
-- Description: Get mapped products for user types under a company with filter/search and pagination
-- =============================================
CREATE PROCEDURE [dbo].[USP_BL_GetAssignProductToUserType_AI]
    @CompID VARCHAR(50),
    @SearchTerm VARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate Offset
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    -- Get total count for pagination
    SELECT COUNT(1)
    FROM User_Type u
    WHERE u.Comp_ID = @CompID
      AND u.IsActive = 1
      AND u.CanScanCoupon = 1
      AND (
          @SearchTerm IS NULL 
          OR u.User_Type LIKE '%' + @SearchTerm + '%'
          OR EXISTS (
              SELECT 1 
              FROM Pro_Reg p 
              WHERE p.Pro_ID IN (SELECT TRIM(value) FROM STRING_SPLIT(u.ProductMapped, ','))
              AND p.Pro_Name LIKE '%' + @SearchTerm + '%'
          )
      );

    -- Get paginated records
    SELECT 
        u.Row_ID, 
        u.User_Type, 
        u.ProductMapped,
        (
            SELECT STRING_AGG(p.pro_name, ', ')
            FROM Pro_Reg p
            WHERE p.Pro_ID IN (
                SELECT TRIM(value) FROM STRING_SPLIT(u.ProductMapped, ',')
            )
        ) AS ProductNames
    FROM 
        User_Type u
    WHERE 
        u.Comp_ID = @CompID
        AND u.IsActive = 1
        AND u.CanScanCoupon = 1
        AND (
            @SearchTerm IS NULL 
            OR u.User_Type LIKE '%' + @SearchTerm + '%'
            OR EXISTS (
                SELECT 1 
                FROM Pro_Reg p 
                WHERE p.Pro_ID IN (SELECT TRIM(value) FROM STRING_SPLIT(u.ProductMapped, ','))
                AND p.Pro_Name LIKE '%' + @SearchTerm + '%'
            )
        )
    ORDER BY u.User_Type
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO
