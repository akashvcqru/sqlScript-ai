USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_UpdatePanOperativeInOperative_AI]
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
    -- Verify Consumer belongs to Company in tbl_Vendorvisekycstatus or M_Consumer
    ------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 
        FROM M_Consumer mc WITH (NOLOCK)
        WHERE mc.M_Consumerid = @m_consumerid 
          AND mc.IsDelete = 0
          AND (
              mc.Comp_id = @Comp_Id 
              OR EXISTS (
                  SELECT 1 
                  FROM tbl_Vendorvisekycstatus tvk WITH (NOLOCK)
                  WHERE tvk.M_consumerId = mc.M_Consumerid 
                    AND tvk.Comp_id = @Comp_Id
              )
          )
    )
    BEGIN
        SELECT 'Consumer not found or does not belong to this company' AS Message, 0 AS Success;
        RETURN;
    END;

    ------------------------------------------------------
    -- Execute Update
    ------------------------------------------------------
    BEGIN TRY
        UPDATE M_Consumer 
        SET IspanOperative = @IspanOperative
        WHERE M_Consumerid = @m_consumerid 
          AND IsDelete = 0;

        SELECT 'PAN status updated successfully' AS Message, 1 AS Success;
    END TRY
    BEGIN CATCH
        SELECT 'Error updating PAN status: ' + ERROR_MESSAGE() AS Message, 0 AS Success;
    END CATCH;
END
GO

