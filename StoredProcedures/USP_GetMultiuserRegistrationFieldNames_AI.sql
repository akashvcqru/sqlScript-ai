USE [VCQRU]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Get active multiuser registration field names
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetMultiuserRegistrationFieldNames_AI]
AS
BEGIN
	SET NOCOUNT ON;

    SELECT 
        FieldId,
        FieldName
    FROM 
        [dbo].[M_MultiuserRegistrationFieldNames] (NOLOCK)
    WHERE 
        IsActive = 1
    ORDER BY 
        FieldName ASC;
END
GO
