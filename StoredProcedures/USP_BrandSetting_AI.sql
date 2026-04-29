ALTER PROCEDURE [dbo].[USP_BrandSetting_AI]
    @Comp_ID NVARCHAR(50),
    @Logo NVARCHAR(MAX) = NULL,
    @SplashImage NVARCHAR(MAX) = NULL,
    @Color NVARCHAR(50) = NULL,
    @CompanyName NVARCHAR(255) = NULL,
    @IsSplashApply BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentCompData NVARCHAR(MAX);
    
    -- Fetch existing data
    SELECT @CurrentCompData = [CompData] FROM [dbo].[BrandSettings_AI] WHERE [Comp_ID] = @Comp_ID;

    IF @CurrentCompData IS NOT NULL
    BEGIN
        -- Update existing record
        -- Merge new values into existing JSON
        -- ProductImage is mapped to SplashImage in the request
        
        SET @CurrentCompData = JSON_MODIFY(@CurrentCompData, '$.Logo', ISNULL(@Logo, JSON_VALUE(@CurrentCompData, '$.Logo')));
        SET @CurrentCompData = JSON_MODIFY(@CurrentCompData, '$.ProductImage', ISNULL(@SplashImage, JSON_VALUE(@CurrentCompData, '$.ProductImage')));
        SET @CurrentCompData = JSON_MODIFY(@CurrentCompData, '$.BackgroundColor', ISNULL(@Color, JSON_VALUE(@CurrentCompData, '$.BackgroundColor')));
        SET @CurrentCompData = JSON_MODIFY(@CurrentCompData, '$.CompName', ISNULL(@CompanyName, JSON_VALUE(@CurrentCompData, '$.CompName')));
        SET @CurrentCompData = JSON_MODIFY(@CurrentCompData, '$.IsSplashApply', ISNULL(@IsSplashApply, JSON_VALUE(@CurrentCompData, '$.IsSplashApply')));

        UPDATE [dbo].[BrandSettings_AI]
        SET [CompData] = @CurrentCompData,
            [Updated_Date] = GETDATE(),
            [Updated_by] = 'API'
        WHERE [Comp_ID] = @Comp_ID;
        
        SELECT 1 AS Success, 'Brand settings updated successfully.' AS Message;
    END
    ELSE
    BEGIN
        -- Insert new record
        DECLARE @CompData NVARCHAR(MAX);
        SET @CompData = (
            SELECT 
                ISNULL(@Logo, '') AS Logo,
                ISNULL(@SplashImage, '') AS ProductImage,
                ISNULL(@Color, '') AS BackgroundColor,
                ISNULL(@CompanyName, '') AS CompName,
                ISNULL(@IsSplashApply, 0) AS IsSplashApply
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        INSERT INTO [dbo].[BrandSettings_AI] ([Comp_ID], [CompData], [Created_Date], [Created_by], [IsActive], [IsDelete])
        VALUES (@Comp_ID, @CompData, GETDATE(), 'API', 1, 0);
        
        SELECT 1 AS Success, 'Brand settings added successfully.' AS Message;
    END
END
GO
