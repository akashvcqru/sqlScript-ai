DECLARE @datePreset NVARCHAR(20) = 'YEAR';
DECLARE @StartDate DATETIME;
DECLARE @EndDate DATETIME;

SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));

SELECT 'YEAR' AS Preset, @StartDate AS StartDate, @EndDate AS EndDate;

SET @datePreset = 'LASTYEAR';
SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);

SELECT 'LASTYEAR' AS Preset, @StartDate AS StartDate, @EndDate AS EndDate;
