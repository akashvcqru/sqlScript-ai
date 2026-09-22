SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-09-22
-- Description: Get Consumer User details by Mobile Number for Mahindra & Mahindra
-- =============================================
-- EXEC [dbo].[USP_BL_GetUserByNumber_MAndM_AI] @Comp_Id = 'Comp-1152', @MobileNo = '9522111376'
CREATE OR ALTER PROCEDURE [dbo].[USP_BL_GetUserByNumber_MAndM_AI]
    @Comp_Id    VARCHAR(50),
    @MobileNo   VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActualCompId VARCHAR(50) = ISNULL(@Comp_Id, 'Comp-1152');
    IF (@ActualCompId = 'Comp-2345' OR @ActualCompId = '')
    BEGIN
        SET @ActualCompId = 'Comp-1152';
    END

    SELECT
        CAST(mc.M_Consumerid AS VARCHAR(50)) AS M_Consumerid,
        mc.MobileNo,
        mc.ConsumerName,
        mc.distributorID AS DealerCode,
        mc.employeeID AS DealerTechnicianId,
        CAST(mc.IsActive AS INT) AS IsActive,
        mc.Entry_Date
    FROM M_Consumer mc WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus TV WITH (NOLOCK)
        ON TV.M_ConsumerId = mc.M_Consumerid
    WHERE RIGHT(mc.MobileNo, 10) = RIGHT(LTRIM(RTRIM(@MobileNo)), 10)
      AND TV.Comp_id = @ActualCompId;
END
GO
