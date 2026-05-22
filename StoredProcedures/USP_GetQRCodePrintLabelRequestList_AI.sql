USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-22
-- Description: Get QR Code Print Label Request List with pagination and search
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetQRCodePrintLabelRequestList_AI]
    @Comp_ID NVARCHAR(50),
    @Search NVARCHAR(200),
    @Offset INT,
    @Limit INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT M_Label_Request.Row_ID, 
           CONVERT(nvarchar, M_Label_Request.Entry_Date, 107) AS RequestDate, 
           M_Label_Request.Pro_ID, 
           Pro_Reg.Pro_Name, 
           M_Label.Label_Name as LabelType, 
           M_Label.Label_Size, 
           M_Label.Label_Prise, 
           M_Label_Request.Qty as RequestedLabels,
           (CASE 
                WHEN M_Label_Request.Flag = '0' THEN 'Pending' 
                WHEN M_Label_Request.Flag = '-1' THEN 'Rejected' 
                WHEN M_Label_Request.Flag = '1' THEN 'Printed' 
                WHEN M_Label_Request.Flag = '-2' THEN 'Canceled' 
            END) AS RequestStatusFlag,
           Tracking_No, 
           M_Label_Request.Flag,
           COUNT(*) OVER() AS TotalRecords
    FROM M_Label_Request 
    INNER JOIN M_Label ON M_Label_Request.Label_Code = M_Label.Label_Code 
    INNER JOIN Pro_Reg ON M_Label_Request.Pro_ID = Pro_Reg.Pro_ID 
    WHERE Pro_Reg.Comp_ID = @Comp_ID 
      AND (M_Label_Request.Tracking_No LIKE @Search 
           OR Pro_Reg.Pro_Name LIKE @Search
           OR M_Label.Label_Name LIKE @Search
           OR CAST(M_Label_Request.Row_ID AS NVARCHAR(50)) LIKE @Search)
    ORDER BY M_Label_Request.Entry_Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
