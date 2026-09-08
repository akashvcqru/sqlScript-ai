-- Seed data for AppReturnMessages_AI
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (1, N'HttpGet api/bl-app/BrandSetting', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'Brand settings retrieved successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (2, N'HttpGet api/bl-app/BrandSetting', N'Success', N'Brand settings retrieved successfully', N'Brand settings retrieved successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Brand settings retrieved successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'Brand settings retrieved successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'App is under maintenance, please try again later.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (3, N'HttpGet api/bl-app/BrandSetting', N'Conditional / Business Logic', N'App is under maintenance, please try again later.', N'We''re upgrading your experience. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Conditional / Business Logic', [RecommendedEnglish] = N'We''re upgrading your experience. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'App is under maintenance, please try again later.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (4, N'HttpGet api/bl-app/BrandSetting', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/BrandSetting' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'Missing required parameters: compid or pin.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (5, N'HttpGet api/bl-app/Getstatewisedealer', N'Validation', N'Missing required parameters: compid or pin.', N'Missing required parameters: brand details or pin.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Missing required parameters: brand details or pin.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'Missing required parameters: compid or pin.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'Success.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (6, N'HttpGet api/bl-app/Getstatewisedealer', N'Success', N'Success.', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'Success.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'No dealers found for the specified criteria.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (7, N'HttpGet api/bl-app/Getstatewisedealer', N'Validation', N'No dealers found for the specified criteria.', N'No dealers found for the specified criteria.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No dealers found for the specified criteria.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'No dealers found for the specified criteria.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (8, N'HttpGet api/bl-app/Getstatewisedealer', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Getstatewisedealer' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Brandlist' AND [ActualMessage] = N'Brand list with points retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (9, N'HttpGet api/bl-app/Brandlist', N'Success', N'Brand list with points retrieved successfully.', N'Brand list with points retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Brand list with points retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Brandlist' AND [ActualMessage] = N'Brand list with points retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForLogin' AND [ActualMessage] = N'new')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (10, N'HttpPost api/bl-app/SendOTPForLogin', N'Success', N'new', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForLogin' AND [ActualMessage] = N'new';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForLogin' AND [ActualMessage] = N'SMS API Error: {StatusCode}. URL: {Url}. Response: {Response}')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (11, N'HttpPost api/bl-app/SendOTPForLogin', N'Error', N'SMS API Error: {StatusCode}. URL: {Url}. Response: {Response}', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForLogin' AND [ActualMessage] = N'SMS API Error: {StatusCode}. URL: {Url}. Response: {Response}';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (12, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'Please enter a valid mobile number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (13, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Validation', N'Please enter a valid mobile number.', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'Please enter a valid mobile number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'Invalid consumer ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (14, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Validation', N'Invalid consumer ID.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'Invalid consumer ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'This user is deleted from this company')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (15, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Success', N'This user is deleted from this company', N'This user is deleted from this company', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'This user is deleted from this company', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'This user is deleted from this company';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'successMsgNormal')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (16, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Success', N'successMsgNormal', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'successMsgNormal';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'User does not exist!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (17, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Validation', N'User does not exist!', N'This mobile number isn''t registered. Please sign up to continue.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'This mobile number isn''t registered. Please sign up to continue.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'User does not exist!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'The OTP entered is incorrect. Please re-enter the correct OTP or request a new one.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (18, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Validation', N'The OTP entered is incorrect. Please re-enter the correct OTP or request a new one.', N'Incorrect OTP. Please try again or request a new OTP.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Incorrect OTP. Please try again or request a new OTP.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'The OTP entered is incorrect. Please re-enter the correct OTP or request a new one.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (19, N'HttpPost api/bl-app/ValidateOTPForLogin', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForLogin' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (20, N'HttpPost api/bl-app/validateOldKyc', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Invalid company ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (21, N'HttpPost api/bl-app/validateOldKyc', N'Validation', N'Invalid company ID.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Invalid company ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Invalid mobile no.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (22, N'HttpPost api/bl-app/validateOldKyc', N'Validation', N'Invalid mobile no.', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Invalid mobile no.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Invalid Consumer ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (23, N'HttpPost api/bl-app/validateOldKyc', N'Validation', N'Invalid Consumer ID.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Invalid Consumer ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Do not update name in profile.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (24, N'HttpPost api/bl-app/validateOldKyc', N'Validation', N'Do not update name in profile.', N'Do not update name in profile.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Do not update name in profile.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Do not update name in profile.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Need to update name')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (25, N'HttpPost api/bl-app/validateOldKyc', N'Conditional / Business Logic', N'Need to update name', N'Need to update name', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Conditional / Business Logic', [RecommendedEnglish] = N'Need to update name', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Need to update name';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'kycEx')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (26, N'HttpPost api/bl-app/validateOldKyc', N'Error', N'kycEx', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'kycEx';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'zoopDbEx')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (27, N'HttpPost api/bl-app/validateOldKyc', N'Error', N'zoopDbEx', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'zoopDbEx';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'mbaEx')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (28, N'HttpPost api/bl-app/validateOldKyc', N'Error', N'mbaEx', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'mbaEx';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'transKycEx')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (29, N'HttpPost api/bl-app/validateOldKyc', N'Error', N'transKycEx', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'transKycEx';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Validation completed successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (30, N'HttpPost api/bl-app/validateOldKyc', N'Success', N'Validation completed successfully.', N'Validation completed successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Validation completed successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'Validation completed successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (31, N'HttpPost api/bl-app/validateOldKyc', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/validateOldKyc' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RejectKyc' AND [ActualMessage] = N'Missing required parameters: M_Consumerid or comp_id.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (32, N'HttpPost api/bl-app/RejectKyc', N'Validation', N'Missing required parameters: M_Consumerid or comp_id.', N'Missing required parameters: user details or brand details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Missing required parameters: user details or brand details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RejectKyc' AND [ActualMessage] = N'Missing required parameters: M_Consumerid or comp_id.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RejectKyc' AND [ActualMessage] = N'KYC status rejected successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (33, N'HttpPost api/bl-app/RejectKyc', N'Success', N'KYC status rejected successfully.', N'KYC status rejected successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'KYC status rejected successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RejectKyc' AND [ActualMessage] = N'KYC status rejected successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RejectKyc' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (34, N'HttpPost api/bl-app/RejectKyc', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RejectKyc' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (35, N'HttpGet api/bl-app/Dashboardiconsmultiusers', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Invalid company ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (36, N'HttpGet api/bl-app/Dashboardiconsmultiusers', N'Validation', N'Invalid company ID.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Invalid company ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Invalid mobile no.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (37, N'HttpGet api/bl-app/Dashboardiconsmultiusers', N'Validation', N'Invalid mobile no.', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Invalid mobile no.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Invalid Consumer ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (38, N'HttpGet api/bl-app/Dashboardiconsmultiusers', N'Validation', N'Invalid Consumer ID.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Invalid Consumer ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Icon data fetched successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (39, N'HttpGet api/bl-app/Dashboardiconsmultiusers', N'Success', N'Icon data fetched successfully.', N'Icon data fetched successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Icon data fetched successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'Icon data fetched successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'ex.Message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (40, N'HttpGet api/bl-app/Dashboardiconsmultiusers', N'Error', N'ex.Message', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboardiconsmultiusers' AND [ActualMessage] = N'ex.Message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (41, N'HttpPost api/bl-app/TdsInfo', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Invalid company ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (42, N'HttpPost api/bl-app/TdsInfo', N'Validation', N'Invalid company ID.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Invalid company ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Invalid financial year format.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (43, N'HttpPost api/bl-app/TdsInfo', N'Validation', N'Invalid financial year format.', N'Invalid financial year format.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid financial year format.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Invalid financial year format.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Failed to fetch TDS Info data.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (44, N'HttpPost api/bl-app/TdsInfo', N'Error', N'Failed to fetch TDS Info data.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Failed to fetch TDS Info data.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Record not available.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (45, N'HttpPost api/bl-app/TdsInfo', N'Validation', N'Record not available.', N'No information is available right now.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No information is available right now.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Record not available.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Successfully fetched TDS Info data.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (46, N'HttpPost api/bl-app/TdsInfo', N'Success', N'Successfully fetched TDS Info data.', N'Successfully fetched TDS Info data.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Successfully fetched TDS Info data.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'Successfully fetched TDS Info data.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (47, N'HttpPost api/bl-app/TdsInfo', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TdsInfo' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddInstalment' AND [ActualMessage] = N'FALSE')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (48, N'HttpPost api/bl-app/AddInstalment', N'Success', N'FALSE', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddInstalment' AND [ActualMessage] = N'FALSE';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddInstalment' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (49, N'HttpPost api/bl-app/AddInstalment', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddInstalment' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetInstalment' AND [ActualMessage] = N'Installments retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (50, N'HttpGet api/bl-app/GetInstalment', N'Success', N'Installments retrieved successfully.', N'Installments retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Installments retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetInstalment' AND [ActualMessage] = N'Installments retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (51, N'HttpGet api/bl-app/UserKycStatus', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Please enter a valid mobile number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (52, N'HttpGet api/bl-app/UserKycStatus', N'Validation', N'Please enter a valid mobile number.', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Please enter a valid mobile number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Company Id cannot be null or less than 5 characters.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (53, N'HttpGet api/bl-app/UserKycStatus', N'Validation', N'Company Id cannot be null or less than 5 characters.', N'Company Id cannot be null or less than 5 characters.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Company Id cannot be null or less than 5 characters.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Company Id cannot be null or less than 5 characters.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Invalid consumer ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (54, N'HttpGet api/bl-app/UserKycStatus', N'Validation', N'Invalid consumer ID.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'Invalid consumer ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'KYC status retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (55, N'HttpGet api/bl-app/UserKycStatus', N'Success', N'KYC status retrieved successfully.', N'KYC status retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'KYC status retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'KYC status retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (56, N'HttpGet api/bl-app/UserKycStatus', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/UserKycStatus' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Request can''t be null or empty')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (57, N'HttpGet api/bl-app/ContactUS', N'Validation', N'Request can''t be null or empty', N'Request can''t be null or empty', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Request can''t be null or empty', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Request can''t be null or empty';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Comp data is empty or null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (58, N'HttpGet api/bl-app/ContactUS', N'Validation', N'Comp data is empty or null.', N'Comp data is empty or null.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Comp data is empty or null.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Comp data is empty or null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Failed to parse contact data.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (59, N'HttpGet api/bl-app/ContactUS', N'Error', N'Failed to parse contact data.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Failed to parse contact data.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Brand settings retrieved successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (60, N'HttpGet api/bl-app/ContactUS', N'Success', N'Brand settings retrieved successfully', N'Brand settings retrieved successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Brand settings retrieved successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Brand settings retrieved successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'sqlEx')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (61, N'HttpGet api/bl-app/ContactUS', N'Error', N'sqlEx', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'sqlEx';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Database error occurred.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (62, N'HttpGet api/bl-app/ContactUS', N'Error', N'Database error occurred.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Database error occurred.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Internal server error occurred.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (63, N'HttpGet api/bl-app/ContactUS', N'Error', N'Internal server error occurred.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/ContactUS' AND [ActualMessage] = N'Internal server error occurred.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (64, N'HttpGet api/bl-app/get-faq', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'FAQ data is empty or null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (65, N'HttpGet api/bl-app/get-faq', N'Validation', N'FAQ data is empty or null.', N'FAQ data is empty or null.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'FAQ data is empty or null.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'FAQ data is empty or null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'sqlEx')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (66, N'HttpGet api/bl-app/get-faq', N'Error', N'sqlEx', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'sqlEx';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'Database error occurred.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (67, N'HttpGet api/bl-app/get-faq', N'Error', N'Database error occurred.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'Database error occurred.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'Internal server error occurred.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (68, N'HttpGet api/bl-app/get-faq', N'Error', N'Internal server error occurred.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/get-faq' AND [ActualMessage] = N'Internal server error occurred.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetBlog' AND [ActualMessage] = N'sqlEx')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (69, N'HttpGet api/bl-app/GetBlog', N'Error', N'sqlEx', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetBlog' AND [ActualMessage] = N'sqlEx';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'Invalid Request.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (70, N'HttpGet api/bl-app/CodeCheckHistory', N'Validation', N'Invalid Request.', N'Invalid Request.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid Request.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'Invalid Request.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'Invalid Consumer ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (71, N'HttpGet api/bl-app/CodeCheckHistory', N'Validation', N'Invalid Consumer ID.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'Invalid Consumer ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'filteredList.Count')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (72, N'HttpGet api/bl-app/CodeCheckHistory', N'Success', N'filteredList.Count', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'filteredList.Count';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'Invalid login details!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (73, N'HttpGet api/bl-app/CodeCheckHistory', N'Validation', N'Invalid login details!', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'Invalid login details!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (74, N'HttpGet api/bl-app/CodeCheckHistory', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/CodeCheckHistory' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (75, N'HttpPost api/bl-app/UpdateMAndMDataorUser', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'Please select a valid User Type.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (76, N'HttpPost api/bl-app/UpdateMAndMDataorUser', N'Validation', N'Please select a valid User Type.', N'Please select a valid User Type.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please select a valid User Type.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'Please select a valid User Type.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'User Updated Successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (77, N'HttpPost api/bl-app/UpdateMAndMDataorUser', N'Success', N'User Updated Successfully.', N'User Updated Successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'User Updated Successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'User Updated Successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'status')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (78, N'HttpPost api/bl-app/UpdateMAndMDataorUser', N'Validation', N'status', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'status';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'No response from database.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (79, N'HttpPost api/bl-app/UpdateMAndMDataorUser', N'Validation', N'No response from database.', N'No response from database.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No response from database.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'No response from database.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (80, N'HttpPost api/bl-app/UpdateMAndMDataorUser', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateMAndMDataorUser' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (81, N'HttpGet api/bl-app/GetNotification', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'Successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (82, N'HttpGet api/bl-app/GetNotification', N'Success', N'Successfully', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'Successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'No records found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (83, N'HttpGet api/bl-app/GetNotification', N'Validation', N'No records found.', N'Nothing to show here yet.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Nothing to show here yet.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'No records found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'User not login!.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (84, N'HttpGet api/bl-app/GetNotification', N'Validation', N'User not login!.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'User not login!.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'Invalid login detail!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (85, N'HttpGet api/bl-app/GetNotification', N'Validation', N'Invalid login detail!', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'Invalid login detail!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (86, N'HttpGet api/bl-app/GetNotification', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetNotification' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'Invalid request. ''CompId'' is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (87, N'HttpGet api/bl-app/GetTopPerformer', N'Validation', N'Invalid request. ''CompId'' is required.', N'Invalid request. ''brand details'' is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid request. ''brand details'' is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'Invalid request. ''CompId'' is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'No top performers found for the provided company.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (88, N'HttpGet api/bl-app/GetTopPerformer', N'Validation', N'No top performers found for the provided company.', N'No top performers found for the provided company.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No top performers found for the provided company.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'No top performers found for the provided company.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'Top performers retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (89, N'HttpGet api/bl-app/GetTopPerformer', N'Success', N'Top performers retrieved successfully.', N'Top performers retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Top performers retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'Top performers retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'An internal server error occurred.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (90, N'HttpGet api/bl-app/GetTopPerformer', N'Error', N'An internal server error occurred.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetTopPerformer' AND [ActualMessage] = N'An internal server error occurred.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Request data or profile picture is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (91, N'HttpPost api/bl-app/UpdateProfilePic', N'Validation', N'Request data or profile picture is null.', N'Request data or profile picture is null.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Request data or profile picture is null.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Request data or profile picture is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'The uploaded file is empty.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (92, N'HttpPost api/bl-app/UpdateProfilePic', N'Validation', N'The uploaded file is empty.', N'The uploaded file is empty.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'The uploaded file is empty.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'The uploaded file is empty.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'File size exceeds the maximum allowed size of 5MB.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (93, N'HttpPost api/bl-app/UpdateProfilePic', N'Validation', N'File size exceeds the maximum allowed size of 5MB.', N'File size exceeds the maximum allowed size of 5MB.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'File size exceeds the maximum allowed size of 5MB.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'File size exceeds the maximum allowed size of 5MB.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Invalid file type. Only .jpg, .jpeg, .png, and .gif are allowed.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (94, N'HttpPost api/bl-app/UpdateProfilePic', N'Validation', N'Invalid file type. Only .jpg, .jpeg, .png, and .gif are allowed.', N'Invalid file type. Only .jpg, .jpeg, .png, and .gif are allowed.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid file type. Only .jpg, .jpeg, .png, and .gif are allowed.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Invalid file type. Only .jpg, .jpeg, .png, and .gif are allowed.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Invalid User Details')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (95, N'HttpPost api/bl-app/UpdateProfilePic', N'Validation', N'Invalid User Details', N'Invalid User Details', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid User Details', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Invalid User Details';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Failed to update profile picture in the database.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (96, N'HttpPost api/bl-app/UpdateProfilePic', N'Error', N'Failed to update profile picture in the database.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Failed to update profile picture in the database.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Profile picture updated successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (97, N'HttpPost api/bl-app/UpdateProfilePic', N'Success', N'Profile picture updated successfully.', N'Profile photo updated successfully!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Profile photo updated successfully!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'Profile picture updated successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (98, N'HttpPost api/bl-app/UpdateProfilePic', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfilePic' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Request data or invoice file is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (99, N'HttpPost api/bl-app/UploadInvoice', N'Validation', N'Request data or invoice file is null.', N'Request data or invoice file is null.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Request data or invoice file is null.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Request data or invoice file is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'validationResult.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (100, N'HttpPost api/bl-app/UploadInvoice', N'Validation', N'validationResult.message', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'validationResult.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Invoice percentage not configured for this company. Please configure it in app settings.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (101, N'HttpPost api/bl-app/UploadInvoice', N'Validation', N'Invoice percentage not configured for this company. Please configure it in app settings.', N'Invoice percentage not configured for this company. Please configure it in app settings.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invoice percentage not configured for this company. Please configure it in app settings.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Invoice percentage not configured for this company. Please configure it in app settings.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Failed to save invoice record in the database.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (102, N'HttpPost api/bl-app/UploadInvoice', N'Error', N'Failed to save invoice record in the database.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Failed to save invoice record in the database.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Invoice uploaded and processed successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (103, N'HttpPost api/bl-app/UploadInvoice', N'Success', N'Invoice uploaded and processed successfully.', N'Invoice uploaded successfully! We''ll take it from here.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Invoice uploaded successfully! We''ll take it from here.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'Invoice uploaded and processed successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (104, N'HttpPost api/bl-app/UploadInvoice', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UploadInvoice' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPoints' AND [ActualMessage] = N'FALSE')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (105, N'HttpPost api/bl-app/TransferPoints', N'Success', N'FALSE', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPoints' AND [ActualMessage] = N'FALSE';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPoints' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (106, N'HttpPost api/bl-app/TransferPoints', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPoints' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/get-child-users/{userId}/{Comp_id}' AND [ActualMessage] = N'Users details fetched successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (107, N'HttpGet api/bl-app/get-child-users/{userId}/{Comp_id}', N'Success', N'Users details fetched successfully', N'Users details fetched successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Users details fetched successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/get-child-users/{userId}/{Comp_id}' AND [ActualMessage] = N'Users details fetched successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetPointTransferHistory' AND [ActualMessage] = N'Transfer history retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (108, N'HttpGet api/bl-app/GetPointTransferHistory', N'Success', N'Transfer history retrieved successfully.', N'Transfer history retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Transfer history retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetPointTransferHistory' AND [ActualMessage] = N'Transfer history retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (109, N'HttpGet api/bl-app/Userwisesettings', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Invalid company ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (110, N'HttpGet api/bl-app/Userwisesettings', N'Validation', N'Invalid company ID.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Invalid company ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Successfully fetched user settings.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (111, N'HttpGet api/bl-app/Userwisesettings', N'Success', N'Successfully fetched user settings.', N'Successfully fetched user settings.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Successfully fetched user settings.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Successfully fetched user settings.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Error occurred while processing the request.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (112, N'HttpGet api/bl-app/Userwisesettings', N'Error', N'Error occurred while processing the request.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Userwisesettings' AND [ActualMessage] = N'Error occurred while processing the request.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/GetOrders' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (113, N'HttpPost api/bl-app/GetOrders', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/GetOrders' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/GetCreditHistory' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (114, N'HttpPost api/bl-app/GetCreditHistory', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/GetCreditHistory' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/GetUserAddresses' AND [ActualMessage] = N'No standard response messages found')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (115, N'HttpPost api/bl-app/GetUserAddresses', N'None / Custom Return', N'No standard response messages found', N'No standard response messages found', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'None / Custom Return', [RecommendedEnglish] = N'No standard response messages found', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/GetUserAddresses' AND [ActualMessage] = N'No standard response messages found';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'Comp_id is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (116, N'HttpPost api/bl-app/PancardVerify', N'Validation', N'Comp_id is required.', N'brand details is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'brand details is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'Comp_id is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'M_Consumerid is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (117, N'HttpPost api/bl-app/PancardVerify', N'Validation', N'M_Consumerid is required.', N'user details is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'user details is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'M_Consumerid is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'You have already completed PAN verification.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (118, N'HttpPost api/bl-app/PancardVerify', N'Validation', N'You have already completed PAN verification.', N'You have already completed PAN verification.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'You have already completed PAN verification.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'You have already completed PAN verification.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (119, N'HttpPost api/bl-app/PancardVerify', N'Validation', N'', N'This PAN is already linked to another mobile number:', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'This PAN is already linked to another mobile number:', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'Invalid M Consumerid. Please logout and login again in the app!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (120, N'HttpPost api/bl-app/PancardVerify', N'Validation', N'Invalid M Consumerid. Please logout and login again in the app!', N'Invalid user details. Please logout and login again in the app!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid user details. Please logout and login again in the app!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'Invalid M Consumerid. Please logout and login again in the app!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'verifyKycDetails.PanRemarks ??')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (121, N'HttpPost api/bl-app/PancardVerify', N'Validation', N'verifyKycDetails.PanRemarks ??', N'verifyKycDetails.PanRemarks ??', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'verifyKycDetails.PanRemarks ??', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'verifyKycDetails.PanRemarks ??';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'Successfully verified PAN card.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (122, N'HttpPost api/bl-app/PancardVerify', N'Success', N'Successfully verified PAN card.', N'Successfully verified PAN card.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Successfully verified PAN card.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'Successfully verified PAN card.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (123, N'HttpPost api/bl-app/PancardVerify', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/PancardVerify' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'Consumer data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (124, N'HttpPost api/bl-app/UpdateProfile', N'Validation', N'Consumer data is null.', N'Consumer data is null.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Consumer data is null.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'Consumer data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'âœ… Your profile has been updated successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (125, N'HttpPost api/bl-app/UpdateProfile', N'Success', N'âœ… Your profile has been updated successfully.', N'âœ… Your profile has been updated successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'âœ… Your profile has been updated successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'âœ… Your profile has been updated successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'Invalid Consumer Details.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (126, N'HttpPost api/bl-app/UpdateProfile', N'Validation', N'Invalid Consumer Details.', N'Invalid Consumer Details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid Consumer Details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'Invalid Consumer Details.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (127, N'HttpPost api/bl-app/UpdateProfile', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UpdateProfile' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/DeleteFromCart' AND [ActualMessage] = N'Items removed from cart successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (128, N'HttpGet api/bl-app/DeleteFromCart', N'Success', N'Items removed from cart successfully.', N'Items removed from cart successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Items removed from cart successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/DeleteFromCart' AND [ActualMessage] = N'Items removed from cart successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/DeleteFromCart' AND [ActualMessage] = N'Error deleting cart items:')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (129, N'HttpGet api/bl-app/DeleteFromCart', N'Success', N'Error deleting cart items:', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/DeleteFromCart' AND [ActualMessage] = N'Error deleting cart items:';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'This code could not be verified. Please check the 13-digit code and try again.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (130, N'HttpPost api/bl-app/Verifycoupon', N'Success', N'This code could not be verified. Please check the 13-digit code and try again.', N'We couldn''t verify this code. Please check the 13-digit code and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'We couldn''t verify this code. Please check the 13-digit code and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'This code could not be verified. Please check the 13-digit code and try again.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Coupon code is null. Please provide a valid coupon code.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (131, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Coupon code is null. Please provide a valid coupon code.', N'Please enter or scan your 13-digit code.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter or scan your 13-digit code.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Coupon code is null. Please provide a valid coupon code.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'The coupon code must be exactly 13 digits long and contain only numbers. Please enter a valid code.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (132, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'The coupon code must be exactly 13 digits long and contain only numbers. Please enter a valid code.', N'Please enter a valid 13-digit numeric code.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 13-digit numeric code.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'The coupon code must be exactly 13 digits long and contain only numbers. Please enter a valid code.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Entered mobile number is invalid. Kindly enter a valid mobile number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (133, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Entered mobile number is invalid. Kindly enter a valid mobile number.', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Entered mobile number is invalid. Kindly enter a valid mobile number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Please complete bank kyc')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (134, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Please complete bank kyc', N'Complete your Bank KYC to continue.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Complete your Bank KYC to continue.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Please complete bank kyc';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'This code is not for this company. Please switch to the original company, {displayCompName}.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (135, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'This code is not for this company. Please switch to the original company, {displayCompName}.', N'This code is not for this company. Please switch to the original company, {displayCompName}.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'This code is not for this company. Please switch to the original company, {displayCompName}.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'This code is not for this company. Please switch to the original company, {displayCompName}.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Please complete your KYC to proceed.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (136, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Please complete your KYC to proceed.', N'Complete your KYC to continue and claim rewards.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Complete your KYC to continue and claim rewards.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Please complete your KYC to proceed.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Complete your PAN KYC to continue and earn rewards.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (137, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Complete your PAN KYC to continue and earn rewards.', N'Verify your PAN to continue earning and claiming rewards.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Verify your PAN to continue earning and claiming rewards.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Complete your PAN KYC to continue and earn rewards.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Complete your Bank KYC to continue and earn rewards.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (138, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Complete your Bank KYC to continue and earn rewards.', N'Verify your bank account to continue and claim rewards.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Verify your bank account to continue and claim rewards.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Complete your Bank KYC to continue and earn rewards.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Please complete your UPI KYC to proceed with code verification.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (139, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Please complete your UPI KYC to proceed with code verification.', N'Verify your UPI ID to continue with code verification.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Verify your UPI ID to continue with code verification.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Please complete your UPI KYC to proceed with code verification.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'KYC details not found. Please complete your profile KYC to proceed.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (140, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'KYC details not found. Please complete your profile KYC to proceed.', N'Complete your profile KYC to continue.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Complete your profile KYC to continue.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'KYC details not found. Please complete your profile KYC to proceed.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'await')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (141, N'HttpPost api/bl-app/Verifycoupon', N'Success', N'await', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'await';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Results')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (142, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Results', N'Results', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Results', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Results';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Unauthorized user type for this code.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (143, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Unauthorized user type for this code.', N'Unauthorized user type for this code.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Unauthorized user type for this code.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Unauthorized user type for this code.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'You are not eligible to check the code because you have reached the financial year earning limit of Rs 19999.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (144, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'You are not eligible to check the code because you have reached the financial year earning limit of Rs 19999.', N'You are not eligible to check the code because you have reached the financial year earning limit of Rs 19999.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'You are not eligible to check the code because you have reached the financial year earning limit of Rs 19999.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'You are not eligible to check the code because you have reached the financial year earning limit of Rs 19999.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Something went wrong! Please check your report or contact service provider.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (145, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'Something went wrong! Please check your report or contact service provider.', N'Something went wrong! Please check your report or contact service provider.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Something went wrong! Please check your report or contact service provider.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Something went wrong! Please check your report or contact service provider.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'resultdatamsg.Message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (146, N'HttpPost api/bl-app/Verifycoupon', N'Success', N'resultdatamsg.Message', N'resultdatamsg.Message', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'resultdatamsg.Message', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'resultdatamsg.Message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Better Luck Next Time')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (147, N'HttpPost api/bl-app/Verifycoupon', N'Success', N'Better Luck Next Time', N'No reward this time. Keep scanningâ€”your next one could be lucky!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'No reward this time. Keep scanningâ€”your next one could be lucky!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Better Luck Next Time';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'responseMessage')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (148, N'HttpPost api/bl-app/Verifycoupon', N'Validation', N'responseMessage', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'responseMessage';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'responseMessage')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (149, N'HttpPost api/bl-app/Verifycoupon', N'Success', N'responseMessage', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'responseMessage';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Internal server error.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (150, N'HttpPost api/bl-app/Verifycoupon', N'Error', N'Internal server error.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/Verifycoupon' AND [ActualMessage] = N'Internal server error.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'This UPI ID is already linked to another account.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (151, N'HttpPost api/bl-app/UPI_verification', N'Validation', N'This UPI ID is already linked to another account.', N'This UPI ID is already linked to another account.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'This UPI ID is already linked to another account.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'This UPI ID is already linked to another account.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Invalid M Consumerid. please provide valid data!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (152, N'HttpPost api/bl-app/UPI_verification', N'Validation', N'Invalid M Consumerid. please provide valid data!', N'Invalid user details. please provide valid data!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid user details. please provide valid data!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Invalid M Consumerid. please provide valid data!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'jOBJ.TryGetProperty')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (153, N'HttpPost api/bl-app/UPI_verification', N'Success', N'jOBJ.TryGetProperty', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'jOBJ.TryGetProperty';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Updated Successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (154, N'HttpPost api/bl-app/UPI_verification', N'Success', N'Updated Successfully', N'Updated Successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Updated Successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Updated Successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Your Name is not matched with your UPI')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (155, N'HttpPost api/bl-app/UPI_verification', N'Validation', N'Your Name is not matched with your UPI', N'Your Name is not matched with your UPI', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your Name is not matched with your UPI', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Your Name is not matched with your UPI';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'KYC Validate Successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (156, N'HttpPost api/bl-app/UPI_verification', N'Success', N'KYC Validate Successfully', N'KYC Validate Successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'KYC Validate Successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'KYC Validate Successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'We couldn''t verify your UPI ID. Please check and try again.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (157, N'HttpPost api/bl-app/UPI_verification', N'Validation', N'We couldn''t verify your UPI ID. Please check and try again.', N'We couldn''t verify your UPI ID. Please check and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t verify your UPI ID. Please check and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'We couldn''t verify your UPI ID. Please check and try again.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Internal server error.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (158, N'HttpPost api/bl-app/UPI_verification', N'Error', N'Internal server error.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/UPI_verification' AND [ActualMessage] = N'Internal server error.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (159, N'HttpGet api/bl-app/Banner', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'Successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (160, N'HttpGet api/bl-app/Banner', N'Success', N'Successfully', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'Successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'No records found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (161, N'HttpGet api/bl-app/Banner', N'Validation', N'No records found.', N'Nothing to show here yet.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Nothing to show here yet.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'No records found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'Invalid login detail!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (162, N'HttpGet api/bl-app/Banner', N'Validation', N'Invalid login detail!', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'Invalid login detail!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (163, N'HttpGet api/bl-app/Banner', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Banner' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (164, N'HttpGet api/bl-app/Brochure', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'Successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (165, N'HttpGet api/bl-app/Brochure', N'Success', N'Successfully', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'Successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'Invalid login detail!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (166, N'HttpGet api/bl-app/Brochure', N'Validation', N'Invalid login detail!', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'Invalid login detail!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (167, N'HttpGet api/bl-app/Brochure', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Brochure' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (168, N'HttpGet api/bl-app/Profiledetails', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Mobile number or Company ID is missing.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (169, N'HttpGet api/bl-app/Profiledetails', N'Validation', N'Mobile number or Company ID is missing.', N'Mobile number or Company ID is missing.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Mobile number or Company ID is missing.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Mobile number or Company ID is missing.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Invalid Mobile Number')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (170, N'HttpGet api/bl-app/Profiledetails', N'Validation', N'Invalid Mobile Number', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Invalid Mobile Number';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Data Retrieved Successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (171, N'HttpGet api/bl-app/Profiledetails', N'Success', N'Data Retrieved Successfully', N'Data Retrieved Successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Data Retrieved Successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Data Retrieved Successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Invalid User Details')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (172, N'HttpGet api/bl-app/Profiledetails', N'Validation', N'Invalid User Details', N'Invalid User Details', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid User Details', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Invalid User Details';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Internal server error.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (173, N'HttpGet api/bl-app/Profiledetails', N'Error', N'Internal server error.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetails' AND [ActualMessage] = N'Internal server error.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Consumer data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (174, N'HttpGet api/bl-app/Profiledetailswithdata', N'Validation', N'Consumer data is null.', N'Consumer data is null.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Consumer data is null.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Consumer data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Mobile number or Company ID is missing.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (175, N'HttpGet api/bl-app/Profiledetailswithdata', N'Validation', N'Mobile number or Company ID is missing.', N'Mobile number or Company ID is missing.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Mobile number or Company ID is missing.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Mobile number or Company ID is missing.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Invalid Mobile Number')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (176, N'HttpGet api/bl-app/Profiledetailswithdata', N'Validation', N'Invalid Mobile Number', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Invalid Mobile Number';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Consumer data processed successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (177, N'HttpGet api/bl-app/Profiledetailswithdata', N'Success', N'Consumer data processed successfully', N'Consumer data processed successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Consumer data processed successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Consumer data processed successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Brand settings not found')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (178, N'HttpGet api/bl-app/Profiledetailswithdata', N'Validation', N'Brand settings not found', N'Brand settings not found', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Brand settings not found', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'Brand settings not found';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (179, N'HttpGet api/bl-app/Profiledetailswithdata', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Profiledetailswithdata' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (180, N'HttpGet api/bl-app/Dashboard', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Invalid company ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (181, N'HttpGet api/bl-app/Dashboard', N'Validation', N'Invalid company ID.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Invalid company ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Record not available.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (182, N'HttpGet api/bl-app/Dashboard', N'Validation', N'Record not available.', N'No information is available right now.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No information is available right now.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Record not available.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Successfully fetched dashboard data.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (183, N'HttpGet api/bl-app/Dashboard', N'Success', N'Successfully fetched dashboard data.', N'Successfully fetched dashboard data.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Successfully fetched dashboard data.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'Successfully fetched dashboard data.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (184, N'HttpGet api/bl-app/Dashboard', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/Dashboard' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (185, N'HttpGet api/bl-app/MultiuserRegistrationfiels', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'Data fetched successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (186, N'HttpGet api/bl-app/MultiuserRegistrationfiels', N'Success', N'Data fetched successfully', N'Data fetched successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Data fetched successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'Data fetched successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'No records found for the given Company ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (187, N'HttpGet api/bl-app/MultiuserRegistrationfiels', N'Validation', N'No records found for the given Company ID.', N'No records found for the given Company ID.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No records found for the given Company ID.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'No records found for the given Company ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (188, N'HttpGet api/bl-app/MultiuserRegistrationfiels', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/MultiuserRegistrationfiels' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'Consumer data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (189, N'HttpPost api/bl-app/RegisterMultiuser', N'Validation', N'Consumer data is null.', N'Consumer data is null.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Consumer data is null.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'Consumer data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'User is not allowed to add the requested user type.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (190, N'HttpPost api/bl-app/RegisterMultiuser', N'Validation', N'User is not allowed to add the requested user type.', N'User is not allowed to add the requested user type.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'User is not allowed to add the requested user type.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'User is not allowed to add the requested user type.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'Mobile number is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (191, N'HttpPost api/bl-app/RegisterMultiuser', N'Validation', N'Mobile number is required.', N'Mobile number is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Mobile number is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'Mobile number is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'dtMsg.Rows')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (192, N'HttpPost api/bl-app/RegisterMultiuser', N'Success', N'dtMsg.Rows', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'dtMsg.Rows';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'msg')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (193, N'HttpPost api/bl-app/RegisterMultiuser', N'Validation', N'msg', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'msg';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'Consumer already exists.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (194, N'HttpPost api/bl-app/RegisterMultiuser', N'Validation', N'Consumer already exists.', N'Consumer already exists.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Consumer already exists.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'Consumer already exists.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (195, N'HttpPost api/bl-app/RegisterMultiuser', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/RegisterMultiuser' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (196, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Invalid M Consumerid or Please try to login again!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (197, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Invalid M Consumerid or Please try to login again!', N'Invalid user details or Please try to login again!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid user details or Please try to login again!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Invalid M Consumerid or Please try to login again!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Req.AccountNo +')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (198, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Req.AccountNo +', N'Req.AccountNo +', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Req.AccountNo +', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Req.AccountNo +';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Please enter correct account number!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (199, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Please enter correct account number!', N'Please enter correct account number!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter correct account number!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Please enter correct account number!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Please enter a valid IFSC code.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (200, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Please enter a valid IFSC code.', N'Please enter a valid IFSC code.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid IFSC code.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Please enter a valid IFSC code.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Invalid ifsc code kindly enter valid ifsc code')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (201, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Invalid ifsc code kindly enter valid ifsc code', N'Invalid ifsc code kindly enter valid ifsc code', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid ifsc code kindly enter valid ifsc code', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Invalid ifsc code kindly enter valid ifsc code';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Payments cannot be processed to this bank. Please provide another bank account.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (202, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Payments cannot be processed to this bank. Please provide another bank account.', N'Payments cannot be processed to this bank. Please provide another bank account.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Payments cannot be processed to this bank. Please provide another bank account.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Payments cannot be processed to this bank. Please provide another bank account.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Api response issue, please wait and try some time later!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (203, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Api response issue, please wait and try some time later!', N'Api response issue, please wait and try some time later!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Api response issue, please wait and try some time later!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Api response issue, please wait and try some time later!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'We couldn''t verify the bank account details entered. Please check and try again.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (204, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'We couldn''t verify the bank account details entered. Please check and try again.', N'We couldn''t verify the bank account details entered. Please check and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t verify the bank account details entered. Please check and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'We couldn''t verify the bank account details entered. Please check and try again.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Multiple Records Found')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (205, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Multiple Records Found', N'Multiple Records Found', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Multiple Records Found', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Multiple Records Found';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Partial Record Found!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (206, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Partial Record Found!', N'Partial Record Found!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Partial Record Found!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Partial Record Found!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Invalid account number!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (207, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Invalid account number!', N'Invalid account number!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid account number!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Invalid account number!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'These bank details have already been submitted for verification.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (208, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'These bank details have already been submitted for verification.', N'These bank details have already been submitted for verification.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'These bank details have already been submitted for verification.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'These bank details have already been submitted for verification.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Server Down!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (209, N'HttpPost api/bl-app/BankAccountVerification', N'Error', N'Server Down!', N'Our service is temporarily unavailable. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Our service is temporarily unavailable. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Server Down!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Unknown Error!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (210, N'HttpPost api/bl-app/BankAccountVerification', N'Error', N'Unknown Error!', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Unknown Error!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Something went wrong, Please contact to service provider!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (211, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Something went wrong, Please contact to service provider!', N'Something went wrong, Please contact to service provider!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Something went wrong, Please contact to service provider!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Something went wrong, Please contact to service provider!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Api Amount Issue')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (212, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Api Amount Issue', N'Api Amount Issue', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Api Amount Issue', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Api Amount Issue';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Entered bank details are not matched with registered name')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (213, N'HttpPost api/bl-app/BankAccountVerification', N'Validation', N'Entered bank details are not matched with registered name', N'Entered bank details are not matched with registered name', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Entered bank details are not matched with registered name', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Entered bank details are not matched with registered name';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Verified successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (214, N'HttpPost api/bl-app/BankAccountVerification', N'Success', N'Verified successfully', N'Verified successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Verified successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Verified successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Verified successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (215, N'HttpPost api/bl-app/BankAccountVerification', N'Success', N'Verified successfully.', N'Verified successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Verified successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'Verified successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (216, N'HttpPost api/bl-app/BankAccountVerification', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/BankAccountVerification' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (217, N'HttpGet api/bl-app/GistMultiuser', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Company settings not found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (218, N'HttpGet api/bl-app/GistMultiuser', N'Validation', N'Company settings not found.', N'Company settings not found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Company settings not found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Company settings not found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your gifts are!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (219, N'HttpGet api/bl-app/GistMultiuser', N'Success', N'Your gifts are!', N'Your gifts are!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your gifts are!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your gifts are!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your UPI details are!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (220, N'HttpGet api/bl-app/GistMultiuser', N'Success', N'Your UPI details are!', N'Your UPI details are!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your UPI details are!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your UPI details are!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your Cash details are!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (221, N'HttpGet api/bl-app/GistMultiuser', N'Success', N'Your Cash details are!', N'Your Cash details are!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your Cash details are!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your Cash details are!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your Bank details are!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (222, N'HttpGet api/bl-app/GistMultiuser', N'Success', N'Your Bank details are!', N'Your Bank details are!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your Bank details are!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Your Bank details are!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Service not assigned. Please contact the administrator.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (223, N'HttpGet api/bl-app/GistMultiuser', N'Validation', N'Service not assigned. Please contact the administrator.', N'Service not assigned. Please contact the administrator.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Service not assigned. Please contact the administrator.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Service not assigned. Please contact the administrator.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'User not logged in.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (224, N'HttpGet api/bl-app/GistMultiuser', N'Validation', N'User not logged in.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'User not logged in.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Invalid login details.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (225, N'HttpGet api/bl-app/GistMultiuser', N'Validation', N'Invalid login details.', N'Invalid login details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid login details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'Invalid login details.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (226, N'HttpGet api/bl-app/GistMultiuser', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GistMultiuser' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (227, N'HttpGet api/bl-app/GiftList', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Invalid login details.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (228, N'HttpGet api/bl-app/GiftList', N'Validation', N'Invalid login details.', N'Invalid login details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid login details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Invalid login details.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'User not found or deleted.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (229, N'HttpGet api/bl-app/GiftList', N'Validation', N'User not found or deleted.', N'User not found or deleted.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'User not found or deleted.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'User not found or deleted.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'No gift details found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (230, N'HttpGet api/bl-app/GiftList', N'Validation', N'No gift details found.', N'No gift details found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No gift details found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'No gift details found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'You don''t have enough points to redeem this reward.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (231, N'HttpGet api/bl-app/GiftList', N'Validation', N'You don''t have enough points to redeem this reward.', N'You need more points for this reward. Keep earning!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'You need more points for this reward. Keep earning!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'You don''t have enough points to redeem this reward.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'new')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (232, N'HttpGet api/bl-app/GiftList', N'Success', N'new', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'new';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'points is not valid')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (233, N'HttpGet api/bl-app/GiftList', N'Validation', N'points is not valid', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'points is not valid';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Your gifts are listed.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (234, N'HttpGet api/bl-app/GiftList', N'Success', N'Your gifts are listed.', N'Your gifts are listed.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your gifts are listed.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Your gifts are listed.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Array.Empty')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (235, N'HttpGet api/bl-app/GiftList', N'Validation', N'Array.Empty', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'Array.Empty';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (236, N'HttpGet api/bl-app/GiftList', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GiftList' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (237, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Claims can be submitted only between {claimDateSetting.StartDay} and {claimDateSetting.EndDay} each month.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (238, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Conditional / Business Logic', N'Claims can be submitted only between {claimDateSetting.StartDay} and {claimDateSetting.EndDay} each month.', N'Claims can be submitted only between {claimDateSetting.StartDay} and {claimDateSetting.EndDay} each month.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Conditional / Business Logic', [RecommendedEnglish] = N'Claims can be submitted only between {claimDateSetting.StartDay} and {claimDateSetting.EndDay} each month.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Claims can be submitted only between {claimDateSetting.StartDay} and {claimDateSetting.EndDay} each month.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your KYC is rejected')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (239, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Your KYC is rejected', N'Your KYC needs attention. Please review the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your KYC needs attention. Please review the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your KYC is rejected';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your KYC is pending')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (240, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Your KYC is pending', N'Your KYC is being verified. We''ll update you once it''s complete.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your KYC is being verified. We''ll update you once it''s complete.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your KYC is pending';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Invalid claim type.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (241, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Invalid claim type.', N'Invalid claim type.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid claim type.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Invalid claim type.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (242, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (243, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'', N'You do not have enough points. Available:', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'You do not have enough points. Available:', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'validation.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (244, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'validation.message', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'validation.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'UPI KYC is not verified.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (245, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'UPI KYC is not verified.', N'Verify your UPI ID before submitting this claim.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Verify your UPI ID before submitting this claim.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'UPI KYC is not verified.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Error creating claim record')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (246, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Error creating claim record', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Error creating claim record';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'dbResultTable.Rows')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (247, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Success', N'dbResultTable.Rows', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'dbResultTable.Rows';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'dbErrorMessage')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (248, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'dbErrorMessage', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'dbErrorMessage';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'bankRemarks')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (249, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'bankRemarks', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'bankRemarks';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (250, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'isHighValue')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (251, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Success', N'isHighValue', N'isHighValue', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'isHighValue', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'isHighValue';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'successMessage')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (252, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Success', N'successMessage', N'successMessage', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'successMessage', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'successMessage';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your bank KYCÂ  is not completed. Please complete it to claim your points.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (253, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Your bank KYCÂ  is not completed. Please complete it to claim your points.', N'Your bank KYCÂ  is not completed. Please complete it to claim your points.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your bank KYCÂ  is not completed. Please complete it to claim your points.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your bank KYCÂ  is not completed. Please complete it to claim your points.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'jdata')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (254, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Success', N'jdata', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'jdata';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your NEFT claim request has been registered and is pending approval.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (255, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Success', N'Your NEFT claim request has been registered and is pending approval.', N'Your cash claim has been submitted and is awaiting approval.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your cash claim has been submitted and is awaiting approval.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your NEFT claim request has been registered and is pending approval.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Gift details not found or inactive.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (256, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Gift details not found or inactive.', N'Gift details not found or inactive.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Gift details not found or inactive.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Gift details not found or inactive.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'You do not have enough points. Required: {pointsToDeduct}, Available: {currentAvailablePoints}')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (257, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'You do not have enough points. Required: {pointsToDeduct}, Available: {currentAvailablePoints}', N'You do not have enough points. Required: {pointsToDeduct}, Available: {currentAvailablePoints}', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'You do not have enough points. Required: {pointsToDeduct}, Available: {currentAvailablePoints}', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'You do not have enough points. Required: {pointsToDeduct}, Available: {currentAvailablePoints}';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your gift claim request has been registered with us.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (258, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Success', N'Your gift claim request has been registered with us.', N'Reward claimed successfully! Track it in Claim History.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Reward claimed successfully! Track it in Claim History.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your gift claim request has been registered with us.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (259, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'', N'Comp-1650:', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Comp-1650:', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (260, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'', N'Comp-1567:', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Comp-1567:', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Error creating claim records')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (261, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Validation', N'Error creating claim records', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Error creating claim records';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your manual claim request has been registered and is pending approval.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (262, N'HttpPost api/bl-app/VendorviseSubmitClaim', N'Success', N'Your manual claim request has been registered and is pending approval.', N'Your claim has been submitted and is awaiting approval.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your claim has been submitted and is awaiting approval.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/VendorviseSubmitClaim' AND [ActualMessage] = N'Your manual claim request has been registered and is pending approval.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/updateUsername' AND [ActualMessage] = N'Request data is invalid.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (263, N'HttpPost api/bl-app/updateUsername', N'Validation', N'Request data is invalid.', N'Request data is invalid.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Request data is invalid.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/updateUsername' AND [ActualMessage] = N'Request data is invalid.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/updateUsername' AND [ActualMessage] = N'User Name Updated successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (264, N'HttpPost api/bl-app/updateUsername', N'Success', N'User Name Updated successfully.', N'User Name Updated successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'User Name Updated successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/updateUsername' AND [ActualMessage] = N'User Name Updated successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/updateUsername' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (265, N'HttpPost api/bl-app/updateUsername', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/updateUsername' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetInvoices' AND [ActualMessage] = N'Invoices retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (266, N'HttpGet api/bl-app/GetInvoices', N'Success', N'Invoices retrieved successfully.', N'Invoices retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Invoices retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetInvoices' AND [ActualMessage] = N'Invoices retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetInvoices' AND [ActualMessage] = N'No invoices found for the provided user.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (267, N'HttpGet api/bl-app/GetInvoices', N'Validation', N'No invoices found for the provided user.', N'No invoices found for the provided user.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No invoices found for the provided user.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetInvoices' AND [ActualMessage] = N'No invoices found for the provided user.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetInvoices' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (268, N'HttpGet api/bl-app/GetInvoices', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetInvoices' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/DuesCheck' AND [ActualMessage] = N'Invoices retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (269, N'HttpGet api/bl-app/DuesCheck', N'Success', N'Invoices retrieved successfully.', N'Invoices retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Invoices retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/DuesCheck' AND [ActualMessage] = N'Invoices retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/DuesCheck' AND [ActualMessage] = N'No invoices found for the provided user.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (270, N'HttpGet api/bl-app/DuesCheck', N'Validation', N'No invoices found for the provided user.', N'No invoices found for the provided user.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No invoices found for the provided user.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/DuesCheck' AND [ActualMessage] = N'No invoices found for the provided user.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/DuesCheck' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (271, N'HttpGet api/bl-app/DuesCheck', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/DuesCheck' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetSubCategories' AND [ActualMessage] = N'SubCategories retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (272, N'HttpGet api/bl-app/GetSubCategories', N'Success', N'SubCategories retrieved successfully.', N'SubCategories retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'SubCategories retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetSubCategories' AND [ActualMessage] = N'SubCategories retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetSubCategories' AND [ActualMessage] = N'No SubCategories found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (273, N'HttpGet api/bl-app/GetSubCategories', N'Validation', N'No SubCategories found.', N'No SubCategories found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No SubCategories found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetSubCategories' AND [ActualMessage] = N'No SubCategories found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetSubCategories' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (274, N'HttpGet api/bl-app/GetSubCategories', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetSubCategories' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDepositHistory' AND [ActualMessage] = N'Deposit history retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (275, N'HttpGet api/bl-app/GetDepositHistory', N'Success', N'Deposit history retrieved successfully.', N'Deposit history retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Deposit history retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDepositHistory' AND [ActualMessage] = N'Deposit history retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDepositHistory' AND [ActualMessage] = N'No deposit history found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (276, N'HttpGet api/bl-app/GetDepositHistory', N'Validation', N'No deposit history found.', N'No deposit history found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No deposit history found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDepositHistory' AND [ActualMessage] = N'No deposit history found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDepositHistory' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (277, N'HttpGet api/bl-app/GetDepositHistory', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDepositHistory' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDealerDocuments' AND [ActualMessage] = N'Dealer documents retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (278, N'HttpGet api/bl-app/GetDealerDocuments', N'Success', N'Dealer documents retrieved successfully.', N'Dealer documents retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Dealer documents retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDealerDocuments' AND [ActualMessage] = N'Dealer documents retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDealerDocuments' AND [ActualMessage] = N'No documents found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (279, N'HttpGet api/bl-app/GetDealerDocuments', N'Validation', N'No documents found.', N'No documents found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No documents found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDealerDocuments' AND [ActualMessage] = N'No documents found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDealerDocuments' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (280, N'HttpGet api/bl-app/GetDealerDocuments', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDealerDocuments' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetRetailerVisits' AND [ActualMessage] = N'Retailer visits fetched successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (281, N'HttpGet api/bl-app/GetRetailerVisits', N'Success', N'Retailer visits fetched successfully.', N'Retailer visits fetched successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Retailer visits fetched successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetRetailerVisits' AND [ActualMessage] = N'Retailer visits fetched successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetRetailerVisits' AND [ActualMessage] = N'No visit records found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (282, N'HttpGet api/bl-app/GetRetailerVisits', N'Validation', N'No visit records found.', N'No visit records found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No visit records found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetRetailerVisits' AND [ActualMessage] = N'No visit records found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetRetailerVisits' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (283, N'HttpGet api/bl-app/GetRetailerVisits', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetRetailerVisits' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/AddRetailerVisit' AND [ActualMessage] = N'Retailer visit saved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (284, N'HttpGet api/bl-app/AddRetailerVisit', N'Success', N'Retailer visit saved successfully.', N'Retailer visit saved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Retailer visit saved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/AddRetailerVisit' AND [ActualMessage] = N'Retailer visit saved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/AddRetailerVisit' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (285, N'HttpGet api/bl-app/AddRetailerVisit', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/AddRetailerVisit' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddTermsAndConditions' AND [ActualMessage] = N'MobileNo and CompId are required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (286, N'HttpPost api/bl-app/AddTermsAndConditions', N'Validation', N'MobileNo and CompId are required.', N'MobileNo and brand details are required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'MobileNo and brand details are required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddTermsAndConditions' AND [ActualMessage] = N'MobileNo and CompId are required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddTermsAndConditions' AND [ActualMessage] = N'Terms and Conditions updated successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (287, N'HttpPost api/bl-app/AddTermsAndConditions', N'Success', N'Terms and Conditions updated successfully.', N'Terms and Conditions updated successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Terms and Conditions updated successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddTermsAndConditions' AND [ActualMessage] = N'Terms and Conditions updated successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddTermsAndConditions' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (288, N'HttpPost api/bl-app/AddTermsAndConditions', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddTermsAndConditions' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SaveApiError' AND [ActualMessage] = N'[FromQuery] string comp_id')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (289, N'HttpPost api/bl-app/SaveApiError', N'Error', N'[FromQuery] string comp_id', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SaveApiError' AND [ActualMessage] = N'[FromQuery] string comp_id';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SaveApiError' AND [ActualMessage] = N'Error logged successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (290, N'HttpPost api/bl-app/SaveApiError', N'Success', N'Error logged successfully.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SaveApiError' AND [ActualMessage] = N'Error logged successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SaveApiError' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (291, N'HttpPost api/bl-app/SaveApiError', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SaveApiError' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'[FromBody] SaveAppErrorRequest req')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (292, N'HttpPost api/bl-app/SaveAppError', N'Error', N'[FromBody] SaveAppErrorRequest req', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'[FromBody] SaveAppErrorRequest req';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (293, N'HttpPost api/bl-app/SaveAppError', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'Error logged successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (294, N'HttpPost api/bl-app/SaveAppError', N'Success', N'Error logged successfully.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'Error logged successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (295, N'HttpPost api/bl-app/SaveAppError', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SaveAppError' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetStarCodeVerificationByMobile' AND [ActualMessage] = N'Transaction details fetched successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (296, N'HttpGet api/bl-app/GetStarCodeVerificationByMobile', N'Success', N'Transaction details fetched successfully.', N'Transaction details fetched successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Transaction details fetched successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetStarCodeVerificationByMobile' AND [ActualMessage] = N'Transaction details fetched successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetStarCodeVerificationByMobile' AND [ActualMessage] = N'No transaction found for this mobile number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (297, N'HttpGet api/bl-app/GetStarCodeVerificationByMobile', N'Validation', N'No transaction found for this mobile number.', N'No transaction found for this mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No transaction found for this mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetStarCodeVerificationByMobile' AND [ActualMessage] = N'No transaction found for this mobile number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetStarCodeVerificationByMobile' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (298, N'HttpGet api/bl-app/GetStarCodeVerificationByMobile', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetStarCodeVerificationByMobile' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (299, N'HttpGet api/bl-app/GetUpiByMobile', N'Validation', N'', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'InstantPay API Error: {Error}')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (300, N'HttpGet api/bl-app/GetUpiByMobile', N'Error', N'InstantPay API Error: {Error}', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'InstantPay API Error: {Error}';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'UPI details lookup successful.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (301, N'HttpGet api/bl-app/GetUpiByMobile', N'Success', N'UPI details lookup successful.', N'UPI details lookup successful.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'UPI details lookup successful.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'UPI details lookup successful.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (302, N'HttpGet api/bl-app/GetUpiByMobile', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUpiByMobile' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Invalid mobile number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (303, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Validation', N'Invalid mobile number.', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Invalid mobile number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Payments cannot be processed to this bank. Please provide another bank account.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (304, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Validation', N'Payments cannot be processed to this bank. Please provide another bank account.', N'Payments cannot be processed to this bank. Please provide another bank account.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Payments cannot be processed to this bank. Please provide another bank account.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Payments cannot be processed to this bank. Please provide another bank account.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Account details retrieved successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (305, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Success', N'Account details retrieved successfully', N'Account details retrieved successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Account details retrieved successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Account details retrieved successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Tutelar API configuration is missing.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (306, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Validation', N'Tutelar API configuration is missing.', N'Tutelar API configuration is missing.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Tutelar API configuration is missing.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Tutelar API configuration is missing.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Tutelar API Error: {Error}')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (307, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Error', N'Tutelar API Error: {Error}', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Tutelar API Error: {Error}';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Unable to complete your request. Please try again later.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (308, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Success', N'Unable to complete your request. Please try again later.', N'Unable to complete your request. Please try again later.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Unable to complete your request. Please try again later.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Unable to complete your request. Please try again later.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Request in progress.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (309, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Success', N'Request in progress.', N'Request in progress.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Request in progress.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Request in progress.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Valid account details not found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (310, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Validation', N'Valid account details not found.', N'Valid account details not found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Valid account details not found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Valid account details not found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Failed to fetch account details:')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (311, N'HttpGet api/bl-app/GetAccountDetailsByMobile', N'Error', N'Failed to fetch account details:', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetAccountDetailsByMobile' AND [ActualMessage] = N'Failed to fetch account details:';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'M_Consumerid and CompId are required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (312, N'HttpGet api/bl-app/GetUserClaimPreference', N'Validation', N'M_Consumerid and CompId are required.', N'user details and brand details are required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'user details and brand details are required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'M_Consumerid and CompId are required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'User claim preference fetched successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (313, N'HttpGet api/bl-app/GetUserClaimPreference', N'Success', N'User claim preference fetched successfully.', N'User claim preference fetched successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'User claim preference fetched successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'User claim preference fetched successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'No claim preference found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (314, N'HttpGet api/bl-app/GetUserClaimPreference', N'Validation', N'No claim preference found.', N'No claim preference found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No claim preference found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'No claim preference found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (315, N'HttpGet api/bl-app/GetUserClaimPreference', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUserClaimPreference' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddUserClaimPreference' AND [ActualMessage] = N'M_Consumerid, CompId and ClaimMode are required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (316, N'HttpPost api/bl-app/AddUserClaimPreference', N'Validation', N'M_Consumerid, CompId and ClaimMode are required.', N'user details, brand details and ClaimMode are required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'user details, brand details and ClaimMode are required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddUserClaimPreference' AND [ActualMessage] = N'M_Consumerid, CompId and ClaimMode are required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddUserClaimPreference' AND [ActualMessage] = N'User claim preference saved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (317, N'HttpPost api/bl-app/AddUserClaimPreference', N'Success', N'User claim preference saved successfully.', N'User claim preference saved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'User claim preference saved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddUserClaimPreference' AND [ActualMessage] = N'User claim preference saved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddUserClaimPreference' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (318, N'HttpPost api/bl-app/AddUserClaimPreference', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddUserClaimPreference' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDuesDetails' AND [ActualMessage] = N'Dues details retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (319, N'HttpGet api/bl-app/GetDuesDetails', N'Success', N'Dues details retrieved successfully.', N'Dues details retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Dues details retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDuesDetails' AND [ActualMessage] = N'Dues details retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDuesDetails' AND [ActualMessage] = N'No dues found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (320, N'HttpGet api/bl-app/GetDuesDetails', N'Validation', N'No dues found.', N'No dues found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No dues found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDuesDetails' AND [ActualMessage] = N'No dues found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetDuesDetails' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (321, N'HttpGet api/bl-app/GetDuesDetails', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetDuesDetails' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (322, N'HttpPost api/bl-app/ApiClaimHistory', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'row')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (323, N'HttpPost api/bl-app/ApiClaimHistory', N'Success', N'row', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'row';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'Your Claim History is here.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (324, N'HttpPost api/bl-app/ApiClaimHistory', N'Success', N'Your Claim History is here.', N'Your Claim History is here.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your Claim History is here.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'Your Claim History is here.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'No claim history found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (325, N'HttpPost api/bl-app/ApiClaimHistory', N'Validation', N'No claim history found.', N'No claim history found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No claim history found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'No claim history found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'No Record found!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (326, N'HttpPost api/bl-app/ApiClaimHistory', N'Validation', N'No Record found!', N'No Record found!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No Record found!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'No Record found!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'User not logged in!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (327, N'HttpPost api/bl-app/ApiClaimHistory', N'Validation', N'User not logged in!', N'User not logged in!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'User not logged in!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'User not logged in!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'Invalid login detail!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (328, N'HttpPost api/bl-app/ApiClaimHistory', N'Validation', N'Invalid login detail!', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'Invalid login detail!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (329, N'HttpPost api/bl-app/ApiClaimHistory', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistory' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (330, N'HttpPost api/bl-app/ApiClaimHistoryDealer', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'row')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (331, N'HttpPost api/bl-app/ApiClaimHistoryDealer', N'Success', N'row', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'row';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'Your Claim History is here.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (332, N'HttpPost api/bl-app/ApiClaimHistoryDealer', N'Success', N'Your Claim History is here.', N'Your Claim History is here.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Your Claim History is here.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'Your Claim History is here.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'No claim history found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (333, N'HttpPost api/bl-app/ApiClaimHistoryDealer', N'Validation', N'No claim history found.', N'No claim history found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No claim history found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'No claim history found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'User not logged in!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (334, N'HttpPost api/bl-app/ApiClaimHistoryDealer', N'Validation', N'User not logged in!', N'User not logged in!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'User not logged in!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'User not logged in!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'Invalid login detail!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (335, N'HttpPost api/bl-app/ApiClaimHistoryDealer', N'Validation', N'Invalid login detail!', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'Invalid login detail!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (336, N'HttpPost api/bl-app/ApiClaimHistoryDealer', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ApiClaimHistoryDealer' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUserKycDetails' AND [ActualMessage] = N'KYC details fetched successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (337, N'HttpGet api/bl-app/GetUserKycDetails', N'Success', N'KYC details fetched successfully.', N'KYC details fetched successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'KYC details fetched successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUserKycDetails' AND [ActualMessage] = N'KYC details fetched successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUserKycDetails' AND [ActualMessage] = N'No records found for the given M_Consumerid.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (338, N'HttpGet api/bl-app/GetUserKycDetails', N'Validation', N'No records found for the given M_Consumerid.', N'No records found for the given user details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No records found for the given user details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUserKycDetails' AND [ActualMessage] = N'No records found for the given M_Consumerid.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUserKycDetails' AND [ActualMessage] = N'Internal server error occurred.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (339, N'HttpGet api/bl-app/GetUserKycDetails', N'Error', N'Internal server error occurred.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUserKycDetails' AND [ActualMessage] = N'Internal server error occurred.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'Invalid request: ''Comp_id'' and ''M_ConsumerId'' are required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (340, N'HttpGet api/bl-app/GetReferralContents', N'Validation', N'Invalid request: ''Comp_id'' and ''M_ConsumerId'' are required.', N'Invalid request: ''brand details'' and ''user details'' are required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid request: ''brand details'' and ''user details'' are required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'Invalid request: ''Comp_id'' and ''M_ConsumerId'' are required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'No consumer found with the provided M_ConsumerId.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (341, N'HttpGet api/bl-app/GetReferralContents', N'Validation', N'No consumer found with the provided M_ConsumerId.', N'No consumer found with the provided user details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No consumer found with the provided user details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'No consumer found with the provided M_ConsumerId.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'No referral contents found for the provided company.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (342, N'HttpGet api/bl-app/GetReferralContents', N'Validation', N'No referral contents found for the provided company.', N'No referral contents found for the provided company.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No referral contents found for the provided company.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'No referral contents found for the provided company.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'Your referral sharing limit has been exhausted.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (343, N'HttpGet api/bl-app/GetReferralContents', N'Validation', N'Your referral sharing limit has been exhausted.', N'Your referral sharing limit has been exhausted.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your referral sharing limit has been exhausted.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'Your referral sharing limit has been exhausted.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'Referral contents found successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (344, N'HttpGet api/bl-app/GetReferralContents', N'Success', N'Referral contents found successfully.', N'Referral contents found successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Referral contents found successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'Referral contents found successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'An error occurred while processing the request.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (345, N'HttpGet api/bl-app/GetReferralContents', N'Error', N'An error occurred while processing the request.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralContents' AND [ActualMessage] = N'An error occurred while processing the request.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'Invalid request: ''Comp_id'' is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (346, N'HttpGet api/bl-app/GetReferralHistory', N'Validation', N'Invalid request: ''Comp_id'' is required.', N'Invalid request: ''brand details'' is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid request: ''brand details'' is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'Invalid request: ''Comp_id'' is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'Referral details found successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (347, N'HttpGet api/bl-app/GetReferralHistory', N'Success', N'Referral details found successfully.', N'Referral details found successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Referral details found successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'Referral details found successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'No referral details found for the provided user.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (348, N'HttpGet api/bl-app/GetReferralHistory', N'Validation', N'No referral details found for the provided user.', N'No referral details found for the provided user.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No referral details found for the provided user.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'No referral details found for the provided user.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'An error occurred while processing the request.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (349, N'HttpGet api/bl-app/GetReferralHistory', N'Error', N'An error occurred while processing the request.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralHistory' AND [ActualMessage] = N'An error occurred while processing the request.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralReport' AND [ActualMessage] = N'Referral report retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (350, N'HttpGet api/bl-app/GetReferralReport', N'Success', N'Referral report retrieved successfully.', N'Referral report retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Referral report retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetReferralReport' AND [ActualMessage] = N'Referral report retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (351, N'HttpPost api/bl-app/ValidateOTPForMultiuser', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'Please enter a valid mobile number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (352, N'HttpPost api/bl-app/ValidateOTPForMultiuser', N'Validation', N'Please enter a valid mobile number.', N'Please enter a valid 10-digit mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid 10-digit mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'Please enter a valid mobile number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'successMsg')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (353, N'HttpPost api/bl-app/ValidateOTPForMultiuser', N'Success', N'successMsg', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'successMsg';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'User is not exists!.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (354, N'HttpPost api/bl-app/ValidateOTPForMultiuser', N'Success', N'User is not exists!.', N'User is not exists!.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'User is not exists!.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'User is not exists!.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'The OTP entered is incorrect. Please re-enter the correct OTP or request a new one.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (355, N'HttpPost api/bl-app/ValidateOTPForMultiuser', N'Validation', N'The OTP entered is incorrect. Please re-enter the correct OTP or request a new one.', N'Incorrect OTP. Please try again or request a new OTP.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Incorrect OTP. Please try again or request a new OTP.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'The OTP entered is incorrect. Please re-enter the correct OTP or request a new one.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'successMsgNormal')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (356, N'HttpPost api/bl-app/ValidateOTPForMultiuser', N'Success', N'successMsgNormal', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'successMsgNormal';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (357, N'HttpPost api/bl-app/ValidateOTPForMultiuser', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForMultiuser' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Ticket description or category cannot be empty.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (358, N'HttpPost api/bl-app/raise-ticket', N'Validation', N'Ticket description or category cannot be empty.', N'Ticket description or category cannot be empty.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Ticket description or category cannot be empty.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Ticket description or category cannot be empty.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Your previous ticket is still open and under review. Please wait for it to be resolved before raising a new ticket.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (359, N'HttpPost api/bl-app/raise-ticket', N'Validation', N'Your previous ticket is still open and under review. Please wait for it to be resolved before raising a new ticket.', N'Your previous ticket is still open and under review. Please wait for it to be resolved before raising a new ticket.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your previous ticket is still open and under review. Please wait for it to be resolved before raising a new ticket.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Your previous ticket is still open and under review. Please wait for it to be resolved before raising a new ticket.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Error generating Ticket ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (360, N'HttpPost api/bl-app/raise-ticket', N'Validation', N'Error generating Ticket ID.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Error generating Ticket ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'val.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (361, N'HttpPost api/bl-app/raise-ticket', N'Validation', N'val.message', N'val.message', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'val.message', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'val.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Ticket raised successfully!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (362, N'HttpPost api/bl-app/raise-ticket', N'Success', N'Ticket raised successfully!', N'Support request submitted! Track it in Ticket History.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Support request submitted! Track it in Ticket History.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'Ticket raised successfully!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'An error occurred while raising the ticket.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (363, N'HttpPost api/bl-app/raise-ticket', N'Error', N'An error occurred while raising the ticket.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/raise-ticket' AND [ActualMessage] = N'An error occurred while raising the ticket.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'Request cannot be empty.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (364, N'HttpPost api/bl-app/ticket-history', N'Validation', N'Request cannot be empty.', N'Request cannot be empty.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Request cannot be empty.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'Request cannot be empty.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'Ticket history fetched successfully!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (365, N'HttpPost api/bl-app/ticket-history', N'Success', N'Ticket history fetched successfully!', N'Ticket history fetched successfully!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Ticket history fetched successfully!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'Ticket history fetched successfully!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'No ticket details found.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (366, N'HttpPost api/bl-app/ticket-history', N'Validation', N'No ticket details found.', N'No ticket details found.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No ticket details found.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'No ticket details found.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'An error occurred while fetching ticket history.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (367, N'HttpPost api/bl-app/ticket-history', N'Error', N'An error occurred while fetching ticket history.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ticket-history' AND [ActualMessage] = N'An error occurred while fetching ticket history.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'Invalid request data or IFSC code is missing.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (368, N'HttpPost api/bl-app/getbankdetails', N'Validation', N'Invalid request data or IFSC code is missing.', N'Invalid request data or IFSC code is missing.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid request data or IFSC code is missing.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'Invalid request data or IFSC code is missing.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'Bank details fetch successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (369, N'HttpPost api/bl-app/getbankdetails', N'Success', N'Bank details fetch successfully', N'Bank details fetch successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Bank details fetch successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'Bank details fetch successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'Please enter a valid IFSC code.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (370, N'HttpPost api/bl-app/getbankdetails', N'Validation', N'Please enter a valid IFSC code.', N'Please enter a valid IFSC code.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid IFSC code.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'Please enter a valid IFSC code.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (371, N'HttpPost api/bl-app/getbankdetails', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/getbankdetails' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/getuplodedinvoice' AND [ActualMessage] = N'Uploaded invoices retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (372, N'HttpGet api/bl-app/getuplodedinvoice', N'Success', N'Uploaded invoices retrieved successfully.', N'Uploaded invoices retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Uploaded invoices retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/getuplodedinvoice' AND [ActualMessage] = N'Uploaded invoices retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetConsumerInvoices' AND [ActualMessage] = N'Invoices retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (373, N'HttpGet api/bl-app/GetConsumerInvoices', N'Success', N'Invoices retrieved successfully.', N'Invoices retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Invoices retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetConsumerInvoices' AND [ActualMessage] = N'Invoices retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetConsumerInvoices' AND [ActualMessage] = N'Sandbox Authentication Failed: {StatusCode} - {Body}')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (374, N'HttpGet api/bl-app/GetConsumerInvoices', N'Error', N'Sandbox Authentication Failed: {StatusCode} - {Body}', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetConsumerInvoices' AND [ActualMessage] = N'Sandbox Authentication Failed: {StatusCode} - {Body}';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Invalid request body. Please check your JSON format.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (375, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'Invalid request body. Please check your JSON format.', N'Invalid request body. Please check your JSON format.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid request body. Please check your JSON format.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Invalid request body. Please check your JSON format.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Please enter a valid Aadhaar number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (376, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'Please enter a valid Aadhaar number.', N'Please enter a valid Aadhaar number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid Aadhaar number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Please enter a valid Aadhaar number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Invalid consumer ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (377, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'Invalid consumer ID.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Invalid consumer ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Record Not available.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (378, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'Record Not available.', N'No information is available right now.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No information is available right now.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Record Not available.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'KYC already verified.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (379, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'KYC already verified.', N'KYC already verified.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'KYC already verified.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'KYC already verified.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'{req.AadharNo} is already in use, Please try with another!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (380, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'{req.AadharNo} is already in use, Please try with another!', N'{req.AadharNo} is already in use, Please try with another!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'{req.AadharNo} is already in use, Please try with another!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'{req.AadharNo} is already in use, Please try with another!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'You have reached the maximum limit: {reqCount}')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (381, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'You have reached the maximum limit: {reqCount}', N'You have reached the maximum limit: {reqCount}', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'You have reached the maximum limit: {reqCount}', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'You have reached the maximum limit: {reqCount}';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Failed to authenticate with provider.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (382, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Error', N'Failed to authenticate with provider.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'Failed to authenticate with provider.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'OTP sent successfully!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (383, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Success', N'OTP sent successfully!', N'OTP sent successfully!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'OTP sent successfully!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'OTP sent successfully!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'sandboxResponse')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (384, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Success', N'sandboxResponse', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'sandboxResponse';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'errorMsg')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (385, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Validation', N'errorMsg', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'errorMsg';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (386, N'HttpPost api/bl-app/SendOTPForKYCAadhar', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/SendOTPForKYCAadhar' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (387, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Please enter a valid Aadhaar number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (388, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Validation', N'Please enter a valid Aadhaar number.', N'Please enter a valid Aadhaar number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please enter a valid Aadhaar number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Please enter a valid Aadhaar number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Invalid consumer ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (389, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Validation', N'Invalid consumer ID.', N'Your session has expired. Please log in again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Your session has expired. Please log in again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Invalid consumer ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Failed to authenticate with provider.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (390, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Error', N'Failed to authenticate with provider.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Failed to authenticate with provider.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Invalid user details.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (391, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Validation', N'Invalid user details.', N'Invalid user details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid user details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Invalid user details.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Aadhaar name does not match the registered name. Please verify and try again.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (392, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Validation', N'Aadhaar name does not match the registered name. Please verify and try again.', N'Aadhaar name does not match the registered name. Please verify and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Aadhaar name does not match the registered name. Please verify and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Aadhaar name does not match the registered name. Please verify and try again.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Verified successfully!')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (393, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Success', N'Verified successfully!', N'Verified successfully!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Verified successfully!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'Verified successfully!';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'sandboxResponse')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (394, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Success', N'sandboxResponse', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'sandboxResponse';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'errorMsg')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (395, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Validation', N'errorMsg', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'errorMsg';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (396, N'HttpPost api/bl-app/ValidateOTPForKYCAadhar', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ValidateOTPForKYCAadhar' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'Comp_Id is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (397, N'HttpGet api/bl-app/GetMultiCompanySettings', N'Validation', N'Comp_Id is required.', N'brand details is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'brand details is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'Comp_Id is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'No settings found for the specified company ID.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (398, N'HttpGet api/bl-app/GetMultiCompanySettings', N'Validation', N'No settings found for the specified company ID.', N'No settings found for the specified company ID.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No settings found for the specified company ID.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'No settings found for the specified company ID.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'Multi-company settings fetched successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (399, N'HttpGet api/bl-app/GetMultiCompanySettings', N'Success', N'Multi-company settings fetched successfully.', N'Multi-company settings fetched successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Multi-company settings fetched successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'Multi-company settings fetched successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (400, N'HttpGet api/bl-app/GetMultiCompanySettings', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetMultiCompanySettings' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'Request body is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (401, N'HttpPost api/bl-app/CloneVendorMConsumer', N'Validation', N'Request body is required.', N'Request body is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Request body is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'Request body is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'comp_id, subcomp_id, M_Consumerid, and UserType are all required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (402, N'HttpPost api/bl-app/CloneVendorMConsumer', N'Validation', N'comp_id, subcomp_id, M_Consumerid, and UserType are all required.', N'brand details, subcomp_id, user details, and UserType are all required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'brand details, subcomp_id, user details, and UserType are all required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'comp_id, subcomp_id, M_Consumerid, and UserType are all required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'result.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (403, N'HttpPost api/bl-app/CloneVendorMConsumer', N'Success', N'result.message', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'result.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'result.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (404, N'HttpPost api/bl-app/CloneVendorMConsumer', N'Validation', N'result.message', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'result.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (405, N'HttpPost api/bl-app/CloneVendorMConsumer', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CloneVendorMConsumer' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Request data is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (406, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'Request data is required.', N'Request data is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Request data is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Request data is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Coupon code is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (407, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'Coupon code is required.', N'Coupon code is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Coupon code is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Coupon code is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Mobile number is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (408, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'Mobile number is required.', N'Mobile number is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Mobile number is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Mobile number is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (409, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Bill image is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (410, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'Bill image is required.', N'Bill image is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Bill image is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Bill image is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Purchase date is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (411, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'Purchase date is required.', N'Purchase date is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Purchase date is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Purchase date is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Invalid purchase date format.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (412, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'Invalid purchase date format.', N'Invalid purchase date format.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Invalid purchase date format.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Invalid purchase date format.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'billValidation.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (413, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'billValidation.message', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'billValidation.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'cardValidation.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (414, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'cardValidation.message', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'cardValidation.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (415, N'HttpPost api/bl-app/ScanWarrantyCode', N'Success', N'message', N'message', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'message', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'row')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (416, N'HttpPost api/bl-app/ScanWarrantyCode', N'Success', N'row', N'Done successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Done successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'row';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (417, N'HttpPost api/bl-app/ScanWarrantyCode', N'Validation', N'message', N'message', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'message', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Failed to scan warranty code. No response from server.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (418, N'HttpPost api/bl-app/ScanWarrantyCode', N'Error', N'Failed to scan warranty code. No response from server.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'Failed to scan warranty code. No response from server.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (419, N'HttpPost api/bl-app/ScanWarrantyCode', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/ScanWarrantyCode' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (420, N'HttpPost api/bl-app/DeleteUser', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (421, N'HttpPost api/bl-app/DeleteUser', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Mobile number is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (422, N'HttpPost api/bl-app/DeleteUser', N'Validation', N'Mobile number is required.', N'Mobile number is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Mobile number is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Mobile number is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Consumer not found with the specified mobile number.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (423, N'HttpPost api/bl-app/DeleteUser', N'Validation', N'Consumer not found with the specified mobile number.', N'Consumer not found with the specified mobile number.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Consumer not found with the specified mobile number.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'Consumer not found with the specified mobile number.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'No record found for this consumer under the specified company.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (424, N'HttpPost api/bl-app/DeleteUser', N'Validation', N'No record found for this consumer under the specified company.', N'No record found for this consumer under the specified company.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No record found for this consumer under the specified company.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'No record found for this consumer under the specified company.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'User will delete after 30 days from the company.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (425, N'HttpPost api/bl-app/DeleteUser', N'Conditional / Business Logic', N'User will delete after 30 days from the company.', N'User will delete after 30 days from the company.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Conditional / Business Logic', [RecommendedEnglish] = N'User will delete after 30 days from the company.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'User will delete after 30 days from the company.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (426, N'HttpPost api/bl-app/DeleteUser', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/DeleteUser' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (427, N'HttpPost api/bl-app/CancelDeleteMark', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (428, N'HttpPost api/bl-app/CancelDeleteMark', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Either Mobile number or Consumer ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (429, N'HttpPost api/bl-app/CancelDeleteMark', N'Validation', N'Either Mobile number or Consumer ID is required.', N'Either Mobile number or Consumer ID is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Either Mobile number or Consumer ID is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Either Mobile number or Consumer ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Consumer not found with the specified details.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (430, N'HttpPost api/bl-app/CancelDeleteMark', N'Validation', N'Consumer not found with the specified details.', N'Consumer not found with the specified details.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Consumer not found with the specified details.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Consumer not found with the specified details.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'No active delete request found for this consumer.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (431, N'HttpPost api/bl-app/CancelDeleteMark', N'Validation', N'No active delete request found for this consumer.', N'No active delete request found for this consumer.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'No active delete request found for this consumer.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'No active delete request found for this consumer.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Delete request initiated on {entryDate:dd-MMM-yyyy} has been successfully cancelled.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (432, N'HttpPost api/bl-app/CancelDeleteMark', N'Success', N'Delete request initiated on {entryDate:dd-MMM-yyyy} has been successfully cancelled.', N'Delete request initiated on {entryDate:dd-MMM-yyyy} has been successfully cancelled.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Delete request initiated on {entryDate:dd-MMM-yyyy} has been successfully cancelled.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'Delete request initiated on {entryDate:dd-MMM-yyyy} has been successfully cancelled.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (433, N'HttpPost api/bl-app/CancelDeleteMark', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/CancelDeleteMark' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetEwarrantyCodeCheckHistory' AND [ActualMessage] = N'No standard response messages found')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (434, N'HttpGet api/bl-app/GetEwarrantyCodeCheckHistory', N'None / Custom Return', N'No standard response messages found', N'No standard response messages found', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'None / Custom Return', [RecommendedEnglish] = N'No standard response messages found', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetEwarrantyCodeCheckHistory' AND [ActualMessage] = N'No standard response messages found';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (435, N'HttpGet api/bl-app/WarrantyUserHistory', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'M_Consumerid is required and must be greater than 0.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (436, N'HttpGet api/bl-app/WarrantyUserHistory', N'Validation', N'M_Consumerid is required and must be greater than 0.', N'user details is required and must be greater than 0.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'user details is required and must be greater than 0.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'M_Consumerid is required and must be greater than 0.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'result.Message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (437, N'HttpGet api/bl-app/WarrantyUserHistory', N'Error', N'result.Message', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'result.Message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'Failed to retrieve report data.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (438, N'HttpGet api/bl-app/WarrantyUserHistory', N'Error', N'Failed to retrieve report data.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'Failed to retrieve report data.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (439, N'HttpGet api/bl-app/WarrantyUserHistory', N'Error', N'', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/WarrantyUserHistory' AND [ActualMessage] = N'';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (440, N'HttpPost api/bl-app/AddWork', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Mobile number is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (441, N'HttpPost api/bl-app/AddWork', N'Validation', N'Mobile number is required.', N'Mobile number is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Mobile number is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Mobile number is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'validationResult.message')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (442, N'HttpPost api/bl-app/AddWork', N'Validation', N'validationResult.message', N'Please check the details and try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Please check the details and try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'validationResult.message';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Work added successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (443, N'HttpPost api/bl-app/AddWork', N'Success', N'Work added successfully.', N'Work added successfully!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Work added successfully!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Work added successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Failed to add work.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (444, N'HttpPost api/bl-app/AddWork', N'Error', N'Failed to add work.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'Failed to add work.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (445, N'HttpPost api/bl-app/AddWork', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/AddWork' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetHistoryUploadedWork' AND [ActualMessage] = N'Uploaded work history retrieved successfully')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (446, N'HttpGet api/bl-app/GetHistoryUploadedWork', N'Success', N'Uploaded work history retrieved successfully', N'Uploaded work history retrieved successfully', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Uploaded work history retrieved successfully', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetHistoryUploadedWork' AND [ActualMessage] = N'Uploaded work history retrieved successfully';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (447, N'HttpGet api/bl-app/GetUsersByCompIdAndUserType', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'User type is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (448, N'HttpGet api/bl-app/GetUsersByCompIdAndUserType', N'Validation', N'User type is required.', N'User type is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'User type is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'User type is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'Users retrieved successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (449, N'HttpGet api/bl-app/GetUsersByCompIdAndUserType', N'Success', N'Users retrieved successfully.', N'Users retrieved successfully.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Users retrieved successfully.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'Users retrieved successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (450, N'HttpGet api/bl-app/GetUsersByCompIdAndUserType', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetUsersByCompIdAndUserType' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Request data is null.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (451, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'Request data is null.', N'We couldn''t process your request. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t process your request. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Request data is null.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (452, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'User mobile number is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (453, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'User mobile number is required.', N'User mobile number is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'User mobile number is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'User mobile number is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Supervisor mobile number is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (454, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'Supervisor mobile number is required.', N'Supervisor mobile number is required.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Supervisor mobile number is required.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Supervisor mobile number is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Points to transfer must be greater than zero.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (455, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'Points to transfer must be greater than zero.', N'Points to transfer must be greater than zero.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Points to transfer must be greater than zero.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Points to transfer must be greater than zero.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'User mobile number is not registered.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (456, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'User mobile number is not registered.', N'User mobile number is not registered.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'User mobile number is not registered.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'User mobile number is not registered.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Supervisor mobile number is not registered.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (457, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'Supervisor mobile number is not registered.', N'Supervisor mobile number is not registered.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Supervisor mobile number is not registered.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Supervisor mobile number is not registered.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Insufficient balance. Your available balance is {availableBalance} points.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (458, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Validation', N'Insufficient balance. Your available balance is {availableBalance} points.', N'Insufficient balance. Your available balance is {availableBalance} points.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'Insufficient balance. Your available balance is {availableBalance} points.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Insufficient balance. Your available balance is {availableBalance} points.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Points transferred to supervisor successfully.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (459, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Success', N'Points transferred to supervisor successfully.', N'Points transferred successfully!', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Success', [RecommendedEnglish] = N'Points transferred successfully!', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Points transferred to supervisor successfully.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Failed to transfer points.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (460, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Error', N'Failed to transfer points.', N'We couldn''t complete this action. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'We couldn''t complete this action. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'Failed to transfer points.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (461, N'HttpPost api/bl-app/TransferPointsToSupervisor', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpPost api/bl-app/TransferPointsToSupervisor' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetPointsTransferHistory' AND [ActualMessage] = N'Company ID is required.')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (462, N'HttpGet api/bl-app/GetPointsTransferHistory', N'Validation', N'Company ID is required.', N'We couldn''t identify your brand. Please try again.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Validation', [RecommendedEnglish] = N'We couldn''t identify your brand. Please try again.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetPointsTransferHistory' AND [ActualMessage] = N'Company ID is required.';
END;
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[AppReturnMessages_AI] WHERE [ApiName] = N'HttpGet api/bl-app/GetPointsTransferHistory' AND [ActualMessage] = N'An unexpected error occurred')
BEGIN
    INSERT INTO [dbo].[AppReturnMessages_AI] ([SrNo], [ApiName], [MessageType], [ActualMessage], [RecommendedEnglish], [IsActive], [CreatedDate], [UpdatedDate])
    VALUES (463, N'HttpGet api/bl-app/GetPointsTransferHistory', N'Error', N'An unexpected error occurred', N'Something went wrong. Please try again shortly.', 1, GETDATE(), GETDATE());
END
ELSE
BEGIN
    UPDATE [dbo].[AppReturnMessages_AI]
    SET [MessageType] = N'Error', [RecommendedEnglish] = N'Something went wrong. Please try again shortly.', [UpdatedDate] = GETDATE()
    WHERE [ApiName] = N'HttpGet api/bl-app/GetPointsTransferHistory' AND [ActualMessage] = N'An unexpected error occurred';
END;
GO
