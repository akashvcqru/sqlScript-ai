CREATE TABLE [dbo].[tbl_UserReferralCodes] (
    [Id] INT IDENTITY(1,1) PRIMARY KEY,
    [M_Consumerid] VARCHAR(50) NOT NULL,
    [Comp_id] VARCHAR(50) NOT NULL,
    [RefCode] VARCHAR(100) UNIQUE NOT NULL,
    [IsUsed] BIT DEFAULT 0,
    [usermobileno] VARCHAR(20) NULL,
    [UsedByPoints] INT NULL,
    [SharedByPoints] INT NULL,
    [CreatedDate] DATETIME DEFAULT GETDATE(),
    [UpdatedDate] DATETIME DEFAULT GETDATE()
);
