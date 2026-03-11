SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeGenerationReport]
AS
BEGIN
    SET NOCOUNT ON;

    -- High-performance count query with parallel execution hint
    SELECT 
        SUM(CASE WHEN ISNULL(Use_Count,0) = 0 THEN 1 ELSE 0 END) AS FreshCode,
        SUM(CASE WHEN Use_Count > 0 THEN 1 ELSE 0 END) AS UseCode,
        SUM(CASE WHEN Print_Date IS NOT NULL THEN 1 ELSE 0 END) AS PrintCode,
        SUM(CASE WHEN Pro_ID IS NULL THEN 1 ELSE 0 END) AS SoftCode,
        SUM(CASE WHEN Pro_ID IS NOT NULL AND ISNULL(Use_Count,0)=0 THEN 1 ELSE 0 END) AS UnusedCode
    FROM [dbo].[M_Code] WITH (NOLOCK)
    OPTION (MAXDOP 0); -- Allow full parallelism
END
GO
