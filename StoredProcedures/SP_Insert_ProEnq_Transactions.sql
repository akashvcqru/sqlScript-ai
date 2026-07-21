USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_Insert_ProEnq_Transactions]    Script Date: 7/20/2026 11:07:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_Insert_ProEnq_Transactions]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT * INTO #tblUPITransactionDetailse FROM tblUPITransactionDetails WHERE status = 'Success';

    -- CTE to find active subscriptions and trans details without scanning M_Code
    ;WITH RankedSubscriptions AS (
        SELECT 
            SS.Pro_ID,
            SS.Comp_ID,
            SST.IsCash,
            SST.Points,
            SS.start_order,
            SS.start_series,
            SS.end_order,
            SS.end_series,
            SST.SST_Id
        FROM M_ServiceSubscription SS WITH (NOLOCK)
        INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
        --WHERE SS.IsActive = 1 AND SS.IsDelete = 0
          --AND SST.IsActive = 1 AND SST.IsDelete = 0
    )
    INSERT INTO dbo.ProEnq_Transactions
    (
        PE_RowID,
        CompanyName,
        ProductName,
        MobileNo,
        Code1Code2,
        Code1,
        Code2,
        comp_id,
        ModeOfVerification,
        CheckedDate,
        IsCash,
        Points,
        IsSuccess,
        TransferedAmount
    )
    SELECT
        PE.Row_ID,
        CR.Comp_Name,
        PR.Pro_Name,
        PE.MobileNo,
        PE.Received_Code1 + '-' + PE.Received_Code2,
        PE.Received_Code1,
        PE.Received_Code2,
        CR.Comp_ID,
        PE.Dial_Mode,
        PE.Enq_Date,
        ISNULL(RS.IsCash, 0),
        ISNULL(RS.Points, 0),
        PE.Is_Success,
        ISNULL(UU.Amount, 0)
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN M_Code M WITH (NOLOCK)
        ON PE.Received_Code1 = CAST(M.Code1 AS VARCHAR(50))
       AND PE.Received_Code2 = CAST(M.Code2 AS VARCHAR(50))
    INNER JOIN Pro_Reg PR WITH (NOLOCK)
        ON PR.Pro_ID = M.Pro_ID
    INNER JOIN Comp_Reg CR WITH (NOLOCK)
        ON CR.Comp_ID = PR.Comp_Id
       AND CR.Status = 1
    OUTER APPLY (
        SELECT TOP 1
            RS.IsCash,
            RS.Points,
            RS.Comp_ID
        FROM RankedSubscriptions RS
        WHERE RS.Pro_ID = M.Pro_ID
          AND (
              (
                  (RS.start_order IS NOT NULL OR M.Pro_ID IN ('AJ45', 'AJ46', 'AJ47', 'AJ48', 'AJ49', 'AJ50'))
                  AND Concat(Format(M.series_order, '000#'), Format(M.Series_Serial, '000#')) 
                      Between Concat(Format(RS.start_order, '000#'), Format(RS.start_series, '000#')) 
                          And Concat(Format(RS.end_order, '000#'), Format(RS.end_series, '000#'))
              )
              OR 
              (
                  RS.start_order IS NULL
              )
          )
        ORDER BY 
            CASE 
                WHEN (RS.start_order IS NOT NULL OR M.Pro_ID IN ('AJ45', 'AJ46', 'AJ47', 'AJ48', 'AJ49', 'AJ50'))
                     AND Concat(Format(M.series_order, '000#'), Format(M.Series_Serial, '000#')) 
                         Between Concat(Format(RS.start_order, '000#'), Format(RS.start_series, '000#')) 
                             And Concat(Format(RS.end_order, '000#'), Format(RS.end_series, '000#'))
                THEN 1 
                ELSE 2 
            END ASC,
            RS.SST_Id DESC
    ) RS
    LEFT JOIN #tblUPITransactionDetailse UU WITH (NOLOCK)
        ON PE.Received_Code1 = UU.Code1
       AND PE.Received_Code2 = UU.Code2
    WHERE RS.Comp_ID NOT IN ('Comp-1152', 'Comp-1669')
      AND PE.Is_Success = '1'
      AND (UU.Status = 'Success' OR UU.Status IS NULL)
      AND PE.Enq_Date >= DATEADD(DAY, -3, GETDATE())
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.ProEnq_Transactions PT
          WHERE PT.PE_RowID = PE.Row_ID
      );
END;
GO
