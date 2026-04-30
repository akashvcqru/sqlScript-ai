CREATE TABLE tblInstallment_AI (
    id INT IDENTITY(1,1) PRIMARY KEY,
    M_Consumerid INT NOT NULL,
    name NVARCHAR(100),
    mobileno NVARCHAR(20),
    address NVARCHAR(MAX),
    Discription NVARCHAR(MAX),
    vendorComment NVARCHAR(MAX),
    status INT DEFAULT 0, -- 0: Pending, 1: Approved, 2: Rejected, 3: Completed
    comp_id NVARCHAR(50),
    created_date DATETIME DEFAULT GETDATE(),
    updated_date DATETIME DEFAULT GETDATE()
);
GO
