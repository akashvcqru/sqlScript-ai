CREATE PROCEDURE [dbo].[SP_SaveRetailerVisit_AI]  
    @SalesPersonId INT,  
    @SalesPersonName NVARCHAR(100),  
    @RetailerName NVARCHAR(150),  
    @Compid NVARCHAR(150),  
    @VisitDate DATETIME,  
    @VisitNotes NVARCHAR(MAX)  
AS  
BEGIN  
    INSERT INTO RetailerVisitLog (  
        SalesPersonId,  
        SalesPersonName,  
        RetailerName,  
  Comp_Id,  
        VisitDate,  
        VisitNotes  
    )  
    VALUES (  
        @SalesPersonId,  
        @SalesPersonName,  
        @RetailerName,  
  @Compid,  
        @VisitDate,  
        @VisitNotes  
    );  
END;
