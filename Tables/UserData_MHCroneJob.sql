/****** Object:  Table [dbo].[UserData_MHCroneJob]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserData_MHCroneJob](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](20) NULL,
	[M_ConsumerId] [int] NOT NULL,
	[kycremark] [nvarchar](1000) NULL,
	[ConsumerName] [nvarchar](200) NULL,
	[MobileNo] [nvarchar](20) NULL,
	[State] [nvarchar](200) NULL,
	[City] [nvarchar](200) NULL,
	[PinCode] [nvarchar](50) NULL,
	[DealerCode] [nvarchar](50) NULL,
	[DealerTechnicianId] [nvarchar](50) NULL,
	[VRKbl_KYC_status] [tinyint] NULL,
	[Entry_Date] [datetime] NULL,
	[InsertedDate] [datetime] NOT NULL,
	[Address] [nvarchar](1000) NULL,
	[pancard_number] [nvarchar](50) NULL,
	[PanHolderName] [nvarchar](200) NULL,
	[panekycStatus] [varchar](50) NULL,
	[pan_card_file] [nvarchar](500) NULL,
	[aadharNumber] [nvarchar](50) NULL,
	[aadharFile] [nvarchar](500) NULL,
	[aadharback] [nvarchar](500) NULL,
	[AadharHolderName] [nvarchar](200) NULL,
	[aadharkycStatus] [varchar](50) NULL,
	[Account_HolderNm] [nvarchar](200) NULL,
	[Account_No] [nvarchar](50) NULL,
	[IFSC_Code] [nvarchar](50) NULL,
	[Bank_Name] [nvarchar](200) NULL,
	[Vrkabel_User_Type] [nvarchar](50) NULL,
	[Branch] [nvarchar](200) NULL,
	[chkPassbook] [nvarchar](500) NULL,
	[bankekycStatus] [varchar](50) NULL,
	[UPIId] [varchar](100) NULL,
	[UpiidImage] [varchar](500) NULL,
	[UPIKYCSTATUS] [varchar](50) NULL,
	[IsDelete] [bit] NOT NULL,
	[Email] [varchar](200) NULL,
	[transaction_status] [varchar](300) NULL,
	[dealer_state] [varchar](150) NULL,
	[DealerType] [int] NOT NULL,
	[designation] [varchar](150) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
