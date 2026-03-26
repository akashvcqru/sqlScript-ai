USE [vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antigravity
-- Create date: 2026-03-20
-- Description:	Fetches scan codes report for a company
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetScanCodesReport_AI]
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MC.ConsumerName,
        MC.City,
        MC.PinCode,

        PE.Received_Code1,
        PE.Received_Code2,
        PE.Is_Success,
        PE.Dial_Mode,
        PE.Enq_Date,
        PE.MobileNo,
        PE.Latitude,
        PE.Longitude,

        C.Batch_No,
        C.Series_Serial,

        PR.Pro_Name,
        PR.Dispatch_Location,

        CAT.mastercode,
        CAT.Dealer_Name,
        CAT.Dealer_Location,
        CAT.Contact_Information,
        CAT.Dispatch_Date AS Dealer_Dispatch_Date,
        CAT.Invoice_Number,  
        CAT.Batch_No AS Dealer_Batch_No

    FROM Pro_Enq PE

    INNER JOIN m_consumer MC 
        ON PE.MobileNo = MC.MobileNo

    INNER JOIN M_Code C 
        ON PE.Received_Code1 = C.Code1 
       AND PE.Received_Code2 = C.Code2

    LEFT JOIN Pro_Reg PR 
        ON PE.Comp_ID = PR.Comp_ID 
       AND C.Pro_ID = PR.Pro_ID

    -- ✅ ONLY ONE MATCH (IMPORTANT FIX)
    OUTER APPLY (
        SELECT TOP 1 *
        FROM codeassign_tractrac CAT
        WHERE C.Pro_ID = CAT.Pro_ID
          AND C.Series_Order = TRY_CAST(PARSENAME(REPLACE(CAT.SeriesStart, '-', '.'), 2) AS BIGINT)
          AND C.Series_Serial BETWEEN 
              TRY_CAST(PARSENAME(REPLACE(CAT.SeriesStart, '-', '.'), 1) AS BIGINT)
              AND
              TRY_CAST(PARSENAME(REPLACE(CAT.SeriesEnd, '-', '.'), 1) AS BIGINT)
        ORDER BY TRY_CAST(PARSENAME(REPLACE(CAT.SeriesEnd, '-', '.'), 1) AS BIGINT) ASC   -- pick smallest range
    ) CAT

    WHERE 
        PE.Comp_ID = @Comp_ID 
    ORDER BY PE.Enq_Date DESC;
END
GO
