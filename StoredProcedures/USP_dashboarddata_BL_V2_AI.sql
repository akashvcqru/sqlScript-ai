USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Description: Optimized dashboard data retrieval for multi-user dashboard.
-- Returns ONLY basic scan counts, skipping point and cash calculations for performance.
CREATE OR ALTER PROCEDURE [dbo].[USP_dashboarddata_BL_V2_AI]
(    
 @M_consumerid INT,    
 @compid VARCHAR(10) = NULL 
)    
AS    
BEGIN  
    SET NOCOUNT ON;
    DECLARE @TotalCodeCheck INT = 0;
    DECLARE @TotalSuccessCheck INT = 0;
    DECLARE @USERTYPE INT = 0;
    DECLARE @FilterDate DATETIME = '1900-08-04 00:00:00.000';
    DECLARE @MobileNo VARCHAR(20);

    SELECT @MobileNo = MobileNo FROM M_Consumer WHERE M_Consumerid = @M_consumerid AND IsDelete = 0;
    IF @MobileNo IS NULL RETURN;

    IF (@compid = 'Comp-1152')
    BEGIN
        SELECT @USERTYPE = Vrkabel_User_Type FROM M_Consumer WHERE M_Consumerid = @M_consumerid;
        IF (@USERTYPE IN (121)) SET @FilterDate = '2024-02-24 00:00:00.000';
        IF (@USERTYPE IN (141,119)) SET @FilterDate = '2022-08-04 00:00:00.000';

        SELECT @TotalSuccessCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate AND Is_Success = 1;
        SELECT @TotalCodeCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate;
    END
    ELSE
    BEGIN
        -- Optimized counts in one pass
        SELECT 
            @TotalSuccessCheck = COUNT(CASE WHEN Pro_Enq.Is_Success = 1 THEN 1 END),
            @TotalCodeCheck = COUNT(*)
        FROM Pro_Enq 
        INNER JOIN M_Code ON M_Code.Code1 = Pro_Enq.Received_Code1 AND M_Code.Code2 = Pro_Enq.Received_Code2  
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID  
        WHERE Pro_Enq.MobileNo = @MobileNo
          AND (Pro_Reg.Comp_ID = @compid OR (@compid IN ('Comp-1650', 'Comp-1567') AND Pro_Reg.Comp_ID IN ('Comp-1650', 'Comp-1567')));
    END

    -- Result Set 1: Overall Stats (Simplified)
    -- Mapping: TotalCode, ReedemPoints, SuccessCode, TotalCash, TransferredCash
    SELECT @TotalCodeCheck as TotalCode, 
           0 as ReedemPoints, 
           @TotalSuccessCheck as SuccessCode, 
           0 as TotalCash, 
           0 as TransferredCash;
END
GO
