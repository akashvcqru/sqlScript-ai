-- =============================================
-- Procedure: USP_GetServiceSettingList_AI
-- Description: Fetch list of service settings for a vendor with search by Pro_ID, Product Name, Series / Serial No
-- =============================================
CREATE OR ALTER PROCEDURE USP_GetServiceSettingList_AI
    @Comp_ID          NVARCHAR(50),
    @Pro_ID           NVARCHAR(50) = NULL,
    @Service_ID       NVARCHAR(10) = NULL,
    @Pro_Name         NVARCHAR(100) = NULL,
    @SeriesSerialNo   NVARCHAR(100) = NULL,
    @Search           NVARCHAR(100) = NULL,
    @PageIndex        INT = 1,
    @PageSize         INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SET @Comp_ID = LTRIM(RTRIM(@Comp_ID));
    SET @Pro_ID = NULLIF(LTRIM(RTRIM(@Pro_ID)), '');
    SET @Service_ID = NULLIF(LTRIM(RTRIM(@Service_ID)), '');
    SET @Pro_Name = NULLIF(LTRIM(RTRIM(@Pro_Name)), '');
    SET @SeriesSerialNo = NULLIF(LTRIM(RTRIM(@SeriesSerialNo)), '');
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');

    SELECT SST.SST_Id, 
           SST.Subscribe_Id, 
           SS.Pro_ID,
           SS.Service_ID,
           P.Pro_Name, 
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
           SST.Comments, 
           SST.IsActive, 
           CASE WHEN SST.IsActive = 1 THEN 'Activated' ELSE 'De-Activated' END AS StatusText, 
           SST.IsDelete, 
           ISNULL(CT.Batch_No, TP.Batch_No) AS Batch_No,
           ISNULL(SS.PlanName, '') AS PlanName,
           ISNULL(CAST(SS.PlanMasterPeriod AS VARCHAR(50)), '') AS PlanMasterPeriod,
           COUNT(*) OVER() as TotalRecords
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
      AND (@Pro_Name IS NULL OR P.Pro_Name LIKE '%' + @Pro_Name + '%')
      AND (
          @SeriesSerialNo IS NULL 
          OR CAST(SS.start_order AS VARCHAR) LIKE '%' + @SeriesSerialNo + '%'
          OR CAST(SS.start_series AS VARCHAR) LIKE '%' + @SeriesSerialNo + '%'
          OR CAST(SS.end_order AS VARCHAR) LIKE '%' + @SeriesSerialNo + '%'
          OR CAST(SS.end_series AS VARCHAR) LIKE '%' + @SeriesSerialNo + '%'
          OR (CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR)) LIKE '%' + @SeriesSerialNo + '%'
          OR (CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR)) LIKE '%' + @SeriesSerialNo + '%'
          OR (CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR) + ' to ' + CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR)) LIKE '%' + @SeriesSerialNo + '%'
          OR CT.SeriesStart LIKE '%' + @SeriesSerialNo + '%'
          OR CT.SeriesEnd LIKE '%' + @SeriesSerialNo + '%'
      )
      AND (
          @Search IS NULL
          OR SS.Pro_ID LIKE '%' + @Search + '%'
          OR P.Pro_Name LIKE '%' + @Search + '%'
          OR S.ServiceName LIKE '%' + @Search + '%'
          OR ISNULL(CT.Batch_No, TP.Batch_No) LIKE '%' + @Search + '%'
          OR CAST(SS.start_order AS VARCHAR) LIKE '%' + @Search + '%'
          OR CAST(SS.start_series AS VARCHAR) LIKE '%' + @Search + '%'
          OR CAST(SS.end_order AS VARCHAR) LIKE '%' + @Search + '%'
          OR CAST(SS.end_series AS VARCHAR) LIKE '%' + @Search + '%'
          OR (CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR)) LIKE '%' + @Search + '%'
          OR (CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR)) LIKE '%' + @Search + '%'
          OR (CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR) + ' to ' + CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR)) LIKE '%' + @Search + '%'
          OR CT.SeriesStart LIKE '%' + @Search + '%'
          OR CT.SeriesEnd LIKE '%' + @Search + '%'
      )
    ORDER BY SST.Entry_Date DESC, SST.SST_Id DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
