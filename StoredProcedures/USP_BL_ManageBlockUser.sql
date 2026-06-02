SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[USP_BL_ManageBlockUser]
    @Action VARCHAR(10),        -- 'GET' or 'ADD'
    @Comp_Id VARCHAR(20) = NULL,
    @MobileNo VARCHAR(20) = NULL,
    @Search VARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @IsExport BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'GET'
    BEGIN
        IF @IsExport = 1
        BEGIN
            SELECT 
                mc.Entry_Date AS Registration_Date,
                mc.ConsumerName,
                mc.MobileNo AS MobileNumber,
                mc.PinCode,
                mc.City,
                mc.block_date AS block_date
            FROM M_Consumer mc WITH (NOLOCK)
            WHERE mc.Comp_id = @Comp_Id 
              AND mc.IsActive = '1' 
              AND mc.IsDelete = '1'
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              )
            ORDER BY mc.Entry_Date DESC;
        END
        ELSE
        BEGIN
            SELECT 
                mc.Entry_Date AS Registration_Date,
                mc.ConsumerName,
                mc.MobileNo AS MobileNumber,
                mc.PinCode,
                mc.City,
                mc.block_date AS block_date
            FROM M_Consumer mc WITH (NOLOCK)
            WHERE mc.Comp_id = @Comp_Id 
              AND mc.IsActive = '1' 
              AND mc.IsDelete = '1'
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              )
            ORDER BY mc.Entry_Date DESC
            OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;

            -- Pagination metadata
            SELECT 
                COUNT(1) AS TotalRecords,
                @Page AS CurrentPage,
                @Limit AS Limit,
                CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
            FROM M_Consumer mc WITH (NOLOCK)
            WHERE mc.Comp_id = @Comp_Id 
              AND mc.IsActive = '1' 
              AND mc.IsDelete = '1'
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              );
        END
    END
    ELSE IF @Action = 'ADD'
    BEGIN
        UPDATE M_Consumer
        SET IsActive = '1',
            IsDelete = '1',
            block_date = GETDATE()
        WHERE MobileNo = @MobileNo;

        IF @@ROWCOUNT > 0
        BEGIN
            SELECT 1 AS Status, 'Consumer marked as Blocked.' AS Message;
        END
        ELSE
        BEGIN
            SELECT 0 AS Status, 'No matching mobile number found.' AS Message;
        END
    END
END
GO
