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
        CAT.Mobile,
        CAT.Email,
        CAT.Dispatch_Date,
        CAT.Invoice_Number,
        TRY_CAST(PARSENAME(REPLACE(CAT.SeriesStart, '-', '.'), 2) AS BIGINT) AS Series_Order,
        TRY_CAST(PARSENAME(REPLACE(CAT.SeriesStart, '-', '.'), 1) AS BIGINT) AS Start_Serial,
        TRY_CAST(PARSENAME(REPLACE(CAT.SeriesEnd, '-', '.'), 1) AS BIGINT) AS End_Serial,

        JSON_QUERY(
            (
                SELECT DISTINCT
                    CAST(MC.Code1 AS VARCHAR(20)) + '-' + CAST(MC.Code2 AS VARCHAR(20)) AS Code,
                    MC.Series_Order AS series_Order,
                    MC.Series_Serial AS series_Serial
                FROM m_code MC
                WHERE 
                    MC.Pro_ID = CAT.Pro_ID

                    -- Robust parsing of Order and Serial (supports both Prefix-Order-Serial and Order-Serial)
                    AND MC.Series_Order = TRY_CAST(PARSENAME(REPLACE(CAT.SeriesStart, '-', '.'), 2) AS BIGINT)

                    -- Series_Serial RANGE
                    AND MC.Series_Serial BETWEEN 
                        TRY_CAST(PARSENAME(REPLACE(CAT.SeriesStart, '-', '.'), 1) AS BIGINT)
                        AND
                        TRY_CAST(PARSENAME(REPLACE(CAT.SeriesEnd, '-', '.'), 1) AS BIGINT)

                FOR JSON PATH
            )
        ) AS AssignedCodes

    FROM codeassign_tractrac CAT
    ORDER BY CAT.entry_date DESC;
END
GO
