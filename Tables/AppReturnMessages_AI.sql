IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AppReturnMessages_AI]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AppReturnMessages_AI] (
        [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [SrNo] INT NULL,
        [ApiName] NVARCHAR(255) NOT NULL,
        [MessageType] NVARCHAR(100) NULL,
        [ActualMessage] NVARCHAR(MAX) NOT NULL,
        [RecommendedEnglish] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL DEFAULT (1),
        [CreatedDate] DATETIME NOT NULL DEFAULT (GETDATE()),
        [UpdatedDate] DATETIME NOT NULL DEFAULT (GETDATE())
    );

    CREATE NONCLUSTERED INDEX [IX_AppReturnMessages_AI_ApiName] 
    ON [dbo].[AppReturnMessages_AI] ([ApiName], [IsActive]) 
    INCLUDE ([ActualMessage], [RecommendedEnglish]);
END;
GO
