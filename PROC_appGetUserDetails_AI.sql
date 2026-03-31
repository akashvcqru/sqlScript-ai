USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[PROC_appGetUserDetails_AI] 	
   @User_ID nvarchar(50)    
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CleanUserID nvarchar(10) = right(@User_ID, 10);
    SELECT top 1 mc.*, replace(pr.[Profile_img], '"', '') [Profile_img] 
    FROM [M_Consumer] mc 
    LEFT JOIN [Profile_images] pr on pr.m_consumerid = mc.m_consumerid 
    WHERE [MobileNo] like '%' + @CleanUserID and IsDelete = 0 
    ORDER BY entry_Date desc;
END
