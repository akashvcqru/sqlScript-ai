-- Restore missing scans from Backup_03_06_2026 to ConsumerPointsCashDetails for Comp-1152
DECLARE @CompId NVARCHAR(50) = 'Comp-1152';

INSERT INTO dbo.ConsumerPointsCashDetails (
    MobileNo, M_ConsumerId, Code1, Code2, Enq_Date, SST_Id, Points, Cash, expireCodeAmount,
    Pro_id, Comp_id, Pro_Name, Is_Success, Service_ID, Latitude, Longitude, Dial_Mode,
    PE_ID, employeedid, distributedid
)
SELECT 
    b.MobileNo, b.M_ConsumerId, b.Code1, b.Code2, b.Enq_Date, b.SST_Id, b.Points, b.Cash, b.expireCodeAmount,
    b.Pro_id, b.Comp_id, b.Pro_Name, b.Is_Success, b.Service_ID, b.Latitude, b.Longitude, b.Dial_Mode,
    b.PE_ID, b.employeedid, b.distributedid
FROM dbo.ConsumerPointsCashDetails_03_06_2026 b WITH (NOLOCK)
WHERE b.Comp_id = @CompId
  AND NOT EXISTS (
      SELECT 1 
      FROM dbo.ConsumerPointsCashDetails c WITH (NOLOCK)
      WHERE c.Comp_id = @CompId
        AND c.Code1 = b.Code1
        AND c.Code2 = b.Code2
        AND c.MobileNo = b.MobileNo
  );
