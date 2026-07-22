USE [Vcqru]
GO
/****** Object:  Table [dbo].[TempDataSyncLog]    Script Date: 7/22/2026 2:46:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE dbo.TempDataSyncLog
(
    Row_ID                INT IDENTITY(1,1) PRIMARY KEY,
    Comp_ID               VARCHAR(20) NOT NULL,
    Comp_Name             NVARCHAR(200) NOT NULL,

    SyncDateTime          DATETIME NOT NULL DEFAULT(GETDATE()),

    PayoutReportCount     INT NOT NULL DEFAULT(0),
    CodeActivityCount     INT NOT NULL DEFAULT(0),

    PayoutFromDate        DATETIME NULL,
    CodeActivityFromDate  DATETIME NULL,

    PayoutToDate          DATETIME NULL,
    CodeActivityToDate    DATETIME NULL,

    Status                VARCHAR(20) NOT NULL DEFAULT('Success'),
    ErrorMessage          NVARCHAR(1000) NULL
) ON [PRIMARY];
GO
