USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GIFTCLAIMDETAILS_BL_Dealer_AI]        
    @Mobileno VARCHAR(20),        
    @Comp_id VARCHAR(20)        
AS        
BEGIN        
    SET NOCOUNT ON;

    -- Step 1: Get the list of consumers related to the dealer
    SELECT M.MobileNo 
    INTO #Consumerlist 
    FROM M_Consumer m  
    INNER JOIN tbl_Vendorvisekycstatus v ON m.M_Consumerid = v.M_consumerId  
    WHERE Dealer_M_consumerid IN (  
        SELECT M_Consumerid 
        FROM M_Consumer 
        WHERE MobileNo = @Mobileno  
    );  
  
    -- Step 2: Store the final response into a temp table
    SELECT * 
    INTO #FinalGiftClaimDetails
    FROM (
        -- Gift claim records      
        SELECT       
            FORMAT(a.Claim_date, 'dd MMM yyyy hh:mm tt') AS Date,       
            a.Amount,       
            a.Isapproved,       
            a.Mobileno,       
            a.vendor_comment AS Message,        
            b.Gift_name,       
            a.Amount AS Gift_value,     
            b.Gift_desc,       
            b.Gift_image,       
            b.gift_id,       
            a.Row_id AS claimid         
        FROM ClaimDetails a        
        INNER JOIN Claim_gift b ON a.Gift_id = b.gift_id       
        WHERE a.Comp_id = b.CompID       
          AND a.Mobileno IN (SELECT MobileNo FROM #Consumerlist)  
          AND a.Comp_id = @Comp_id        

        UNION ALL        

        -- Cash transfer records (no gift associated)      
        SELECT       
            FORMAT(Claim_date, 'dd MMM yyyy hh:mm tt') AS Date,       
            Amount,       
            Isapproved,       
            Mobileno,       
            vendor_comment AS Message,        
            'Cash Claim' AS Gift_name,       
            Amount AS Gift_value,       
            '' AS Gift_desc,       
            'images/Gift/new/Cash_transfer.png' AS Gift_image,       
            '' AS gift_id,       
            Row_id AS claimid         
        FROM ClaimDetails       
        WHERE Gift_id IS NULL      
          AND Mobileno = @Mobileno       
          AND Comp_id = @Comp_id  
          AND Claim_mode = 'Manual'      
    ) AS FinalResultSet;

    -- Step 3: Return the result
    SELECT v.Name,v.usercity,v.userpin,f.* FROM #FinalGiftClaimDetails f
	inner join M_Consumer c on f.Mobileno=c.MobileNo
	inner join tbl_Vendorvisekycstatus v on c.M_Consumerid=v.M_consumerId
	ORDER BY claimid DESC;

    -- Optional: Drop temp tables (they will auto-drop on scope end, but explicit drop is cleaner)
    DROP TABLE #Consumerlist;
    DROP TABLE #FinalGiftClaimDetails;
END
