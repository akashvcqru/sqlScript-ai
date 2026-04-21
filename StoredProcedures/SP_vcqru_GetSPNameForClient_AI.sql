USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_vcqru_GetSPNameForClient_AI]
    @Comp_Id VARCHAR(50),
    @APIName Varchar(200)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 SP_Name
    FROM Tbl_ClientSPMapping
    WHERE Comp_Id = @Comp_Id AND APIName = @APIName
      AND IsActive = 1;
END;
GO
