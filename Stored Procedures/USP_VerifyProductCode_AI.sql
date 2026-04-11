SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:        AI Assistant
-- Create date:   2026-04-11
-- Description:   Modernized product code verification for landing pages
-- =============================================
CREATE PROCEDURE [dbo].[USP_VerifyProductCode_AI]
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
    SELECT @Pro_ID = Pro_ID, @Use_Count = ISNULL(Use_Count, 0)
    FROM ' + @TableName + '
    WHERE Code1 = @Code1 AND Code2 = @Code2
    AND (ScrapeFlag = 0 OR ScrapeFlag IS NULL)';

    EXEC sp_executesql @SQL, 
        N'@Code1 VARCHAR(10), @Code2 VARCHAR(10), @Pro_ID VARCHAR(50) OUTPUT, @Use_Count INT OUTPUT',
        @Code1, @Code2, @Pro_ID OUTPUT, @Use_Count OUTPUT;

    IF @Pro_ID IS NULL
    BEGIN
        SELECT 0 AS IsValid, 'Invalid or unscanned code.' AS Message;
        RETURN;
    END

    -- 3. Get Product and Company Info (Join with LandingPage for images)
    SELECT TOP 1
        P.Pro_Name AS ProductName,
        C.Comp_Name AS CompanyName,
        C.Comp_ID AS CompId,
        P.Pro_ID AS ProId,
        ISNULL(LP.ProductImage1, '') AS ProductImage
    FROM Pro_Reg P
    INNER JOIN Comp_Reg C ON P.Comp_ID = C.Comp_ID
    INNER JOIN M_ServiceSubscription ASG ON P.Pro_ID = ASG.Pro_ID
    LEFT JOIN LandingPage LP ON LP.Comp_Id = C.Comp_ID AND LP.Service_Id = ASG.Service_ID
    WHERE P.Pro_ID = @Pro_ID AND ASG.IsActive = 1 AND ISNULL(ASG.IsDelete, 0) = 0;

    -- 4. Get Assigned Services
    SELECT 
        S.Service_ID,
        S.ServiceName,
        ASG.IsActive
    FROM M_Service S
    INNER JOIN M_ServiceSubscription ASG ON S.Service_ID = ASG.Service_ID
    WHERE ASG.Pro_ID = @Pro_ID AND ASG.IsActive = 1 AND ISNULL(ASG.IsDelete, 0) = 0;

    -- 5. Record the inquiry (mimicking ServiceLogic.cs)
    -- TODO: Implement PROC_InsertProductInquery if needed
END
GO
