IF OBJECT_ID('[dbo].[USP_ManageLandingPage_AI]', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE [dbo].[USP_ManageLandingPage_AI]
END
GO

CREATE PROCEDURE [dbo].[USP_ManageLandingPage_AI]
    @Action NVARCHAR(50),
    @PageName NVARCHAR(150) = NULL,
    @BrandName NVARCHAR(150) = NULL,
    @Comp_Id NVARCHAR(50) = NULL,
    @Service_Id NVARCHAR(50) = NULL,
    @ServiceType NVARCHAR(50) = NULL,
    @LogoUrl NVARCHAR(500) = NULL,
    @BackgroundImageUrl NVARCHAR(500) = NULL,
    @ProductImage1 NVARCHAR(500) = NULL,
    @ProductImage2 NVARCHAR(500) = NULL,
    @ProductImage3 NVARCHAR(500) = NULL,
    @ColorCode NVARCHAR(50) = NULL,
    @IsActive BIT = 1,
    @FieldConfigJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'Add'
    BEGIN
        INSERT INTO LandingPage (
            PageName, BrandName, Comp_Id, Service_Id, ServiceType, 
            LogoUrl, BackgroundImageUrl, ProductImage1, ProductImage2, ProductImage3, 
            ColorCode, IsActive, CreatedDate
        )
        VALUES (
            @PageName, @BrandName, @Comp_Id, @Service_Id, @ServiceType, 
            @LogoUrl, @BackgroundImageUrl, @ProductImage1, @ProductImage2, @ProductImage3, 
            @ColorCode, @IsActive, GETDATE()
        );

        DECLARE @NewPageId INT = SCOPE_IDENTITY();

        -- Handle Field Configs if JSON is provided
        IF @FieldConfigJson IS NOT NULL
        BEGIN
            -- Delete existing configs for this page
            DELETE FROM LandingPage_FieldConfig WHERE PageId = @NewPageId;

            -- Insert new configs from JSON
            INSERT INTO LandingPage_FieldConfig (PageId, FieldId, IsRequired, DisplayOrder, IsVisible, CustomLabel, CustomValidation, DefaultValue)
            SELECT @NewPageId, FieldId, IsRequired, DisplayOrder, IsVisible, CustomLabel, CustomValidation, DefaultValue
            FROM OPENJSON(@FieldConfigJson)
            WITH (
                FieldId INT,
                IsRequired BIT,
                DisplayOrder INT,
                IsVisible BIT,
                CustomLabel NVARCHAR(150),
                CustomValidation NVARCHAR(200),
                DefaultValue NVARCHAR(150)
            );
        END

        SELECT 1 AS Status, 'Landing page added successfully' AS Message;
    END

    ELSE IF @Action = 'Update'
    BEGIN
        UPDATE LandingPage
        SET PageName = ISNULL(@PageName, PageName),
            BrandName = ISNULL(@BrandName, BrandName),
            ServiceType = ISNULL(@ServiceType, ServiceType),
            LogoUrl = ISNULL(@LogoUrl, LogoUrl),
            BackgroundImageUrl = ISNULL(@BackgroundImageUrl, BackgroundImageUrl),
            ProductImage1 = ISNULL(@ProductImage1, ProductImage1),
            ProductImage2 = ISNULL(@ProductImage2, ProductImage2),
            ProductImage3 = ISNULL(@ProductImage3, ProductImage3),
            ColorCode = ISNULL(@ColorCode, ColorCode),
            IsActive = ISNULL(@IsActive, IsActive)
        WHERE Comp_Id = @Comp_Id AND Service_Id = @Service_Id;

        -- Update Field Configs if JSON is provided
        IF @FieldConfigJson IS NOT NULL
        BEGIN
            DECLARE @UpdatePageId INT;
            SELECT @UpdatePageId = PageId FROM LandingPage WHERE Comp_Id = @Comp_Id AND Service_Id = @Service_Id;

            IF @UpdatePageId IS NOT NULL
            BEGIN
                DELETE FROM LandingPage_FieldConfig WHERE PageId = @UpdatePageId;

                INSERT INTO LandingPage_FieldConfig (PageId, FieldId, IsRequired, DisplayOrder, IsVisible, CustomLabel, CustomValidation, DefaultValue)
                SELECT @UpdatePageId, FieldId, IsRequired, DisplayOrder, IsVisible, CustomLabel, CustomValidation, DefaultValue
                FROM OPENJSON(@FieldConfigJson)
                WITH (
                    FieldId INT,
                    IsRequired BIT,
                    DisplayOrder INT,
                    IsVisible BIT,
                    CustomLabel NVARCHAR(150),
                    CustomValidation NVARCHAR(200),
                    DefaultValue NVARCHAR(150)
                );
            END
        END

        SELECT 1 AS Status, 'Landing page updated successfully' AS Message;
    END

    ELSE IF @Action = 'List'
    BEGIN
        -- Table 0: Landing Pages
        SELECT * FROM LandingPage WHERE Comp_Id = ISNULL(@Comp_Id, Comp_Id);

        -- Table 1: Field Configs (Returning all for the filtered pages)
        SELECT fc.*, f.FieldName, f.FieldType AS BaseFieldType
        FROM LandingPage_FieldConfig fc
        INNER JOIN LandingPage lp ON fc.PageId = lp.PageId
        LEFT JOIN Master_InputFieldsWeb f ON fc.FieldId = f.FieldId
        WHERE lp.Comp_Id = ISNULL(@Comp_Id, lp.Comp_Id);
    END

    ELSE IF @Action = 'GetByService'
    BEGIN
        -- Table 0: Landing Page
        SELECT TOP 1 * FROM LandingPage 
        WHERE Comp_Id = @Comp_Id 
        AND (Service_Id = @Service_Id OR @Service_Id IS NULL)
        ORDER BY CreatedDate DESC;

        -- Table 1: Field Configs
        DECLARE @Pid INT;
        SELECT TOP 1 @Pid = PageId FROM LandingPage 
        WHERE Comp_Id = @Comp_Id 
        AND (Service_Id = @Service_Id OR @Service_Id IS NULL)
        ORDER BY CreatedDate DESC;

        SELECT fc.*, f.FieldName, f.FieldType AS BaseFieldType
        FROM LandingPage_FieldConfig fc
        LEFT JOIN Master_InputFieldsWeb f ON fc.FieldId = f.FieldId
        WHERE fc.PageId = @Pid;
    END

    ELSE IF @Action = 'GetByPageName'
    BEGIN
        -- Table 0: Landing Page
        SELECT lp.*, c.Comp_Name AS CompanyName
        FROM LandingPage lp
        LEFT JOIN Comp_Reg c ON lp.Comp_Id = c.Comp_ID
        WHERE lp.PageName = @PageName;

        -- Table 1: Field Configs
        SELECT fc.*, f.FieldName, f.FieldType AS BaseFieldType
        FROM LandingPage_FieldConfig fc
        INNER JOIN LandingPage lp ON fc.PageId = lp.PageId
        LEFT JOIN Master_InputFieldsWeb f ON fc.FieldId = f.FieldId
        WHERE lp.PageName = @PageName;
    END
END
GO
