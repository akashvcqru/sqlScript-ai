SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LandingPage] (
    Comp_Id VARCHAR(50) NOT NULL,
    Service_Id VARCHAR(50) NOT NULL,
    PageName VARCHAR(150),
    BrandName VARCHAR(150),
    ServiceType VARCHAR(50),
    LogoUrl VARCHAR(500),
    BackgroundImageUrl VARCHAR(500),
    ProductImage1 VARCHAR(500),
    ProductImage2 VARCHAR(500),
    ProductImage3 VARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (Comp_Id, Service_Id)
);
GO
