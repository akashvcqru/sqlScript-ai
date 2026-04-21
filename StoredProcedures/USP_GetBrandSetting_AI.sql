CREATE PROCEDURE [dbo].[USP_GetBrandSetting_AI]
    @Comp_ID NVARCHAR(50),
    @Type NVARCHAR(20) -- 'Brand' or 'Contact'
AS
BEGIN
    SET NOCOUNT ON;

    IF @Type = 'Brand'
    BEGIN
        SELECT [CompData] AS Data FROM [dbo].[BrandSettings] WHERE [Comp_ID] = @Comp_ID;
    END
    ELSE IF @Type = 'Contact'
    BEGIN
        SELECT [ContactUsContains] AS Data FROM [dbo].[BrandSettings] WHERE [Comp_ID] = @Comp_ID;
    END
END
GO
