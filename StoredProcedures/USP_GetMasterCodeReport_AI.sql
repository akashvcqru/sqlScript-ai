CREATE OR ALTER PROCEDURE [dbo].[USP_GetMasterCodeReport_AI]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CAT.mastercode AS MasterCode,
        CAT.Pro_ID,
        CAT.MRP,
        CAT.Mfd_Date,
        CAT.Exp_Date,
        CAT.Batch_No,
        CAT.SeriesStart,
        CAT.SeriesEnd,
        CAT.entry_date AS EntryDate,
        CAT.Dealer_Name,
        CAT.Dealer_Location,
        CAT.Contact_Information,
        CAT.Dispatch_Date,
        CAT.Invoice_Number,

        JSON_QUERY(
            (
                SELECT DISTINCT
                    CAST(MC.Code1 AS VARCHAR(20)) + '-' + CAST(MC.Code2 AS VARCHAR(20)) AS Code,
                    MC.Series_Order AS series_Order,
                    MC.Series_Serial AS series_Serial
                FROM m_code MC
                WHERE 
                    MC.Pro_ID = CAT.Pro_ID

                    -- SAFE Series_Order
                    AND MC.Series_Order = 
                    CASE 
                        WHEN CHARINDEX('-', CAT.SeriesStart) > 0 
                        THEN TRY_CAST(LEFT(CAT.SeriesStart, CHARINDEX('-', CAT.SeriesStart) - 1) AS BIGINT)
                        ELSE NULL
                    END

                    -- SAFE Series_Serial RANGE
                    AND MC.Series_Serial BETWEEN 
                    CASE 
                        WHEN CHARINDEX('-', CAT.SeriesStart) > 0 
                        THEN TRY_CAST(SUBSTRING(CAT.SeriesStart, CHARINDEX('-', CAT.SeriesStart) + 1, LEN(CAT.SeriesStart)) AS BIGINT)
                        ELSE NULL
                    END
                    AND
                    CASE 
                        WHEN CHARINDEX('-', CAT.SeriesEnd) > 0 
                        THEN TRY_CAST(SUBSTRING(CAT.SeriesEnd, CHARINDEX('-', CAT.SeriesEnd) + 1, LEN(CAT.SeriesEnd)) AS BIGINT)
                        ELSE NULL
                    END

                FOR JSON PATH
            )
        ) AS AssignedCodes

    FROM codeassign_tractrac CAT
    ORDER BY CAT.entry_date DESC;
END
GO
