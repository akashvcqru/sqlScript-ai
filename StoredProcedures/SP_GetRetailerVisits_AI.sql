CREATE PROCEDURE [dbo].[SP_GetRetailerVisits_AI]  
    @SalesPersonId INT  
AS  
BEGIN  
    SELECT  
        VisitId,  
        SalesPersonId,  
        SalesPersonName,  
        RetailerName,  
        VisitDate,  
        VisitNotes,  
        CreatedOn  
    FROM RetailerVisitLog  
    WHERE SalesPersonId = @SalesPersonId  
    ORDER BY VisitDate DESC;  
END;
