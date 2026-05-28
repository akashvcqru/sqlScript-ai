USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_vcqru_GetLoginHistory_AI]    Script Date: 5/14/2026 1:52:31 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec SP_vcqru_GetLoginHistory_AI 'Comp-1555'
CREATE PROCEDURE [dbo].[SP_vcqru_GetLoginHistory_AI]
    @Comp_ID VARCHAR(15),
    @Page    INT = NULL,     
    @Limit   INT = NULL,
    @IsExport BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;

    ----------------------------------------------------
    -- Normalize
    ----------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);

    ----------------------------------------------------
    -- EXPORT MODE (NO PAGINATION)
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            Email,
            LoginTime,
            IPAddress,
            BrowserInfo,
            DeviceInfo,
            OperatingSystem,
            CASE 
                WHEN IsSuccess = 1 THEN 'Successful Login'
                ELSE 'Unsuccessful Login'
            END AS LoginStatus,
            [Message]
        FROM Tbl_Login_History
        WHERE Comp_ID = @Comp_ID
        ORDER BY LoginTime DESC;

        RETURN;
    END

    ----------------------------------------------------
    -- Pagination Defaults
    ----------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ----------------------------------------------------
    -- RESULT SET 1 : PAGINATED DATA
    ----------------------------------------------------
    SELECT 
        Email,
        LoginTime,
        IPAddress,
        BrowserInfo,
        DeviceInfo,
        OperatingSystem,
        CASE 
            WHEN IsSuccess = 1 THEN 'Successful Login'
            ELSE 'Unsuccessful Login'
        END AS LoginStatus,
        [Message]
    FROM Tbl_Login_History
    WHERE Comp_ID = @Comp_ID
    ORDER BY LoginTime DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ----------------------------------------------------
    -- RESULT SET 2 : PAGINATION META
    ----------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM Tbl_Login_History
    WHERE Comp_ID = @Comp_ID;
END
