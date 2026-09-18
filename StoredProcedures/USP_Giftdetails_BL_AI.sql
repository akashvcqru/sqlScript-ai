USE [Vcqru]
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'USP_Giftdetails_BL_AI')
    DROP PROCEDURE [dbo].[USP_Giftdetails_BL_AI]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[USP_Giftdetails_BL_AI]
    @Comp_id VARCHAR(20)
AS
BEGIN
    -- Validate input parameter
    IF @Comp_id IS NULL OR @Comp_id = ''
    BEGIN
        RAISERROR('Company ID cannot be null or empty.', 16, 1);
        RETURN;
    END

    -- Fetch gift details with improved readability
    SELECT
        a.gift_id,
        a.Gift_name,
        a.Gift_value,
        a.Gift_desc,
        a.Gift_image,
        a.status,
        a.CompID,
        a.Gift_point,
        -- Trim any trailing comma from the gift_images
        CASE 
            WHEN b.gift_images LIKE '%,%' THEN RTRIM(LTRIM(LEFT(b.gift_images, LEN(b.gift_images) - 1)))
            ELSE b.gift_images
        END AS gift_images
    FROM 
        Claim_gift AS a
    LEFT JOIN 
        gifttable_images AS b 
        ON a.gift_id = b.gift_id
    WHERE 
        a.CompID = @Comp_id
        AND a.status = 1
        AND (a.Isdelete IS NULL OR a.Isdelete = 0)
    ORDER BY 
        a.Gift_value ASC;
END
GO
