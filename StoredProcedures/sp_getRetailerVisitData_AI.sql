USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[sp_getRetailerVisitData_AI]    Script Date: 4/11/2026 3:41:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_getRetailerVisitData_AI]      
    @Start_Date VARCHAR(50) = NULL,                
    @End_Date VARCHAR(50) = NULL,  
    @compId VARCHAR(50),
    @Id INT = 0
AS  
BEGIN
    DECLARE @StartDateDT DATETIME = NULL;
    DECLARE @EndDateDT DATETIME = NULL;

    -- Convert to DATETIME only if non-empty
    IF ISDATE(@Start_Date) = 1
        SET @StartDateDT = CAST(@Start_Date AS DATETIME);

    IF ISDATE(@End_Date) = 1
        SET @EndDateDT = CAST(@End_Date AS DATETIME);

    SELECT 
        VisitId,
        SalesPersonId,
        b.MobileNo,
        SalesPersonName,
        RetailerName,
        VisitDate,
        VisitNotes,
        CreatedOn
    FROM 
        [dbo].[RetailerVisitLog] a
        inner join M_Consumer b on b.M_Consumerid = a.SalesPersonId
    WHERE 
        a.Comp_Id = @compId 
        AND (@Id = 0 OR SalesPersonId = @Id)
        AND (@StartDateDT IS NULL OR VisitDate >= @StartDateDT)
        AND (@EndDateDT IS NULL OR VisitDate <= @EndDateDT)
    ORDER BY VisitDate DESC
END
GO
