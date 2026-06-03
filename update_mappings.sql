USE [Vcqru]
GO

-- 1. GetLoyaltyHeatmapByState -> Proc_GetStateWiseSummary_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'Proc_GetStateWiseSummary_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetLoyaltyHeatmapByState';

-- 2. GetCashBurnDetailsReport -> SP_BL_CashBurnDetailsReport_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_CashBurnDetailsReport_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetCashBurnDetailsReport';

-- 3. GetBeneficiariesReport -> SP_BL_GetBeneficiariesReport_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetBeneficiariesReport_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetBeneficiariesReport';

-- 4. GetBLBrandOverview -> SP_BL_GetBrandOverview_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetBrandOverview_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetBLBrandOverview';

-- 5. GetCashBurnPattern -> SP_BL_GetCashBurnPattern_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetCashBurnPattern_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetCashBurnPattern';

-- 6. GetCodesActivityReport -> SP_BL_GetCodesActivityReport_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetCodesActivityReport_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetCodesActivityReport';

-- 7. GetKYCOverview -> SP_BL_GetNewUsersAndKYCOverview_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetNewUsersAndKYCOverview_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetKYCOverview';

-- 8. GetNewUsersAndKYCReport -> SP_BL_GetNewUsersAndKYCReportAutoFilterData_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetNewUsersAndKYCReportAutoFilterData_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetNewUsersAndKYCReport';

-- 9. GetPeakActivityHours -> SP_BL_GetScanPeakActivityHour_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetScanPeakActivityHour_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetPeakActivityHours';

-- 10. GetTopPerformingStates -> SP_BL_GetTopPerformingStates_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetTopPerformingStates_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetTopPerformingStates';

-- 11. GetLiveScanReport -> SP_BL_LiveScanActivity_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_LiveScanActivity_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetLiveScanReport';

-- 12. GetTopBeneficiariesList -> SP_BL_GetTopBeneficiariesList_MAndM_AI
UPDATE Tbl_ClientSPMapping 
SET SP_Name = 'SP_BL_GetTopBeneficiariesList_MAndM_AI' 
WHERE Comp_Id = 'Comp-1152' AND APIName = 'GetTopBeneficiariesList';
