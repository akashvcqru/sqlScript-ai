-- One-time backfill script to populate ConsumerPointsCashDetails from Tbl_M_Star_CodeVerification
DECLARE @CompId NVARCHAR(50) = 'Comp-1152';

-- 1. Setup temp tables
DROP TABLE IF EXISTS #missing_codes;
DROP TABLE IF EXISTS #temp1;
DROP TABLE IF EXISTS #pe_ranked;
DROP TABLE IF EXISTS #m_consumer_lookup;

-- 2. Extract missing verifications into a temp table with clustered index
SELECT 
    SUBSTRING(CAST(CAST(v.completecode AS bigint) AS varchar(20)), 1, 5) AS Code1,
    SUBSTRING(CAST(CAST(v.completecode AS bigint) AS varchar(20)), 6, 8) AS Code2,
    v.completecode,
    v.Mobile_Number,
    v.enquiry_date,
    v.amount_won,
    v.mode_of_verification
INTO #missing_codes
FROM Tbl_M_Star_CodeVerification v
WHERE v.Comp_Id = @CompId
  AND NOT EXISTS (
      SELECT 1 
      FROM ConsumerPointsCashDetails c
      WHERE c.Code1 = SUBSTRING(CAST(CAST(v.completecode AS bigint) AS varchar(20)), 1, 5)
        AND c.Code2 = SUBSTRING(CAST(CAST(v.completecode AS bigint) AS varchar(20)), 6, 8)
        AND c.Comp_id = @CompId
  );

CREATE CLUSTERED INDEX IX_missing_codes ON #missing_codes (Code1, Code2);

-- 3. Get active service subscription details for Comp-1152 (all services including SRV1018)
;WITH cte AS
(
    SELECT  sst.SST_Id, sst.Points,  sst.IsCash,  ss.Pro_ID,  ss.start_order,  ss.start_series, ss.end_order, ss.end_series,  sst.IsActive, ss.Service_ID,
        ROW_NUMBER() OVER (
            PARTITION BY 
                ss.start_order,  ss.start_series, ss.end_order, ss.end_series, ss.Pro_ID
            ORDER BY 
                CASE WHEN ss.Service_ID = 'SRV1005' THEN 0 ELSE 1 END,
                sst.Entry_Date DESC
        ) AS rn
    FROM M_ServiceSubscriptionTrans sst
    INNER JOIN M_ServiceSubscription ss ON sst.Subscribe_Id = ss.Subscribe_Id
    INNER JOIN Pro_reg pr ON pr.Pro_id = ss.Pro_ID 
    INNER JOIN Comp_reg cr ON cr.Comp_ID = pr.Comp_ID
    WHERE pr.Comp_ID = @CompId
)
SELECT SST_Id, Points, IsCash, Pro_ID, start_order, start_series, end_order, end_series, IsActive, Service_ID
INTO #temp1 FROM cte WHERE rn = 1;

-- 4. Get ranked Pro_Enq scans matching only the missing codes
;WITH RankedPE AS (
    SELECT 
        pe.Row_ID AS PE_ID,
        pe.Dial_Mode,
        pe.Received_Code1,
        pe.Received_Code2,
        pe.MobileNo,
        pe.Latitude,
        pe.Longitude,
        ROW_NUMBER() OVER (
            PARTITION BY pe.Received_Code1, pe.Received_Code2
            ORDER BY CASE WHEN pe.Is_Success = 1 THEN 0 ELSE 1 END, pe.Enq_Date ASC
        ) AS rn
    FROM Pro_Enq pe
    INNER JOIN #missing_codes m ON pe.Received_Code1 = m.Code1 AND pe.Received_Code2 = m.Code2
)
SELECT PE_ID, Dial_Mode, Received_Code1, Received_Code2, MobileNo, Latitude, Longitude
INTO #pe_ranked
FROM RankedPE
WHERE rn = 1;

CREATE CLUSTERED INDEX IX_pe_ranked ON #pe_ranked (Received_Code1, Received_Code2);

-- 5. Get active consumer lookup with employee and distributor IDs
SELECT M_Consumerid, MobileLast10, MobileNo, employeeID, distributorID
INTO #m_consumer_lookup
FROM M_Consumer
WHERE IsDelete = 0;

CREATE CLUSTERED INDEX IX_m_consumer_lookup ON #m_consumer_lookup (MobileLast10);

-- 6. Insert missing records in a single transaction
BEGIN TRANSACTION;

INSERT INTO dbo.ConsumerPointsCashDetails 
(
    MobileNo,
    M_ConsumerId,
    Code1,
    Code2,
    Enq_Date,
    SST_Id,
    Points,
    Cash,
    expireCodeAmount,
    Pro_id,
    Comp_id,
    Pro_Name,
    Is_Success,
    Service_ID,
    Latitude,
    Longitude,
    Dial_Mode,
    PE_ID,
    employeedid,
    distributedid
)
SELECT  
    LEFT(CAST(CAST(v.Mobile_Number AS bigint) AS varchar(20)), 12) AS MobileNo,
    mcc.M_Consumerid,
    v.Code1,
    v.Code2,
    v.enquiry_date AS Enq_Date,
    sd.SST_Id,
    0 AS Points,
    CAST(v.amount_won AS int) AS Cash,
    0.00 AS expireCodeAmount,
    mc.Pro_id,
    @CompId AS Comp_id,
    pr.Pro_Name,
    '1' AS Is_Success,
    'SRV1005' AS Service_ID,
    pe.Latitude,
    pe.Longitude,
    COALESCE(pe.Dial_Mode, v.mode_of_verification, 'WebSite') AS Dial_Mode,
    pe.PE_ID,
    mcc.employeeID AS employeedid,
    mcc.distributorID AS distributedid
FROM #missing_codes v
INNER JOIN M_Code mc ON mc.Code1 = TRY_CAST(v.Code1 AS NUMERIC(18,0)) AND mc.Code2 = TRY_CAST(v.Code2 AS NUMERIC(18,0))
INNER JOIN Pro_Reg pr ON pr.Pro_id = mc.Pro_ID
LEFT JOIN #temp1 sd ON sd.Pro_ID = mc.Pro_id 
                   AND (sd.start_order IS NULL OR (mc.Series_Order * 10000 + mc.Series_Serial) BETWEEN (sd.start_order * 10000 + sd.start_series) AND (sd.end_order * 10000 + sd.end_series))
LEFT JOIN #m_consumer_lookup mcc ON mcc.MobileLast10 = RIGHT(CAST(CAST(v.Mobile_Number AS bigint) AS varchar(20)), 10)
LEFT JOIN #pe_ranked pe ON pe.Received_Code1 = v.Code1 AND pe.Received_Code2 = v.Code2;

COMMIT TRANSACTION;

-- Clean up
DROP TABLE IF EXISTS #missing_codes;
DROP TABLE IF EXISTS #temp1;
DROP TABLE IF EXISTS #pe_ranked;
DROP TABLE IF EXISTS #m_consumer_lookup;
