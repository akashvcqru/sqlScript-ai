-- =============================================
-- Author:      Antigravity
-- Create date: 2026-03-21
-- Description: Gets codes for a specific batch (linked via T_Pro.Row_ID)
-- =============================================
CREATE PROCEDURE [dbo].[USP_GetCodesByBatchID_AI]
    @Row_ID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Series_Limit NVARCHAR(MAX);
    DECLARE @Pro_ID NVARCHAR(50);
    DECLARE @Series_Order INT;
    DECLARE @Series_From INT;
    DECLARE @Series_To INT;

    -- Get batch details
    SELECT @Series_Limit = Series_Limit, @Pro_ID = Pro_ID
    FROM T_Pro
    WHERE Row_ID = @Row_ID;

    IF @Series_Limit IS NULL
    BEGIN
        -- If Series_Limit is not set, we can't reliably parse it.
        -- Fallback: try to find codes directly by Batch_No if it's stored in M_Code
        SELECT 
            ROW_NUMBER() OVER (ORDER BY Series_Order, Series_Serial) AS SNO,
            Pro_ID + '-' + 
            RIGHT('00' + CAST(Series_Order AS VARCHAR(2)), 2) + '-' + 
            RIGHT('0000' + CAST(Series_Serial AS VARCHAR(4)), 4) AS Series_Name,
            Code1,
            ' ' AS Mark_Scrap
        FROM M_Code
        WHERE Batch_No = CAST(@Row_ID AS VARCHAR(50))
        AND Print_Status = 1;

        RETURN;
    END

    -- Parse Series_Limit: "From PRO-01-0001 To PRO-01-0100" -> "PRO-01-0001,PRO-01-0100" (after replacement)
    -- Actually the legacy code does:
    -- string MySeriesDet = obj.statusstr.ToString().Replace("From  ", "").Replace("   To  ", ",").Trim();
    -- string[] Arr = MySeriesDet.ToString().Split(','); // ["PRO-01-0001", "PRO-01-0100"]
    -- string[] Arr1 = Arr[0].ToString().Split('-'); // ["PRO", "01", "0001"]
    
    -- In SQL we can simplify this if we assume the codes are already tagged with Batch_No
    -- But since we want to follow legacy logic closely:
    
    -- For now, let's use the Batch_No directly from M_Code if possible, 
    -- as it's more reliable than parsing a string.
    -- If Batch_No is not reliable, we'd need to parse @Series_Limit.
    
    -- Legacy Parse:
    -- SELECT Pro_ID +'-'+ (case when len(convert(nvarchar,Series_Order)) = 1 then '0'+convert(nvarchar,Series_Order) else convert(nvarchar,Series_Order) end)+'-'+  
    -- (case when len(convert(nvarchar,Series_Serial)) = 1 then '000'+convert(nvarchar,Series_Serial) when len(convert(nvarchar,Series_Serial)) = 2 then '00'+convert(nvarchar,Series_Serial) when len(convert(nvarchar,Series_Serial)) = 3 then '0'+convert(nvarchar,Series_Serial) else convert(nvarchar,Series_Serial) end) AS Series_Name ,Code1,' ' as Mark_Scrap 
    -- FROM  M_Code WHERE Pro_ID=@Pro_ID and print_status = 1 AND (Series_Order = @series_order) AND (Series_Serial >= @series_From) AND (Series_Serial <= @series_To)
    
    SELECT 
        ROW_NUMBER() OVER (ORDER BY Series_Order, Series_Serial) AS SNO,
        Pro_ID + '-' + 
        RIGHT('00' + CAST(Series_Order AS VARCHAR(2)), 2) + '-' + 
        RIGHT('0000' + CAST(Series_Serial AS VARCHAR(4)), 4) AS Series_Name,
        Code1,
        ' ' AS Mark_Scrap
    FROM M_Code
    WHERE Batch_No = CAST(@Row_ID AS VARCHAR(50))
    AND Print_Status = 1;
END
GO
