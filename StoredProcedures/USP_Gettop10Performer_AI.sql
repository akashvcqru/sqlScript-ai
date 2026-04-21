USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_Gettop10Performer_AI]    Script Date: 3/31/2026 3:15:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Gettop10Performer_AI]    
    @CompId VARCHAR(20)    
AS    
BEGIN    
    -- Temporary table to hold ranked consumers  
    SELECT TOP 10     
        ROW_NUMBER() OVER (ORDER BY SUM(b.Points) DESC) AS OnRank,    
        m.MobileNo,    
        ISNULL(m.ConsumerName, '') AS ConsumerName,    
        ISNULL(m.City, '') AS City,    
        ISNULL(m.State, '') AS State,  
        SUM(b.Points) AS TotalPoints    
    INTO #temp    
    FROM BLoyaltyPointsEarned b    
    INNER JOIN M_Consumer m ON b.M_Consumerid = m.M_Consumerid    
    WHERE b.CompId = @CompId    
    GROUP BY m.MobileNo, m.ConsumerName, m.City, m.State;  
  
    -- Final result with profile image URL  
    SELECT     
        CASE     
            WHEN p.Profile_img IS NOT NULL THEN CONCAT('https://www.vcqru.com/', p.Profile_img)    
            ELSE ''    
        END AS ProfileImageUrl,    
        t.OnRank,  
        t.MobileNo,  
        t.ConsumerName,  
        t.City,  
        t.State,  
        t.TotalPoints  
    FROM #temp t    
    INNER JOIN M_Consumer m ON m.MobileNo = t.MobileNo    
    LEFT JOIN Profile_images p ON p.M_Consumerid = m.M_Consumerid;  
  
    -- Clean up  
    DROP TABLE #temp;  
END
