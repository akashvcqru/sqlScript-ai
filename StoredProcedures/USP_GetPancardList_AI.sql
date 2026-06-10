-- USP_GetPancardList_AI
-- Fetch all pancard details for consumers under a given company where pancard is not null/empty
CREATE PROCEDURE USP_GetPancardList_AI
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SELECT 
        mc.M_Consumerid,
        mc.MobileNo,
        mc.pancard_number
    FROM M_Consumer mc WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus tvk WITH (NOLOCK)
        ON mc.M_Consumerid = tvk.M_consumerId
    WHERE tvk.Comp_id = @Comp_ID
      AND ISNULL(mc.pancard_number, '') <> '';
END
GO
