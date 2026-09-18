USE [Vcqru]
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_BL_CodesActivityReport_AI')
BEGIN
    CREATE TABLE [dbo].[tbl_BL_CodesActivityReport_AI]
    (
        [ID]             BIGINT IDENTITY(1,1) PRIMARY KEY,
        [Row_id]         BIGINT NULL,               -- Pro_Enq.Row_id
        [Comp_ID]        VARCHAR(50) NOT NULL,
        [UniqueCode]     VARCHAR(100) NULL,
        [Enq_Date]       DATETIME NULL,
        [Dial_Mode]      VARCHAR(50) NULL,
        [ConsumerName]   NVARCHAR(150) NULL,
        [MobileNo]       VARCHAR(50) NULL,
        [State]          NVARCHAR(100) NULL,
        [City]           NVARCHAR(100) NULL,
        [Pro_Name]       NVARCHAR(200) NULL,
        [Points]         DECIMAL(18,2) NULL,
        [Result]         VARCHAR(50) NULL,
        [Latitude]       VARCHAR(50) NULL,
        [Longitude]      VARCHAR(50) NULL,
        [AssignPoint]    DECIMAL(18,2) NULL,
        [WornPoint]      DECIMAL(18,2) NULL,
        [ReferralPoints] DECIMAL(18,2) NULL,
        [CreatedDate]    DATETIME DEFAULT GETDATE()
    );

    CREATE NONCLUSTERED INDEX [IX_tbl_BL_CodesActivityReport_Comp_Mobile_Date]
    ON [dbo].[tbl_BL_CodesActivityReport_AI] ([Comp_ID], [MobileNo], [Enq_Date]);

    PRINT 'Table tbl_BL_CodesActivityReport_AI created successfully.';
END
ELSE
BEGIN
    PRINT 'Table tbl_BL_CodesActivityReport_AI already exists.';
END
GO
