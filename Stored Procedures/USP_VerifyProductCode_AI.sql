SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:        AI Assistant
-- Create date:   2026-04-11
-- Description:   Modernized product code verification for landing pages
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_VerifyProductCode_AI]
    @Code1 VARCHAR(10),
    @Code2 VARCHAR(10),
    @Latitude VARCHAR(50) = NULL,
    @Longitude VARCHAR(50) = NULL,
    @Comp_Id VARCHAR(50) = NULL,
    @Service_Id VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Pro_ID VARCHAR(50);
    DECLARE @Use_Count INT;
    DECLARE @ActualCompId VARCHAR(50);
    DECLARE @TableName NVARCHAR(50) = 'M_Code';
    DECLARE @SQL NVARCHAR(MAX);

    -- 1. Identify which table to use (M_Code or M_Code_PFL)
    -- This logic mimics ServiceLogic.cs for specific companies
    IF @Comp_Id = 'Comp-1693' 
        SET @TableName = 'M_Code_PFL';

    -- 2. Basic Code Validation
    -- Check if code exists and is dispatched/received
    SET @SQL = N'
    SELECT @Pro_ID = M.Pro_ID, @Use_Count = ISNULL(M.Use_Count, 0), @ActualCompId = C.Comp_ID
    FROM ' + @TableName + ' M
    INNER JOIN Pro_Reg P ON M.Pro_ID = P.Pro_ID
    INNER JOIN Comp_Reg C ON P.Comp_ID = C.Comp_ID
    WHERE M.Code1 = @Code1 AND M.Code2 = @Code2
    AND (M.ScrapeFlag = 0 OR M.ScrapeFlag IS NULL)';

    EXEC sp_executesql @SQL, 
        N'@Code1 VARCHAR(10), @Code2 VARCHAR(10), @Pro_ID VARCHAR(50) OUTPUT, @Use_Count INT OUTPUT, @ActualCompId VARCHAR(50) OUTPUT',
        @Code1, @Code2, @Pro_ID OUTPUT, @Use_Count OUTPUT, @ActualCompId OUTPUT;

    IF @Pro_ID IS NULL
    BEGIN
        DECLARE @InvalidMsg NVARCHAR(MAX);
        EXEC [USP_ManageCodeCheckMessages_AI] @Action = 'GetMessage', @Comp_Id = @Comp_Id, @Message_Type = 'Invalid', @Message_Text = @InvalidMsg OUTPUT;
        SELECT 0 AS IsValid, ISNULL(@InvalidMsg, 'Invalid or unscanned code.') AS Message;
        RETURN;
    END

    -- 3. Check for "Already Used"
    IF @Use_Count > 0
    BEGIN
        DECLARE @AlreadyMsg NVARCHAR(MAX);
        EXEC [USP_ManageCodeCheckMessages_AI] @Action = 'GetMessage', @Comp_Id = @ActualCompId, @Service_Id = @Service_Id, @Message_Type = 'Already', @Message_Text = @AlreadyMsg OUTPUT;
        SELECT 0 AS IsValid, ISNULL(@AlreadyMsg, 'This code has already been verified.') AS Message;
        -- We still return product info for already used codes in some flows, but usually verified = 0
        -- RETURN; -- Or continue to show info
    END

    -- 4. Get Product and Company Info (Join with LandingPage for images)
    DECLARE @SuccessMsg NVARCHAR(MAX);
    EXEC [USP_ManageCodeCheckMessages_AI] @Action = 'GetMessage', @Comp_Id = @ActualCompId, @Service_Id = @Service_Id, @Message_Type = 'Success', @Message_Text = @SuccessMsg OUTPUT;

    SELECT TOP 1
        P.Pro_Name AS ProductName,
        C.Comp_Name AS CompanyName,
        C.Comp_ID AS CompId,
        P.Pro_ID AS ProId,
        ISNULL(LP.ProductImage1, '') AS ProductImage,
        ISNULL(@SuccessMsg, 'Product successfully identified.') AS Message,
        1 AS IsValid
    FROM Pro_Reg P
    INNER JOIN Comp_Reg C ON P.Comp_ID = C.Comp_ID
    INNER JOIN M_ServiceSubscription ASG ON P.Pro_ID = ASG.Pro_ID
    LEFT JOIN LandingPage LP ON LP.Comp_Id = C.Comp_ID AND LP.Service_Id = ASG.Service_ID
    WHERE P.Pro_ID = @Pro_ID AND ASG.IsActive = 1 AND ISNULL(ASG.IsDelete, 0) = 0;

    -- 5. Get Assigned Services
    SELECT 
        S.Service_ID,
        S.ServiceName,
        ASG.IsActive
    FROM M_Service S
    INNER JOIN M_ServiceSubscription ASG ON S.Service_ID = ASG.Service_ID
    WHERE ASG.Pro_ID = @Pro_ID AND ASG.IsActive = 1 AND ISNULL(ASG.IsDelete, 0) = 0;
END
GO
