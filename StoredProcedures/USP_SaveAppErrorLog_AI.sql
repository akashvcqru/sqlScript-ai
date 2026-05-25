CREATE PROCEDURE [dbo].[USP_SaveAppErrorLog_AI]
(
    @DeviceInfo      NVARCHAR(MAX) = NULL,
    @ApiResponse     NVARCHAR(MAX) = NULL,
    @ApiName         NVARCHAR(250) = NULL,
    @Username        NVARCHAR(250) = NULL,
    @UserMobile      VARCHAR(20) = NULL,
    @PageName        NVARCHAR(250) = NULL,
    @ErrorResponse   NVARCHAR(MAX) = NULL,
    @ApplicationType VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tbl_AppErrorLog
    (
        DeviceInfo,
        ApiResponse,
        ApiName,
        Username,
        UserMobile,
        PageName,
        ErrorResponse,
        ApplicationType,
        CreatedAt
    )
    VALUES
    (
        @DeviceInfo,
        @ApiResponse,
        @ApiName,
        @Username,
        @UserMobile,
        @PageName,
        @ErrorResponse,
        @ApplicationType,
        GETDATE()
    );
END;
GO
