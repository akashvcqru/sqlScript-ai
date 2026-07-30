USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GIFTCLAIMDETAILS_BL_AI]      
    @Mobileno VARCHAR(20),      
    @Comp_id VARCHAR(20)      
AS      
BEGIN      
    -- Gift claim records    
    SELECT     
        FORMAT(a.Claim_date, 'dd MMM yyyy HH:mm tt') AS Date,     
        a.Amount,     
        a.Isapproved,     
        a.Mobileno,     
        a.vendor_comment AS Message,      
        b.Gift_name,     
        a.Amount as Gift_value,   
      --  b.Gift_value,     
        b.Gift_desc,      aa.Service_ID ,aa.ServiceName,
        b.Gift_image,     
        b.gift_id,     
        a.Row_id AS claimid,
        a.SupervisorValue,
        a.SupervisorGet,
        a.SupervisorValueType,
        a.SupervisorMobileNo,
        a.RequestAmmount
    FROM ClaimDetails a      
    INNER JOIN Claim_gift b ON a.Gift_id = b.gift_id   	left join M_Service aa on aa.Service_ID = a.Service_ID  
    WHERE a.Comp_id = b.CompID     
      AND a.Mobileno = @Mobileno     
      AND a.Comp_id = @Comp_id      
      AND a.Row_id NOT IN (SELECT Row_id FROM ClaimDetails WHERE IsReqClaimReport = 0)
    
    UNION ALL      
    
    -- Cash transfer records (no gift associated)    
    SELECT     
        FORMAT(Claim_date, 'dd MMM yyyy HH:mm tt') AS Date,     
        Amount,     
        Isapproved,     
        Mobileno,     
        vendor_comment AS Message,      
        'Cash Claim' AS Gift_name,   
        Amount AS Gift_value,     
        '' AS Gift_desc,      aa.Service_ID ,aa.ServiceName, 
        'images/Gift/new/Cash_transfer.png' AS Gift_image,     
        '' AS gift_id,     
        Row_id AS claimid,
        a.SupervisorValue,
        a.SupervisorGet,
        a.SupervisorValueType,
        a.SupervisorMobileNo,
        a.RequestAmmount
    FROM ClaimDetails     a 	left join M_Service aa on aa.Service_ID = a.Service_ID
  WHERE Gift_id IS NULL  
      AND a.Mobileno = @Mobileno   
      AND a.Comp_id = @Comp_id  
	  and Claim_mode='Manual'  
      AND a.Row_id NOT IN (SELECT Row_id FROM ClaimDetails WHERE IsReqClaimReport = 0)
  --and (a.Comp_id = @Comp_id or (@Comp_id IN ('Comp-1650', 'Comp-1567') and a.Comp_id IN ('Comp-1650', 'Comp-1567') ) )   
    
    UNION ALL
 
    -- Transaction records for specific companies (e.g., Comp-1152)
    SELECT 
        FORMAT(TransactionDate, 'dd MMM yyyy HH:mm tt') AS Date,
        Amount,
        Issuccess AS Isapproved,
        MobileNumber AS Mobileno,
        TransctionNumber AS Message,
        'Cash Claim' AS Gift_name,
        Amount AS Gift_value,
        '' AS Gift_desc,
        'SRV1002' AS Service_ID,
        'Cash Transfer' AS ServiceName,
        'images/Gift/new/Cash_transfer.png' AS Gift_image,
        '' AS gift_id,
        TransactionsId AS claimid,
        NULL AS SupervisorValue,
        NULL AS SupervisorGet,
        NULL AS SupervisorValueType,
        NULL AS SupervisorMobileNo,
        Amount AS RequestAmmount
    FROM [dbo].[Transactions] WITH (NOLOCK)
    WHERE (MobileNumber = @Mobileno OR RIGHT(MobileNumber, 10) = RIGHT(@Mobileno, 10))
      AND ('Comp-' + CAST(CompId AS VARCHAR) = @Comp_id OR CAST(CompId AS VARCHAR) = @Comp_id)
      AND (@Comp_id = 'Comp-1152' OR @Comp_id = '1152')
    
    ORDER BY claimid DESC      
END
