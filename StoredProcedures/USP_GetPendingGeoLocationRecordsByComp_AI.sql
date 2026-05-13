USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec [dbo].[USP_GetPendingGeoLocationRecordsByComp_AI] 'Comp-1234'
CREATE OR ALTER PROCEDURE [dbo].[USP_GetPendingGeoLocationRecordsByComp_AI]
(
    @CompId VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LastEnqDate DATETIME;
    -- Get the last Enq_Date that was successfully geocoded for this company to narrow down the search incredibly fast
    SELECT @LastEnqDate = MAX(Enq_Date) FROM GeoLocationData WITH (NOLOCK) 
    WHERE Comp_Id = @CompId AND DisplayName IS NOT NULL AND DisplayName <> '';
    
    IF @LastEnqDate IS NULL SET @LastEnqDate = '1900-01-01';

    -- Buffer by 10 minutes to handle overlapping inserts or slight clock skews
    SET @LastEnqDate = DATEADD(MINUTE, -10, @LastEnqDate);

    SELECT 
        p.MobileNo,
        p.Latitude,
        p.Longitude,
        p.Comp_Id,
        p.Received_Code1,
        p.Received_Code2,
        p.Enq_Date
    FROM Pro_Enq p WITH (NOLOCK)
    WHERE p.Comp_Id = @CompId
      AND p.Enq_Date > @LastEnqDate
      AND p.Latitude IS NOT NULL AND p.Latitude <> ''
      AND p.Longitude IS NOT NULL AND p.Longitude <> ''
      AND NOT EXISTS (
          SELECT 1 FROM GeoLocationData G WITH (NOLOCK)
          WHERE G.Comp_Id  = p.Comp_Id
            AND G.MobileNo = p.MobileNo
            AND G.Code1 = p.Received_Code1
            AND G.Code2 = p.Received_Code2
            AND G.Latitude = p.Latitude
            AND G.Longitude = p.Longitude
      )
    ORDER BY p.Enq_Date ASC; -- Process oldest first
END
GO
