CREATE PROCEDURE [dbo].[USP_GetDealerDocuments_AI]      
    @UserId VARCHAR(20)   
AS      
BEGIN      
WITH RankedDocs AS (  
    SELECT   
        DocumentType,  
        FilePath,  
        UploadedDate,  
        ROW_NUMBER() OVER (PARTITION BY DocumentType ORDER BY UploadedDate DESC) AS rn  
    FROM   
        tbl_DealerDocuments  
    WHERE   
        DealerID = @UserId  
)  
SELECT   
    DocumentType,  
    FilePath,  
    UploadedDate  
FROM   
    RankedDocs  
WHERE   
    rn = 1;  
END
