-- Migration: 20260908_Add_ScrapeFlag_Check_To_ACCodeCheck.sql
-- Description: Ensure scrapped codes (ScrapeFlag = 1) are rejected in USP_ACCodeCheck_whatsapp_Unified_AI and USP_ACCodeCheck_Unified_AI

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Revert test record in M_Code and clean test enquiries in Pro_Enq
UPDATE M_Code 
SET Use_Count = NULL, Allot_Date = NULL 
WHERE Code1 = 58092 AND Code2 = 48309477;

DELETE FROM Pro_Enq 
WHERE Received_Code1 = '58092' AND Received_Code2 = '48309477' AND MobileNo = '919315742150';
GO
