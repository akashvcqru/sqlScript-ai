USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-04-01
-- Description: Manage Landing Pages and their field configurations (Natural Key Version)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageLandingPage_AI]
    @Action VARCHAR(20) = 'List',
    @PageName VARCHAR(150) = NULL,
    @BrandName VARCHAR(150) = NULL,
    @Comp_Id VARCHAR(50) = NULL,
    @Service_Id VARCHAR(50) = NULL,
    @ServiceType VARCHAR(50) = NULL,
    @LogoUrl VARCHAR(500) = NULL,
    @BackgroundImageUrl VARCHAR(500) = NULL,
    @ProductImage1 VARCHAR(500) = NULL,
    @ProductImage2 VARCHAR(500) = NULL,
    @ProductImage3 VARCHAR(500) = NULL,
    @IsActive BIT = 1,
    @FieldConfigJson NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'Add'
    BEGIN
        -- Check if already exists
        IF EXISTS (SELECT 1 FROM LandingPage WHERE Comp_Id = @Comp_Id AND Service_Id = @Service_Id)
        BEGIN
            SELECT @Comp_Id AS Comp_Id, @Service_Id AS Service_Id, 'Landing page already exists for this service.' AS [Message], 0 AS [Status];
            RETURN;
        END

        INSERT INTO LandingPage (
            Comp_Id, Service_Id, PageName, BrandName, ServiceType, 
            LogoUrl, BackgroundImageUrl, ProductImage1, ProductImage2, ProductImage3, 
            IsActive, CreatedDate
        )
        VALUES (
            @Comp_Id, @Service_Id, @PageName, @BrandName, @ServiceType, 
            @LogoUrl, @BackgroundImageUrl, @ProductImage1, @ProductImage2, @ProductImage3, 
            @IsActive, GETDATE()
        );
        
        -- Insert field configurations from JSON
        IF @FieldConfigJson IS NOT NULL AND @FieldConfigJson <> ''
        BEGIN
            INSERT INTO LandingPage_FieldConfig (
                Comp_Id, Service_Id, FieldId, IsRequired, DisplayOrder, IsVisible, 
                CustomLabel, CustomValidation, DefaultValue, CreatedDate
            )
            SELECT 
                @Comp_Id, @Service_Id, FieldId, IsRequired, DisplayOrder, IsVisible, 
                CustomLabel, CustomValidation, DefaultValue, GETDATE()
            FROM OPENJSON(@FieldConfigJson)
            WITH (
                FieldId INT,
                IsRequired BIT,
                DisplayOrder INT,
                IsVisible BIT,
                CustomLabel VARCHAR(150),
                CustomValidation VARCHAR(200),
                DefaultValue VARCHAR(200)
            );
        END

        SELECT @Comp_Id AS Comp_Id, @Service_Id AS Service_Id, 'Landing page created successfully' AS [Message], 1 AS [Status];
    END
    ELSE IF @Action = 'Update'
    BEGIN
        IF EXISTS (SELECT 1 FROM LandingPage WHERE Comp_Id = @Comp_Id AND Service_Id = @Service_Id)
        BEGIN
            UPDATE LandingPage
            SET 
                PageName = @PageName,
                BrandName = @BrandName,
                ServiceType = @ServiceType,
                LogoUrl = @LogoUrl,
                BackgroundImageUrl = @BackgroundImageUrl,
                ProductImage1 = @ProductImage1,
                ProductImage2 = @ProductImage2,
                ProductImage3 = @ProductImage3,
                IsActive = @IsActive
            WHERE Comp_Id = @Comp_Id AND Service_Id = @Service_Id;

            -- Update field configurations: Delete existing and re-insert
            IF @FieldConfigJson IS NOT NULL AND @FieldConfigJson <> ''
            BEGIN
                DELETE FROM LandingPage_FieldConfig WHERE Comp_Id = @Comp_Id AND Service_Id = @Service_Id;

                INSERT INTO LandingPage_FieldConfig (
                    Comp_Id, Service_Id, FieldId, IsRequired, DisplayOrder, IsVisible, 
                    CustomLabel, CustomValidation, DefaultValue, CreatedDate
                )
                SELECT 
                    @Comp_Id, @Service_Id, FieldId, IsRequired, DisplayOrder, IsVisible, 
                    CustomLabel, CustomValidation, DefaultValue, GETDATE()
                FROM OPENJSON(@FieldConfigJson)
                WITH (
                    FieldId INT,
                    IsRequired BIT,
                    DisplayOrder INT,
                    IsVisible BIT,
                    CustomLabel VARCHAR(150),
                    CustomValidation VARCHAR(200),
                    DefaultValue VARCHAR(200)
                );
            END

            SELECT @Comp_Id AS Comp_Id, @Service_Id AS Service_Id, 'Landing page updated successfully' AS [Message], 1 AS [Status];
        END
        ELSE
        BEGIN
            SELECT @Comp_Id AS Comp_Id, @Service_Id AS Service_Id, 'Landing page not found' AS [Message], 0 AS [Status];
        END
    END
    ELSE IF @Action = 'List'
    BEGIN
        -- Table 0: Landing Pages
        SELECT * FROM LandingPage 
        WHERE (@Comp_Id IS NULL OR Comp_Id = @Comp_Id)
        ORDER BY CreatedDate DESC;

        -- Table 1: Field Configs for those Landing Pages
        SELECT FC.*, MF.FieldName, MF.FieldType as BaseFieldType
        FROM LandingPage_FieldConfig FC
        INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId
        WHERE (@Comp_Id IS NULL OR FC.Comp_Id = @Comp_Id)
        ORDER BY FC.Comp_Id, FC.Service_Id, FC.DisplayOrder;
    END
    ELSE IF @Action = 'GetById' OR @Action = 'GetByService'
    BEGIN
        -- Get Landing Page main data
        SELECT * FROM LandingPage WHERE Comp_Id = @Comp_Id AND Service_Id = @Service_Id;
        
        -- Get Field Configs
        SELECT FC.*, MF.FieldName, MF.FieldType as BaseFieldType
        FROM LandingPage_FieldConfig FC
        INNER JOIN Master_InputFieldsWeb MF ON FC.FieldId = MF.FieldId
        WHERE FC.Comp_Id = @Comp_Id AND FC.Service_Id = @Service_Id
        ORDER BY FC.DisplayOrder;
    END
END
GO
