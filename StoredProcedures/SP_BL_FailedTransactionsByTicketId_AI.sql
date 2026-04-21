USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_FailedTransactionsByTicketId_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_FailedTransactionsByTicketId_AI]
(
    @TicketID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 1️⃣ CREATE TEMP TABLE
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#DedupUPI') IS NOT NULL DROP TABLE #DedupUPI;

    SELECT
        UPI.Comp_ID,
        UPI.M_Consumerid,
        UPI.MobileNo,
        UPI.ConsumerName,
        UPI.ConsumerEmailId,
        UPI.UPI_Id,
        UPI.Points_Val,
        UPI.Code1,
        UPI.Code2,
        ROW_NUMBER() OVER
        (
            PARTITION BY UPI.OrderId
            ORDER BY UPI.ReqDate DESC
        ) AS rn
    INTO #DedupUPI
    FROM tblUPITransactionDetails UPI WITH (NOLOCK)
    LEFT JOIN ClaimDetails CD WITH (NOLOCK)
        ON CD.Mobileno = UPI.MobileNo
    WHERE 
        UPI.ID = @TicketID;

    ---------------------------------------------------------
    -- 2️⃣ DETAIL OUTPUT
    ---------------------------------------------------------
    SELECT
        Comp_ID,
        Points_Val As Amount,
        ConsumerName,
        ConsumerEmailId,
        MobileNo,
        UPI_Id,
        Code1,
        Code2,
        M_Consumerid
    FROM #DedupUPI
    WHERE rn = 1;
END
