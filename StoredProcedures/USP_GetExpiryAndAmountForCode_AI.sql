USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-29
-- Description: Get subscription expiry date and amount/points for a code series
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetExpiryAndAmountForCode_AI]
    @ProID NVARCHAR(50),
    @CompID NVARCHAR(50),
    @SeriesOrder INT,
    @SeriesSerial INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 
        ss.Subscribe_Id, 
        ss.DateTo AS SubscriptionExpiry,
        sst.DateTo AS TransExpiry,
        sst.Points AS TransPoints,
        sst.IsCash AS TransCash
    FROM M_ServiceSubscription ss WITH (NOLOCK)
    LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id 
        AND sst.IsActive = 1 AND sst.IsDelete = 0
    WHERE ss.Pro_ID = @ProID 
      AND ss.Comp_ID = @CompID 
      AND ss.IsActive = 1 
      AND ss.IsDelete = 0
      AND (
        ss.start_order IS NULL 
        OR 
        (
          (@SeriesOrder > ss.start_order OR (@SeriesOrder = ss.start_order AND @SeriesSerial >= ISNULL(ss.start_series, 0)))
          AND
          (@SeriesOrder < ss.end_order OR (@SeriesOrder = ss.end_order AND @SeriesSerial <= ISNULL(ss.end_series, 999999)))
        )
      )
    ORDER BY 
        CASE WHEN ss.start_order IS NOT NULL THEN 1 ELSE 2 END ASC,
        sst.SST_Id DESC;
END
GO
