CREATE PROCEDURE [dbo].[USP_ContactUsSetting_AI]
    @Comp_ID NVARCHAR(50),
    @ContactNumber NVARCHAR(50) = NULL,
    @ContactEmail NVARCHAR(100) = NULL,
    @ContactContents NVARCHAR(MAX) = NULL,
    @TermsConditionLink NVARCHAR(MAX) = NULL,
    @AboutUsLink NVARCHAR(MAX) = NULL,
    @PrivacyPolicyLink NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentContactUsData NVARCHAR(MAX);
    
    -- Fetch existing data
    SELECT @CurrentContactUsData = [ContactUsContains] FROM [dbo].[BrandSettings_AI] WHERE [Comp_ID] = @Comp_ID;

    IF @CurrentContactUsData IS NOT NULL
    BEGIN
        -- Update existing record
        -- Merge new values into existing JSON
        SET @CurrentContactUsData = JSON_MODIFY(@CurrentContactUsData, '$.ContactNumber', ISNULL(@ContactNumber, JSON_VALUE(@CurrentContactUsData, '$.ContactNumber')));
        SET @CurrentContactUsData = JSON_MODIFY(@CurrentContactUsData, '$.ContactEmail', ISNULL(@ContactEmail, JSON_VALUE(@CurrentContactUsData, '$.ContactEmail')));
        SET @CurrentContactUsData = JSON_MODIFY(@CurrentContactUsData, '$.ContactContents', ISNULL(@ContactContents, JSON_VALUE(@CurrentContactUsData, '$.ContactContents')));
        SET @CurrentContactUsData = JSON_MODIFY(@CurrentContactUsData, '$.TermsConditionLink', ISNULL(@TermsConditionLink, JSON_VALUE(@CurrentContactUsData, '$.TermsConditionLink')));
        SET @CurrentContactUsData = JSON_MODIFY(@CurrentContactUsData, '$.AboutUsLink', ISNULL(@AboutUsLink, JSON_VALUE(@CurrentContactUsData, '$.AboutUsLink')));
        SET @CurrentContactUsData = JSON_MODIFY(@CurrentContactUsData, '$.PrivacyPolicyLink', ISNULL(@PrivacyPolicyLink, JSON_VALUE(@CurrentContactUsData, '$.PrivacyPolicyLink')));

        UPDATE [dbo].[BrandSettings_AI]
        SET [ContactUsContains] = @CurrentContactUsData,
            [Updated_Date] = GETDATE(),
            [Updated_by] = 'API'
        WHERE [Comp_ID] = @Comp_ID;
        
        SELECT 1 AS Success, 'Contact Us settings updated successfully.' AS Message;
    END
    ELSE
    BEGIN
        -- Insert new record (or update if Comp_ID exists but ContactUsContains is null)
        DECLARE @NewContactUsData NVARCHAR(MAX);
        SET @NewContactUsData = (
            SELECT 
                ISNULL(@ContactNumber, '') AS ContactNumber,
                ISNULL(@ContactEmail, '') AS ContactEmail,
                ISNULL(@ContactContents, '') AS ContactContents,
                ISNULL(@TermsConditionLink, '') AS TermsConditionLink,
                ISNULL(@AboutUsLink, '') AS AboutUsLink,
                ISNULL(@PrivacyPolicyLink, '') AS PrivacyPolicyLink
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        IF EXISTS (SELECT 1 FROM [dbo].[BrandSettings_AI] WHERE [Comp_ID] = @Comp_ID)
        BEGIN
            UPDATE [dbo].[BrandSettings_AI]
            SET [ContactUsContains] = @NewContactUsData,
                [Updated_Date] = GETDATE(),
                [Updated_by] = 'API'
            WHERE [Comp_ID] = @Comp_ID;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[BrandSettings_AI] ([Comp_ID], [ContactUsContains], [Created_Date], [Created_by], [IsActive], [IsDelete])
            VALUES (@Comp_ID, @NewContactUsData, GETDATE(), 'API', 1, 0);
        END
        
        SELECT 1 AS Success, 'Contact Us settings added successfully.' AS Message;
    END
END
GO
