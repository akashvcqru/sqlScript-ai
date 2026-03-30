CREATE PROCEDURE [dbo].[USP_CheckFrequencyused_AI]  
    @Comp_ID NVARCHAR(20),  
    @Code1 NVARCHAR(5),  
    @Code2 NVARCHAR(8),  
    @Mobileno NVARCHAR(13)  
AS  
BEGIN  
    IF (@Comp_ID = 'Comp-1819')  
    BEGIN  
        -- Check if the user exists and is associated with the provided company  
        IF EXISTS (  
            SELECT 1  
            FROM M_Consumer mc  
            INNER JOIN User_Type u ON mc.Vrkabel_User_Type = u.Row_ID  
            WHERE mc.Mobileno = @Mobileno AND u.Comp_ID = @Comp_ID  
        )  
        BEGIN  
            -- Check if the code is active and not deleted  
            IF EXISTS (  
                SELECT 1  
                FROM tbl_M_Code_USERFrequency   
                WHERE Code1 = @Code1   
                AND Code2 = @Code2   
                AND Isactive = 1   
                AND Isdelete = 0  
            )  
            BEGIN  
                -- Declare temporary variables to hold the result  
                DECLARE @Frequency INT,   
                        @UserTypeRole NVARCHAR(50),   
                        @AssignPoint INT,   
                        @Use_count INT;  
                  
                -- Retrieve frequency and related data  
                SELECT  
                    @Frequency = f.Frequency,  
                    @UserTypeRole = f.UserTypeRole,  
                    @AssignPoint = f.AssignPoint,  
                    @Use_count = f.Use_count  
                FROM tbl_M_Code_USERFrequency f  
                INNER JOIN M_Code m ON m.Code1 = f.Code1 AND m.Code2 = f.Code2  
                WHERE f.Comp_ID = @Comp_ID  
                  AND m.Code1 = @Code1  
                  AND m.Code2 = @Code2  
                  AND f.Use_count = 0  
                  AND f.Isactive = 1  
                  AND f.Isdelete = 0  
                  AND f.UserTypeRole = (  
                      SELECT u.User_Type  
                      FROM M_Consumer mc  
                      INNER JOIN User_Type u ON mc.Vrkabel_User_Type = u.Row_ID  
                      WHERE mc.Mobileno = @Mobileno AND u.Comp_ID = @Comp_ID  
                  );  
                  
                -- If frequency is not found, return 'frequency already used'  
                IF (@Frequency IS NULL)  
                BEGIN  
                    SELECT 'Frequency already used.' AS Message;  
                END  
                ELSE  
                BEGIN  
                    -- Return frequency details  
                    SELECT  
                        @Frequency AS Frequency,  
                        @UserTypeRole AS UserTypeRole,  
                        @AssignPoint AS AssignPoint,  
                        @Use_count AS Use_count;  
                END  
            END  
            ELSE  
            BEGIN  
                -- If the coupon is deactivated, return an error message  
                SELECT 'Coupon deactivated' AS ErrorMessage,'This coupon code has been deactivated and cannot be used. Please contact customer support for more details.' AS Messagetemp;  
            END  
        END  
        ELSE  
        BEGIN  
            -- If user is not associated with the company, return 'UserType not found'  
            SELECT 'UserType not found' AS ErrorMessage;  
        END  
    END  
    ELSE  
    BEGIN  
        -- If the company ID is not correct, return 'UserType not found'  
        SELECT 'UserType not found' AS ErrorMessage;  
    END  
END;  
GO
