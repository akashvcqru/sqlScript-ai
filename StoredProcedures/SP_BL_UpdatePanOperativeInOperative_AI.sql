USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_BL_UpdatePanOperativeInOperative_AI]
    @Comp_Id        VARCHAR(15),
    @IspanOperative BIT,
    @m_consumerid   INT
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------
    -- Validate parameters
    ------------------------------------------------------
    IF (@Comp_Id IS NULL OR @Comp_Id = '' OR @m_consumerid IS NULL OR @m_consumerid <= 0)
    BEGIN
        SELECT 'Missing required parameters' AS Message, 0 AS Success;
        RETURN;
    END;

    ------------------------------------------------------
    -- Execute Update
    ------------------------------------------------------
    BEGIN TRY
        UPDATE M_Consumer 
        SET IspanOperative = @IspanOperative
        WHERE Comp_id = @Comp_Id 
          AND M_Consumerid = @m_consumerid AND IsDelete = 0;

        SELECT 'PAN status updated successfully' AS Message, 1 AS Success;
    END TRY
    BEGIN CATCH
        SELECT 'Error updating PAN status: ' + ERROR_MESSAGE() AS Message, 0 AS Success;
    END CATCH;
END
GO
