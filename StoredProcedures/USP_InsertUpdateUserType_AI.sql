USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROC [dbo].[USP_InsertUpdateUserType_AI] @compid   VARCHAR(20),
                                     @Mobileno VARCHAR(13),
                                     @UserType VARCHAR(20),
                                     @DML      VARCHAR(10)
AS
  BEGIN
      DECLARE @M_consumerid BIGINT

      IF EXISTS (SELECT m_consumerid
                 FROM   m_consumer
                 WHERE  mobileno = @Mobileno)
        BEGIN
            SELECT @M_consumerid = m_consumerid
            FROM   m_consumer
            WHERE  mobileno = @Mobileno

            IF( @DML = 'U' )
              BEGIN
                  IF EXISTS (SELECT*
                             FROM   tbl_vendorvisekycstatus
                             WHERE  m_consumerid = @M_consumerid
                                    AND comp_id = @compid)
                    BEGIN
                        UPDATE tbl_vendorvisekycstatus
                        SET    vrkabel_user_type = @UserType
                        WHERE  m_consumerid = @M_consumerid
                               AND comp_id = @compid
							   	SELECT '1' AS Returnmsg;
                    END
              END
            ELSE IF( @DML = 'I' )
              BEGIN
                  IF NOT EXISTS (SELECT*
                                 FROM   tbl_vendorvisekycstatus
                                 WHERE  m_consumerid = @M_consumerid
                                        AND comp_id = @compid)
                    BEGIN
                        INSERT INTO tbl_vendorvisekycstatus
                                    (m_consumerid,
                                     comp_id,
                                     mobileno,
                                     vrkabel_user_type)
                        VALUES      (@M_consumerid,
                                     @compid,
                                     @Mobileno,
                                     @UserType)
							SELECT '1' AS Returnmsg;
                    END
              END
        END
      ELSE
        BEGIN
            SELECT 'User Not Register' AS Returnmsg;
        END
  END 
GO
