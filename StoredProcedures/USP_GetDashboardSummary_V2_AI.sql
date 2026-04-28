SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Description: Optimized dashboard summary for multi-user dashboard.
-- Returns ONLY basic scan counts and flag, skipping points/cash/service-wise data for speed.
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDashboardSummary_V2_AI]
(
    @M_Consumerid INT,
    @CompID VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MobileNo VARCHAR(20)
    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_Consumerid AND IsDelete = 0;

    IF @MobileNo IS NULL RETURN;

    -- Flag for service-wise gifts presence
    DECLARE @HasServiceWiseGifts BIT = 0;
    IF EXISTS (SELECT 1 FROM Claim_gift WHERE CompID = @CompID AND Service_id IS NOT NULL AND Isdelete = 0)
    BEGIN
        SET @HasServiceWiseGifts = 1;
    END

    -- Result Set 1: Overall Stats (Simplified)
    SELECT 
        (SELECT COUNT(pe.Received_Code1) 
         FROM Pro_Enq pe 
         WHERE pe.MobileNo = @MobileNo) as TotalCode,
        0 as ReedemPoints,
        (SELECT COUNT(pe.Received_Code1) 
         FROM Pro_Enq pe 
         WHERE pe.MobileNo = @MobileNo AND pe.Is_Success = 1) as SuccessCode,
        0 as TotalCash,
        0 as TotalPoints,
        @HasServiceWiseGifts as HasServiceWiseGifts;

    -- Result Set 2: Service-Wise Stats (Empty placeholders for speed)
    SELECT TOP 0
        ms.Service_ID,
        ms_name.ServiceName,
        0 as ServiceTotalPoints,
        0 as ServiceTotalCash
    FROM M_ServiceSubscription ms
    LEFT JOIN M_Service ms_name ON ms_name.Service_ID = ms.Service_ID
    WHERE 1=0;

    -- Result Set 3: Claim Amounts Service-Wise (Empty placeholders for speed)
    SELECT TOP 0 '' as Service_ID, 0 as ClaimAmount;
END
GO
