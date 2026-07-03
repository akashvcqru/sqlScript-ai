SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GetAlertNews_AI]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        [ID],
        [Case_ID],
        [Case_Date],
        [Year],
        [Month],
        [Country],
        [State],
        [City],
        [Pincode],
        [Brand_Name],
        [Product_Name],
        [Industry],
        [Counterfeit_Type],
        [Case_Type],
        [Estimated_Value],
        [Authority],
        [Arrest_Made],
        [Risk_Level],
        [Consumer_Health_Risk],
        [Suggested_VCQRU_Solution],
        [Verification_Status],
        [Verification_Notes],
        [Source_Link],
        [Latitude],
        [Longitude],
        [Entry_Date],
        [Updated_Date],
        [Act_Flag]
    FROM [dbo].[tbl_AlertNews] WITH (NOLOCK)
    WHERE [Act_Flag] = 1
    ORDER BY [Case_Date] DESC, [ID] DESC;
END
GO
