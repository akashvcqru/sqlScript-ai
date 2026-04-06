-- =============================================
-- Procedure: USP_GetServiceSettingTracTrashList_AI
-- Description: Fetch list of service settings for Track & Trace with master code details
-- =============================================
IF OBJECT_ID('USP_GetServiceSettingTracTrashList_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServiceSettingTracTrashList_AI
GO

CREATE PROCEDURE USP_GetServiceSettingTracTrashList_AI
    @Comp_ID       NVARCHAR(50),
    @PageIndex     INT = 1,
    @PageSize      INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        SST.SST_Id,
        SST.Subscribe_Id,
        SS.Pro_ID, 
        P.Pro_Name,
        S.ServiceName,
        SST.DateFrom,
        SST.DateTo,
        SST.Points,
        SST.IsCashConvert,
        SST.IsCash,
        SST.Frequency,
        SST.Comments,
        SST.IsActive,
        CASE 
            WHEN SST.IsActive = 0 THEN 'Activated' 
            ELSE 'De-Activated' 
        END AS StatusText,
        SST.IsDelete,
        CT.mastercode,
        CT.Batch_No,
        CT.Dealer_Name,
        CT.Dealer_Location,
        CT.Mobile,
        CT.Email,
        CT.Invoice_Number,
        CT.BatchSize,
        CT.SeriesStart,
        CT.SeriesEnd,
        CT.ID AS TrackTrace_ID,
        CT.ID AS ID,
        TRY_CAST(PARSENAME(REPLACE(CT.SeriesStart, '-', '.'), 2) AS BIGINT) AS Series_Order,
        TRY_CAST(PARSENAME(REPLACE(CT.SeriesStart, '-', '.'), 1) AS BIGINT) AS Start_Serial,
        TRY_CAST(PARSENAME(REPLACE(CT.SeriesEnd, '-', '.'), 1) AS BIGINT) AS End_Serial,
        TP.Row_ID AS tpro_id,
        COUNT(*) OVER() as TotalRecords
    FROM M_ServiceSubscriptionTrans SST
    INNER JOIN M_ServiceSubscription SS ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN Pro_Reg P ON SS.Pro_ID = P.Pro_ID
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    LEFT JOIN codeassign_tractrac CT ON SST.SST_Id = CT.SST_Id
    OUTER APPLY (
        SELECT TOP 1 m.Pro_ID, m.Batch_No
        FROM M_Code m
        WHERE m.Pro_ID = CT.Pro_ID 
          AND (
               -- Primary join: Use SeriesStart components (e.g., BM92-0000-0117)
               (m.Series_Order = TRY_CAST(PARSENAME(REPLACE(CT.SeriesStart, '-', '.'), 2) AS NUMERIC(10,0))
                AND m.Series_Serial = TRY_CAST(PARSENAME(REPLACE(CT.SeriesStart, '-', '.'), 1) AS NUMERIC(4,0)))
               OR
               -- Fallback join: Use mastercode with safe conversion
               (TRY_CAST(CT.mastercode AS NUMERIC(18,0)) IS NOT NULL AND 
                (m.Code1 = TRY_CAST(CT.mastercode AS NUMERIC(5,0)) OR m.Code2 = TRY_CAST(CT.mastercode AS NUMERIC(8,0))))
          )
    ) MC
    OUTER APPLY (
        SELECT TOP 1 Row_ID
        FROM T_Pro 
        WHERE Pro_ID = MC.Pro_ID 
          AND CAST(Row_ID AS VARCHAR(50)) = MC.Batch_No
    ) TP
    WHERE SS.Comp_ID = @Comp_ID
      AND SS.Service_ID = 'SRV1021'
    ORDER BY CT.entry_date DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
