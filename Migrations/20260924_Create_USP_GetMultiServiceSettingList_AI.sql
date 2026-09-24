-- =============================================
-- Migration: 20260924_Create_USP_GetMultiServiceSettingList_AI.sql
-- Description: Create USP_GetMultiServiceSettingList_AI procedure for multi-service list
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetMultiServiceSettingList_AI]
    @Comp_ID          NVARCHAR(50),
    @PageNumber       INT = 1,
    @PageSize         INT = 10,
    @Search           NVARCHAR(100) = NULL,
    @Pro_ID           NVARCHAR(50) = NULL,
    @Service_ID       NVARCHAR(50) = NULL,
    @IsActive         INT = NULL,
    @DateFrom         DATETIME = NULL,
    @DateTo           DATETIME = NULL,
    @IsExport         BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SET @Comp_ID = LTRIM(RTRIM(@Comp_ID));
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');
    SET @Pro_ID = NULLIF(LTRIM(RTRIM(@Pro_ID)), '');
    SET @Service_ID = NULLIF(LTRIM(RTRIM(@Service_ID)), '');

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;

    -- CTE to gather all matching rows
    ;WITH BaseSettings AS (
        SELECT 
            SST.SST_Id,
            SST.Subscribe_Id,
            SS.Comp_ID,
            SS.Pro_ID,
            P.Pro_Name,
            SS.Service_ID,
            S.ServiceName,
            CASE WHEN SS.start_order IS NOT NULL AND SS.start_series IS NOT NULL 
                 THEN CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR) + ' to ' + CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR) 
                 ELSE 'All' END AS servicerange,
            ISNULL(SST.DateFrom, SS.DateFrom) AS DateFrom,
            ISNULL(SST.DateTo, SS.DateTo) AS DateTo,
            SST.Points,
            SST.IsCashConvert,
            SST.IsCash,
            SST.Frequency,
            SST.AmtType,
            SST.totalamont AS TotalLoyalty,
            SST.Minval,
            SST.Maxval,
            SST.Comments,
            SST.IsActive,
            CASE WHEN SST.IsActive = 1 THEN 'Activated' ELSE 'De-Activated' END AS StatusText,
            SST.IsDelete,
            ISNULL(CT.Batch_No, TP.Batch_No) AS Batch_No,
            TP.MRP,
            TP.Mfd_Date,
            TP.Exp_Date,
            CT.Dealer_Name,
            CT.Dealer_Location,
            CT.Mobile AS Dealer_Mobile,
            CT.Email AS Dealer_Email,
            CT.Invoice_Number,
            COALESCE(SST.Entry_Date, SS.EntryDate) AS EntryDate
        FROM M_ServiceSubscriptionTrans SST WITH (NOLOCK)
        INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        INNER JOIN Pro_Reg P WITH (NOLOCK) ON SS.Pro_ID = P.Pro_ID
        INNER JOIN M_Service S WITH (NOLOCK) ON SS.Service_ID = S.Service_ID
        LEFT JOIN codeassign_tractrac CT WITH (NOLOCK) ON SST.SST_Id = CT.SST_Id
        LEFT JOIN T_Pro TP WITH (NOLOCK) ON SS.Pro_ID = TP.Pro_ID 
             AND (TP.Comments = SST.Comments OR (TP.Entry_Date >= DATEADD(SECOND, -10, SST.Entry_Date) AND TP.Entry_Date <= DATEADD(SECOND, 10, SST.Entry_Date)))
        WHERE SS.Comp_ID = @Comp_ID
          AND (SST.IsDelete = 0 OR SST.IsDelete IS NULL)
          AND (@Pro_ID IS NULL OR SS.Pro_ID = @Pro_ID OR SS.Pro_ID LIKE '%' + @Pro_ID + '%')
          AND (@Service_ID IS NULL OR SS.Service_ID = @Service_ID)
          AND (@IsActive IS NULL OR SST.IsActive = @IsActive)
          AND (@DateFrom IS NULL OR SST.DateFrom >= @DateFrom OR SST.Entry_Date >= @DateFrom)
          AND (@DateTo IS NULL OR SST.DateTo <= @DateTo OR SST.Entry_Date <= @DateTo)
          AND (
              @Search IS NULL
              OR P.Pro_Name LIKE '%' + @Search + '%'
              OR P.Pro_ID LIKE '%' + @Search + '%'
              OR S.ServiceName LIKE '%' + @Search + '%'
              OR SS.Service_ID LIKE '%' + @Search + '%'
              OR ISNULL(CT.Batch_No, TP.Batch_No) LIKE '%' + @Search + '%'
              OR CT.Dealer_Name LIKE '%' + @Search + '%'
          )
    )
    SELECT *, COUNT(*) OVER() AS TotalRecords
    FROM BaseSettings
    ORDER BY EntryDate DESC, SST_Id DESC;
END
GO
