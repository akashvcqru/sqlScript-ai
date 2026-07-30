-- 1. Drop the dependent indexes
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('m_dealermaster') AND name = 'Indx_m_dealermaster_D_State')
BEGIN
    DROP INDEX [Indx_m_dealermaster_D_State] ON [dbo].[m_dealermaster]
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('m_dealermaster') AND name = 'missing_index_45244')
BEGIN
    DROP INDEX [missing_index_45244] ON [dbo].[m_dealermaster]
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('m_dealermaster') AND name = 'missing_index_45256')
BEGIN
    DROP INDEX [missing_index_45256] ON [dbo].[m_dealermaster]
END
GO

-- 2. Alter the column type to NVARCHAR(255)
ALTER TABLE [dbo].[m_dealermaster] ALTER COLUMN [Updated_By] NVARCHAR(255) NULL
GO

-- 3. Recreate the indexes
CREATE NONCLUSTERED INDEX [Indx_m_dealermaster_D_State] ON [dbo].[m_dealermaster]
(
    [D_State] ASC
)
INCLUDE (
    [DealerId], [Zone], [DealerCode], [DealerType], [DealerLocation], [DealerTechnicianId], [DE_Designation], [D_Status],
    [Created_Date], [Created_By], [Updated_Date], [Updated_By], [D_Name], [Comp_id], [City], [Mobile_Num], [Proprietor1], [Proprietor2], [Proprietor3]
)
GO

CREATE NONCLUSTERED INDEX [missing_index_45244] ON [dbo].[m_dealermaster]
(
    [Mobile_Num] ASC
)
INCLUDE (
    [DealerId], [Zone], [D_State], [DealerCode], [DealerType], [DealerLocation], [DealerTechnicianId], [DE_Designation], [D_Status],
    [Created_Date], [Created_By], [Updated_Date], [Updated_By], [D_Name], [Comp_id], [City], [Proprietor1], [Proprietor2], [Proprietor3]
)
GO

CREATE NONCLUSTERED INDEX [missing_index_45256] ON [dbo].[m_dealermaster]
(
    [D_Status] ASC,
    [Mobile_Num] ASC
)
INCLUDE (
    [DealerId], [Zone], [D_State], [DealerCode], [DealerType], [DealerLocation], [DealerTechnicianId], [DE_Designation],
    [Created_Date], [Created_By], [Updated_Date], [Updated_By], [D_Name], [Comp_id], [City], [Proprietor1], [Proprietor2], [Proprietor3]
)
GO
