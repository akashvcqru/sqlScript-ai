CREATE PROCEDURE [dbo].[Proc_FindCodesWithMultipleServices_AI]
(
    @Comp_ID nvarchar(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Get all active subscriptions for the company
    IF OBJECT_ID('tempdb..#CompanySubs') IS NOT NULL DROP TABLE #CompanySubs;
    SELECT 
        Subscribe_Id, Service_ID, Pro_ID, 
        start_order, start_series, end_order, end_series,
        CONCAT(FORMAT(start_order,'000#'), FORMAT(start_series,'000#')) as FullStart,
        CONCAT(FORMAT(end_order,'000#'), FORMAT(end_series,'000#')) as FullEnd
    INTO #CompanySubs 
    FROM M_ServiceSubscription (NOLOCK) 
    WHERE Comp_ID = @Comp_ID AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDelete,0) = 0;

    -- 2. Identify products with multiple "blank" (default) services
    IF OBJECT_ID('tempdb..#MultipleBlank') IS NOT NULL DROP TABLE #MultipleBlank;
    SELECT Pro_ID, COUNT(*) as ServiceCount
    INTO #MultipleBlank
    FROM #CompanySubs
    WHERE start_order IS NULL
    GROUP BY Pro_ID
    HAVING COUNT(*) > 1;

    -- 3. Identify overlapping ranges for the same Pro_ID
    IF OBJECT_ID('tempdb..#Overlaps') IS NOT NULL DROP TABLE #Overlaps;
    SELECT s1.Pro_ID, 
           s1.Subscribe_Id as Sub1, s2.Subscribe_Id as Sub2,
           -- Calculate intersection range
           CASE WHEN s1.FullStart > s2.FullStart THEN s1.FullStart ELSE s2.FullStart END as IntersectStart,
           CASE WHEN s1.FullEnd < s2.FullEnd THEN s1.FullEnd ELSE s2.FullEnd END as IntersectEnd
    INTO #Overlaps
    FROM #CompanySubs s1
    JOIN #CompanySubs s2 ON s1.Pro_ID = s2.Pro_ID AND s1.Subscribe_Id < s2.Subscribe_Id
    WHERE s1.start_order IS NOT NULL AND s2.start_order IS NOT NULL
    AND (s1.FullStart <= s2.FullEnd)
    AND (s2.FullStart <= s1.FullEnd);

    -- 4. Result Set
    -- Case A: Codes in overlapping ranges
    SELECT 
        mc.Code1, 
        mc.Code2, 
        mc.Pro_ID, 
        (SELECT Pro_Name FROM Pro_Reg (NOLOCK) WHERE Pro_ID = mc.Pro_ID) as ProductName,
        'Overlapping Ranges' as Reason,
        ov.Sub1 + ', ' + ov.Sub2 as AffectedSubscriptions
    FROM M_Code mc (NOLOCK)
    JOIN #Overlaps ov ON mc.Pro_ID = ov.Pro_ID
    WHERE CONCAT(FORMAT(mc.Series_Order,'000#'), FORMAT(mc.Series_Serial,'000#')) BETWEEN ov.IntersectStart AND ov.IntersectEnd
    
    --UNION ALL
    
    ---- Case B: Codes matching 0 ranges but product has multiple blank services
    --SELECT 
    --    mc.Code1, 
    --    mc.Code2, 
    --    mc.Pro_ID, 
    --    (SELECT Pro_Name FROM Pro_Reg (NOLOCK) WHERE Pro_ID = mc.Pro_ID) as ProductName,
    --    'Multiple Default Services' as Reason,
    --    CAST(mb.ServiceCount AS nvarchar(10)) + ' Default Services' as AffectedSubscriptions
    --FROM M_Code mc (NOLOCK)
    --JOIN #MultipleBlank mb ON mc.Pro_ID = mb.Pro_ID
    --WHERE NOT EXISTS (
    --    SELECT 1 FROM #CompanySubs ss 
    --    WHERE ss.Pro_ID = mc.Pro_ID AND ss.start_order IS NOT NULL
    --    AND CONCAT(FORMAT(mc.Series_Order,'000#'), FORMAT(mc.Series_Serial,'000#')) BETWEEN ss.FullStart AND ss.FullEnd
    --);

    -- Cleanup
    IF OBJECT_ID('tempdb..#CompanySubs') IS NOT NULL DROP TABLE #CompanySubs;
    IF OBJECT_ID('tempdb..#MultipleBlank') IS NOT NULL DROP TABLE #MultipleBlank;
    IF OBJECT_ID('tempdb..#Overlaps') IS NOT NULL DROP TABLE #Overlaps;
END
