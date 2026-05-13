USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec [dbo].[USP_GetPendingGeoLocationRecordsBackfill_AI]
CREATE OR ALTER PROCEDURE [dbo].[USP_GetPendingGeoLocationRecordsBackfill_AI]
AS
BEGIN
    SET NOCOUNT ON;

    -- Fetch a safe chunk of 1000 unpopulated records to avoid server/API timeouts
    SELECT TOP (1000)
        p.MobileNo,
        p.Latitude,
        p.Longitude,
        p.Comp_Id,
        p.Received_Code1,
        p.Received_Code2,
        p.Enq_Date
    FROM Pro_Enq p WITH (NOLOCK)
    WHERE p.Latitude IS NOT NULL AND LEN(p.Latitude) > 4
      AND p.Longitude IS NOT NULL AND LEN(p.Longitude) > 4
      AND NOT EXISTS (
          SELECT 1 FROM GeoLocationData G WITH (NOLOCK)
          WHERE G.Comp_Id  = p.Comp_Id
            AND G.MobileNo = p.MobileNo
            AND G.Code1 = p.Received_Code1
            AND G.Code2 = p.Received_Code2
            AND G.Latitude = p.Latitude
            AND G.Longitude = p.Longitude
      )
    ORDER BY p.Enq_Date DESC; -- Process the unpopulated backfill records batch-by-batch
END
GO
