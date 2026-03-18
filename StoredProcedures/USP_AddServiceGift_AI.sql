-- =============================================
-- Procedure: USP_AddServiceGift_AI
-- Description: Insert gift transaction details for a service setting
-- =============================================
IF OBJECT_ID('USP_AddServiceGift_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_AddServiceGift_AI
GO

CREATE PROCEDURE USP_AddServiceGift_AI
    @SST_Id            BIGINT,
    @Gift_ID          BIGINT,
    @GiftCount        NUMERIC(18, 0),
    @LuckyNoCount     NUMERIC(18, 0) = 0
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO M_ServiceGiftTrans (SST_Id, Gift_ID, GiftCount, LuckyNoCount)
    VALUES (@SST_Id, @Gift_ID, @GiftCount, @LuckyNoCount);
END
GO
