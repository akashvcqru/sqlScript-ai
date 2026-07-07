USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateMAndMUser_AI]    Script Date: 4/1/2026 9:58:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_UpdateMAndMUser_AI]
(
    @ConsumerId VARCHAR(50),
    @DealerCode VARCHAR(50) = null,
    @UserType VARCHAR(50),
    @Comp_id VARCHAR(50),
    @TechMasterId VARCHAR(50) = null
)
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @UserTypeName VARCHAR(50);
	DECLARE @UserTypeInt INT = TRY_CAST(@UserType AS INT);

	IF (@UserTypeInt IS NULL)
	BEGIN
		SELECT 'Please Select Valid User Type' AS Status;
		RETURN;
	END

	SELECT @UserTypeName = User_Type 
    FROM User_Type 
    WHERE Row_id = @UserTypeInt;

	IF (@Comp_id <> 'Comp-1152' OR @DealerCode IS   NULL OR LTRIM(RTRIM(@DealerCode)) = '')
    BEGIN
	      IF (@Comp_id = 'Comp-1152')
          BEGIN
		    select @DealerCode = distributorID , @TechMasterId = employeeID from M_Consumer where M_ConsumerID = @ConsumerId
              IF (@UserTypeName <> 'M Star')
                   BEGIN
               	    IF (@UserTypeName = 'Tech Master')
                       BEGIN 
               		   
               			IF NOT EXISTS (
                               SELECT 1 
                               FROM m_dealermaster 
                               WHERE DealerCode = @DealerCode 
                                 AND DealerTechnicianId = @TechMasterId
               				  AND DealerCode <> 'SBUTEAM'
                           )
                           BEGIN
                               SELECT 'Please Select Valid User Type' AS Status;
                               RETURN;
                           END
               		    
                           IF NOT EXISTS (
                               SELECT 1 
                               FROM M_Consumer 
                               WHERE employeeID = @TechMasterId 
                                 AND distributorID = @DealerCode and IsDelete = 0
                                 AND M_ConsumerID = @ConsumerId
                           )
                           BEGIN
                               SELECT 'Please Select Valid User Type' AS Status;
                               RETURN;
                           END
               
               		END
               
               		IF (@UserTypeName = 'SBU')
                       BEGIN 
               		   
               			IF NOT EXISTS (
                               SELECT 1 
                               FROM m_dealermaster 
                               WHERE DealerCode = @DealerCode 
                                 AND DealerTechnicianId = @TechMasterId
               				  AND DealerCode = 'SBUTEAM'
                           )
                           BEGIN
                               SELECT 'Please Select Valid User Type' AS Status;
                               RETURN;
                           END
               		    
                           IF NOT EXISTS (
                               SELECT 1 
                               FROM M_Consumer 
                               WHERE employeeID = @TechMasterId 
                                 AND distributorID = @DealerCode and IsDelete = 0
                                 AND M_ConsumerID = @ConsumerId
                           )
                           BEGIN
                               SELECT 'Please Select Valid User Type' AS Status;
                               RETURN;
                           END
               
               		END
               
                   END
                   ELSE
                   BEGIN
                       IF NOT EXISTS (
                           SELECT 1 
                           FROM m_dealermaster_mahindra_emp 
                           WHERE DealerCode = @DealerCode 
                             AND DealerTechnicianId = @TechMasterId
                       )
                       BEGIN
                           SELECT 'Please Select Valid User Type' AS Status;
                           RETURN;
                       END
               
                       IF NOT EXISTS (
                           SELECT 1 
                           FROM M_Consumer 
                           WHERE employeeID = @TechMasterId 
                             AND distributorID = @DealerCode and IsDelete = 0
                             AND M_ConsumerID = @ConsumerId
                       )
                       BEGIN
                           SELECT 'Please Select Valid User Type' AS Status;
                           RETURN;
                       END
                   END

          END
       	   UPDATE M_Consumer
           SET 
               Vrkabel_User_Type = @UserTypeInt
           WHERE M_ConsumerID = @ConsumerId;
       	 UPDATE tbl_Vendorvisekycstatus
           SET 
               Vrkabel_User_Type = @UserTypeInt
           WHERE M_ConsumerID = @ConsumerId; 
		   select 'Success' as Status
       	  return
	end



	-- 🔴 For Comp-1152: user must exist in at least one dealer table
    IF NOT EXISTS (
            SELECT 1
            FROM m_dealermaster_mahindra_emp
            WHERE DealerCode = @DealerCode
              AND DealerTechnicianId = @TechMasterId
    )
    AND NOT EXISTS (
            SELECT 1
            FROM m_dealermaster
            WHERE DealerCode = @DealerCode
              AND DealerTechnicianId = @TechMasterId
    )
    AND EXISTS (
            SELECT 1
            FROM M_Consumer
            WHERE employeeID = @TechMasterId
              AND distributorID = @DealerCode
              AND M_ConsumerID = @ConsumerId
    )
    BEGIN
	     UPDATE M_Consumer
         SET 
             Vrkabel_User_Type = @UserTypeInt
         WHERE M_ConsumerID = @ConsumerId;
	     UPDATE tbl_Vendorvisekycstatus
         SET 
            Vrkabel_User_Type = @UserTypeInt
          WHERE M_ConsumerID = @ConsumerId;


        SELECT 'Your account is currently inactive. Please contact your Customer Care Manager for assistance.' AS Status;
        RETURN;
    END
	ELSE
    BEGIN
	    IF   EXISTS (
                SELECT 1
                FROM m_dealermaster_mahindra_emp
                WHERE DealerCode = @DealerCode
                  AND DealerTechnicianId = @TechMasterId
        )
        or   EXISTS (
                SELECT 1
                FROM m_dealermaster
                WHERE DealerCode = @DealerCode
                  AND DealerTechnicianId = @TechMasterId
        )
		BEGIN
		   print 'AK'
		end
		else
		BEGIN
		SELECT 'Invalid Id and Dealer Code' AS Status;
            RETURN;
		end
    END
    




	IF (@UserTypeName <> 'M Star')
    BEGIN



	    IF (@UserTypeName = 'Tech Master')
        BEGIN 
		   
			IF NOT EXISTS (
                SELECT 1 
                FROM m_dealermaster 
                WHERE DealerCode = @DealerCode 
                  AND DealerTechnicianId = @TechMasterId
				  AND DealerCode <> 'SBUTEAM'
            )
            BEGIN
                SELECT 'Invalid Tech Master ID' AS Status;
                RETURN;
            END
		    
            IF NOT EXISTS (
                SELECT 1 
                FROM M_Consumer 
                WHERE employeeID = @TechMasterId 
                  AND distributorID = @DealerCode and IsDelete = 0
                  AND M_ConsumerID = @ConsumerId
            )
            BEGIN
                SELECT 'This Tech Master id is already used by another user' AS Status;
                RETURN;
            END

		END

		IF (@UserTypeName = 'SBU')
        BEGIN 
		   
			IF NOT EXISTS (
                SELECT 1 
                FROM m_dealermaster 
                WHERE DealerCode = @DealerCode 
                  AND DealerTechnicianId = @TechMasterId
				  AND DealerCode = 'SBUTEAM'
            )
            BEGIN
                SELECT 'Invalid SBU ID' AS Status;
                RETURN;
            END
		    
            IF NOT EXISTS (
                SELECT 1 
                FROM M_Consumer 
                WHERE employeeID = @TechMasterId 
                  AND distributorID = @DealerCode and IsDelete = 0
                  AND M_ConsumerID = @ConsumerId
            )
            BEGIN
                SELECT 'This SBU Id is already used by another user' AS Status;
                RETURN;
            END

		END

    END
    ELSE
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM m_dealermaster_mahindra_emp 
            WHERE DealerCode = @DealerCode 
              AND DealerTechnicianId = @TechMasterId
        )
        BEGIN
            SELECT 'Invalid Dealer Code or M Star Id' AS Status;
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 
            FROM M_Consumer 
            WHERE employeeID = @TechMasterId 
              AND distributorID = @DealerCode and IsDelete = 0
              AND M_ConsumerID = @ConsumerId
        )
        BEGIN
            SELECT 'This Dealer Code & M Star Id is already used by another user' AS Status;
            RETURN;
        END
    END


    IF NOT EXISTS (SELECT 1 FROM M_Consumer WHERE M_ConsumerID = @ConsumerId)
    BEGIN
        SELECT 'User not found' AS Status;
        RETURN;
    END

	 

   
    UPDATE M_Consumer
    SET 
        distributorID = @DealerCode,
        employeeID = @TechMasterId,
        Vrkabel_User_Type = @UserTypeInt
    WHERE M_ConsumerID = @ConsumerId;
	UPDATE tbl_Vendorvisekycstatus
    SET 
        Vrkabel_User_Type = @UserTypeInt
    WHERE M_ConsumerID = @ConsumerId;

    SELECT 'Success' AS Status;
END
GO
