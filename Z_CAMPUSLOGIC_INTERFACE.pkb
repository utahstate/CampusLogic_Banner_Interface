/* Formatted on 8/18/2021 3:55:27 PM (QP5 v5.336) */
CREATE OR REPLACE PACKAGE BODY BANINST1.z_campuslogic_interface
AS
  /****************************************************************************
    NAME:       z_campuslogic_interface
    PURPOSE:    Interfacing package between Ellucian Banner and Campus Logic
                CL Connect server. Performs database udpates to Banner and
                BDMS, if in use. ZCLELOG is a new logging table for all
                transactions, ZCLXWLK is a new cross reference table to
                indicate which BDMS document types corespond to which Banner
                TREQ types.

    REVISIONS:
    Ver      Date      Author               Description
    -------  --------  -------------------  ------------------------------------
    .9b      20160317  Marty Carver, Weber  provided reference components
    1.0      20160318  Carl Ellsworth, USU  created this package
    1.1      20160325  Carl Ellsworth &     updated process with additional
                       John Mays, USU         logic
    1.2      20160331  Carl Ellsworth       commented code for other users
    1.2.1    20160510  Carl Ellsworth &     extended transaction categoy
                       Steven Francom, USU    ids to include SAP and PJ
    1.3      20160510  Carl Ellsworth &     added logic to update ROASTAT
                       Steven Francom, USU    verification field on complete
    1.3.1    20160517  Carl Ellsworth, USU  removed logic for fund_code,
                                              cl_connect was throwing errors
    1.3.2    20160523  Carl Ellsworth, USU  changed updated RRRAREQ records to
                                              a sys_ind of 'B'
    1.3.3    20160708  Carl Ellsworth, USU  updated p_status_upd_api to include
                                              RORSTAT_VER_COMPLETE in processing
    1.3.4    20160711  Carl Ellsworth, USU  updated p_status_upd_api, found that
                                              p_ver_pay_ind and p_ver_complete
                                              must be set in separate steps
    1.3.5    20171205  Steven Francom, USU  updated v_banner_verify_code for clarity
    1.4      20190417  Carl Ellsworth, USU  added handling for 209 events
    1.4.1    20190429  Carl Ellsworth, USU  changed 209 logic to ROBNYUD update
    2.0      20210802  Miles Canfield, USU  expansion to accommodate Scholarship Universe
    2.0.1    20210809  Carl & Miles, USU    logic changes for cl-connect limitations
    2.0.2                                   removal of USU specific block
    2.0.3    20210818  Miles Canfield, USU  split p_transaction into SF and SU parts
    2.0.4    20210825  Miles Canfield, USU  put rp_award create outside case statement
                                              isolated SU event updates as a result
    2.0.5    20210826  Miles Canfield, USU  update events that already exist and add
                                              better logging of errors

    NOTES:
    Reference this documentation for various p_eventNotificationId codes
    https://campuslogicinc.freshdesk.com/support/solutions/articles/5000573254
    Reference for event notifactions
    https://campuslogicinc.freshdesk.com/support/solutions/articles/5000868997-event-notifications-guide
    Reference this documentation for Web.config entries
    https://github.com/campuslogic/CL-Connect/blob/master/Web.config

    transaction category
    1 = Student Verification
    2 = SAP Appeal
    3 = PJ Dependency Override Appeal
    4 = PJ EFC Appeal
    5 = Other Documents
  ****************************************************************************/

  /* DEPENDENT TABLES

  DROP TABLE BANINST1.ZCLELOG;

  CREATE TABLE BANINST1.ZCLELOG
  (
    ZCLELOG_STUDENTID                  VARCHAR2 (9 CHAR),
    ZCLELOG_AWARDYEAR                  VARCHAR2 (4 CHAR),
    ZCLELOG_SFTRANSACTIONCATEGORYID    INTEGER,
    ZCLELOG_EVENTNOTIFICATIONID        INTEGER,
    ZCLELOG_SFDOCUMENTNAME             VARCHAR2 (100 CHAR),
    ZCLELOG_PIDM                       NUMBER (8),
    ZCLELOG_CREATE_DATE                DATE,
    ZCLELOG_EVENTID                    VARCHAR2 (100 CHAR),
    ZCLELOG_EVENTNOTIFICATIONNAME      VARCHAR2 (100 CHAR),
    ZCLELOG_EVENTDATETIME              VARCHAR2 (50 CHAR),
    ZCLELOG_SUTERMCODE                 VARCHAR2 (6 CHAR),
    ZCLELOG_SUSCHOLARSHIPAWARDID       VARCHAR2 (30 CHAR),
    ZCLELOG_SUSCHOLARSHIPNAME          VARCHAR2 (100 CHAR),
    ZCLELOG_SUSCHOLARSHIPCODE          VARCHAR2 (100 CHAR),
    ZCLELOG_SUAMOUNT                   NUMBER (11, 2),
    ZCLELOG_SUPOSTBATCHUSER            VARCHAR2 (100 CHAR),
    ZCLELOG_SUPOSTTYPE                 VARCHAR2 (30 CHAR),
    ZCLELOG_SUTERMCOMMENTS             VARCHAR2 (4000 CHAR),
    ZCLELOG_ACTIVITY                   DATE DEFAULT SYSDATE,
    ZCLELOG_VERSION                    INTEGER DEFAULT 1,
    ZCLELOG_PROCESSED                  DATE
  );

  CREATE TABLE BANINST1.ZCLERRM
  (
    ZCLERRM_EVENTID       VARCHAR2 (100),
    ZCLERRM_CODE          INTEGER,
    ZCLERRM_MESSAGE       VARCHAR2 (300),
    ZCLERRM_CREATE_DATE   DATE DEFAULT SYSDATE
  );

  DROP TABLE BANINST1.ZCLXWLK;

  CREATE TABLE BANINST1.ZCLXWLK
  (
     ZCLXWLK_AIDY_CODE      VARCHAR2 (4 CHAR) NOT NULL,
     ZCLXWLK_TREQ_CODE      VARCHAR2 (6 CHAR),
     ZCLXWLK_DOCUMENT       VARCHAR2 (100 CHAR) NOT NULL,
     ZCLXWLK_CAMPUS_LOGIC   VARCHAR2 (1 CHAR) NOT NULL,
     ZCLXWLK_YEAR_BASED     VARCHAR2 (1 CHAR) NOT NULL,
     ZCLXWLK_CROSSWALKED    VARCHAR2 (1 CHAR) NOT NULL
  );

  */

  /**
  * Calls the Banner table API for RORSTAT
  */
  PROCEDURE p_status_upd_api (p_pidm          VARCHAR2,
                              p_awardYear     VARCHAR2,
                              p_verPayInd     VARCHAR2,
                              p_verComplete   VARCHAR2)
  AS
    record_count   NUMBER;
  BEGIN
    --determine if the student exists in a verification group (USU Specific)
    --Verification Group Logic, can be removed to apply to all students
    SELECT COUNT (*)
      INTO record_count
      FROM rcrapp1
     WHERE     rcrapp1_verification_prty LIKE 'V%'
           AND rcrapp1_curr_rec_ind = 'Y'
           AND rcrapp1_aidy_code = p_awardYear
           AND rcrapp1_pidm = p_pidm;


    IF (record_count >= 1)                          --verification group check
    THEN
      --Update RORSTAT
      IF (rp_applicant_status.f_exists (p_aidy_code   => p_awardYear,
                                        p_pidm        => p_pidm) =
          'Y')
      THEN
        --update p_ver_pay_ind
        rp_applicant_status.p_update (p_aidy_code     => p_awardYear,
                                      p_pidm          => p_pidm,
                                      p_ver_pay_ind   => p_verPayInd);
        --update p_ver_complete to 'Y'
        rp_applicant_status.p_update (p_aidy_code      => p_awardYear,
                                      p_pidm           => p_pidm,
                                      p_ver_complete   => p_verComplete);
        gb_common.p_commit;
      ELSE
        --create p_ver_pay_ind
        rp_applicant_status.p_create (p_aidy_code     => p_awardYear,
                                      p_pidm          => p_pidm,
                                      p_ver_pay_ind   => p_verPayInd);
        --update p_ver_complete to 'Y'
        rp_applicant_status.p_update (p_aidy_code      => p_awardYear,
                                      p_pidm           => p_pidm,
                                      p_ver_complete   => p_verComplete);
        gb_common.p_commit;
      END IF;
    END IF;
  END p_status_upd_api;


  /**
  * Calls the Banner table API for RRRAREQ
  */
  PROCEDURE p_tracking_upd_api (p_pidm        VARCHAR2,
                                p_awardYear   VARCHAR2,
                                p_treqCode    VARCHAR2,
                                p_status      VARCHAR2,
                                p_sysInd      VARCHAR2)
  AS
    record_count   NUMBER;
    treq_row       rrrareq%ROWTYPE DEFAULT NULL;
  BEGIN
    --determine if there is an existing record
    SELECT COUNT (*)
      INTO record_count
      FROM rrrareq
     WHERE     rrrareq_pidm = p_pidm
           AND rrrareq_aidy_code = p_awardYear
           AND rrrareq_treq_code = p_treqCode;

    IF record_count = 0
    --if no record exists, create it
    THEN
      rp_requirement.p_create (p_aidy_code       => p_awardYear,
                               p_pidm            => p_pidm,
                               p_treq_code       => p_treqCode,
                               p_stat_date       => TRUNC (SYSDATE),
                               p_trst_code       => p_status,
                               p_fund_code       => NULL,
                               p_sys_ind         => NVL (p_sysInd, 'B'),
                               p_sbgi_code       => NULL,
                               p_sbgi_type_ind   => NULL,
                               p_term_code       => NULL);
      gb_common.p_commit;
    ELSIF record_count = 1
    --if a record already exists, update it
    THEN
      SELECT *
        INTO treq_row
        FROM rrrareq
       WHERE     rrrareq_aidy_code = p_awardYear
             AND rrrareq_pidm = p_pidm
             AND rrrareq_treq_code = p_treqCode;

      rp_requirement.p_update (p_aidy_code   => p_awardYear,
                               p_pidm        => p_pidm,
                               p_treq_code   => p_treqCode,
                               p_stat_date   => TRUNC (SYSDATE),
                               p_trst_code   => p_status,
                               p_fund_code   => treq_row.rrrareq_fund_code,
                               -- Request to change even updated records to a sys_ind of 'B'
                               --p_sys_ind     => treq_row.rrrareq_sys_ind,
                               p_sys_ind     => NVL (p_sysInd, 'B'),
                               p_sbgi_code   => treq_row.rrrareq_sbgi_code);

      gb_common.p_commit;
    END IF;
  END p_tracking_upd_api;

  /**
  * Updates tracking index for document in BDMS, B-R-TREQ application (ae_dt507)
  */
  PROCEDURE p_update_xtender (p_studentId             VARCHAR2,
                              p_studentPidm           INTEGER,
                              p_awardYear             VARCHAR2,
                              p_documentName          VARCHAR2,
                              p_treqCode              VARCHAR2,
                              p_status                VARCHAR2,
                              p_eventNotificationId   INTEGER)
  AS
    record_count   NUMBER;
  BEGIN
    --determine if there is an existing document in BDMS
    SELECT COUNT (*)
      INTO record_count
      FROM otgmgr.ae_dt507
     WHERE     field1 = p_studentId
           AND UPPER (field3) = UPPER (p_documentName)
           AND field8 = p_awardYear;

    IF record_count = 1
    --if a record exists, update it
    THEN
      IF p_eventNotificationId = 403
      --Document Accepted (see notes)
      THEN
        UPDATE otgmgr.ae_dt507
           SET field10 = 'C', field9 = p_treqCode
         WHERE     field1 = p_studentId
               AND UPPER (field3) = UPPER (p_documentName)
               AND field8 = p_awardYear;

        COMMIT;
      ELSE
        UPDATE otgmgr.ae_dt507
           SET field10 = 'R', field9 = p_treqCode
         WHERE     field1 = p_studentId
               AND UPPER (field3) = UPPER (p_documentName)
               AND field8 = p_awardYear;

        COMMIT;
      END IF;

      --Update Banner RRRAREQ tracking requirement
      IF p_treqCode IS NOT NULL
      THEN
        p_tracking_upd_api (p_pidm        => p_studentPidm,
                            p_awardYear   => p_awardYear,
                            p_treqCode    => p_treqCode,
                            p_status      => p_status,
                            p_sysInd      => 'B');
      END IF;
    END IF;
  END p_update_xtender;


  /**
  * Procedure called from CL Connect for Student Forms transactions
  *
  * In Web.config on the CL Connect server, populate the field dbCommandFieldValue
  * with the full path to this procedure, BANINST1.z_campuslogic_interface.p_sf_transaction
  */
  PROCEDURE p_sf_transaction (
    p_studentId                 VARCHAR2,
    p_eventNotificationId       INTEGER,
    p_eventId                   VARCHAR2 DEFAULT NULL,
    p_eventNotificationName     VARCHAR2 DEFAULT NULL,
    p_eventDateTime             VARCHAR2 DEFAULT NULL,
    p_sfAwardYear               VARCHAR2 DEFAULT NULL,
    p_sfTransactionCategoryId   INTEGER DEFAULT NULL,
    p_sfDocumentName            VARCHAR2 DEFAULT NULL)
  AS
    v_record_count                    NUMBER;
    v_student_pidm                    NUMBER := NULL;
    v_aidy_code                       VARCHAR2 (4) := NULL;

    v_status                          VARCHAR2 (1);
    v_treq_code                       rrrareq.rrrareq_treq_code%TYPE;
    --update these constants to your Banner specific needs
    v_banner_verify_code              rrrareq.rrrareq_treq_code%TYPE := 'CLOGIC';
    v_banner_sap_code        CONSTANT rrrareq.rrrareq_treq_code%TYPE := 'SAP';
    v_banner_pj_code         CONSTANT rrrareq.rrrareq_treq_code%TYPE := 'PROJUD';
    v_banner_creation_code   CONSTANT rrrareq.rrrareq_treq_code%TYPE
                                        := 'ACCTCL' ;
  BEGIN
    --Determine if StudentID matches a single record in Banner
    BEGIN
      SELECT spriden_pidm
        INTO v_student_pidm
        FROM spriden
       WHERE spriden_change_ind IS NULL AND spriden_id = p_studentId;
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        DBMS_OUTPUT.PUT_LINE (
          'ERROR: student not found for studentID ' || p_studentId);
      WHEN TOO_MANY_ROWS
      THEN
        DBMS_OUTPUT.PUT_LINE (
          'ERROR: duplicate pidm issue for studentID ' || p_studentId);
    END;

    --Determine if Aid Year exists in Banner
    IF p_sfAwardYear IS NOT NULL
    THEN
      BEGIN
        SELECT robinst_aidy_code
          INTO v_aidy_code
          FROM robinst
         WHERE robinst_aidy_code = p_sfAwardYear;
      EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
          v_aidy_code := NULL;
          DBMS_OUTPUT.PUT_LINE (
            'ERROR: award year is invalid: ' || p_sfAwardYear);
        WHEN TOO_MANY_ROWS
        THEN
          v_aidy_code := NULL;
          DBMS_OUTPUT.PUT_LINE (
            'ERROR: award year is invalid: ' || p_sfAwardYear);
      END;
    END IF;

    --log the incoming transaction
    BEGIN
        MERGE INTO baninst1.zclelog USING dual ON (zclelog_eventid = p_eventId)
        WHEN MATCHED THEN
            UPDATE SET zclelog_activity = SYSDATE,
                       zclelog_version = zclelog_version + 1
        WHEN NOT MATCHED THEN
            INSERT (zclelog_studentid,
                    zclelog_pidm,
                    zclelog_awardyear,
                    zclelog_eventid,
                    zclelog_eventnotificationname,
                    zclelog_eventdatetime,
                    zclelog_eventnotificationid,
                    zclelog_sftransactioncategoryid,
                    zclelog_sfdocumentname,
                    zclelog_sutermcode,
                    zclelog_suscholarshipawardid,
                    zclelog_suscholarshipname,
                    zclelog_suscholarshipcode,
                    zclelog_suamount,
                    zclelog_supostbatchuser,
                    zclelog_suposttype,
                    zclelog_sutermcomments,
                    zclelog_activity,
                    zclelog_processed,
                    zclelog_create_date)
           VALUES (p_studentId,
                   v_student_pidm,
                   v_aidy_code,
                   p_eventId,
                   p_eventNotificationName,
                   p_eventDateTime,
                   p_eventNotificationId,
                   p_sfTransactionCategoryId,
                   p_sfDocumentName,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   SYSDATE,
                   NULL,
                   SYSDATE);

      COMMIT;
    EXCEPTION
      WHEN OTHERS
      THEN
        DBMS_OUTPUT.PUT_LINE (
          'ERROR: failed to insert event notification into ZCLELOG');
    END;

    -- Custom Error Block
    IF v_student_pidm IS NULL
    THEN
      raise_application_error (
        -20404,
        'ERROR: student pidm not found for ' || p_studentId);
    ELSIF p_sfAwardYear IS NULL
    THEN
      raise_application_error (
        -20400,
        'ERROR: award year is required to process transaction');
    END IF;

    --BANNER LOGIC

    CASE
      -- STUDENT FORMS
      WHEN (p_eventNotificationId = 103)
      THEN                                     --103 is File Review(see notes)
        IF (NVL (p_sfTransactionCategoryId, 0) = 1)     --Student Verification
        THEN
          p_tracking_upd_api (p_pidm        => v_student_pidm,
                              p_awardYear   => v_aidy_code,
                              p_treqCode    => v_banner_verify_code,
                              p_status      => 'Z',             --from RTVTRST
                              p_sysInd      => 'B');
        END IF;
      WHEN (p_eventNotificationId = 104)
      THEN                                      --104 is Correction(see notes)
        IF (NVL (p_sfTransactionCategoryId, 0) = 1)     --Student Verification
        THEN
          p_tracking_upd_api (p_pidm        => v_student_pidm,
                              p_awardYear   => v_aidy_code,
                              p_treqCode    => v_banner_verify_code,
                              p_status      => 'Q',             --from RTVTRST
                              p_sysInd      => 'B');
        END IF;
      WHEN (p_eventNotificationId = 105 AND p_sfDocumentName IS NULL)
      THEN                          --105 is Transaction Completed (see notes)
        CASE
          WHEN NVL (p_sfTransactionCategoryId, 0) = 1   --Student Verification
          THEN                      --update Banner RRRAREQ verify requirement
            p_tracking_upd_api (p_pidm        => v_student_pidm,
                                p_awardYear   => v_aidy_code,
                                p_treqCode    => v_banner_verify_code,
                                p_status      => 'C',           --from RTVTRST
                                p_sysInd      => 'B');
            p_status_upd_api (p_pidm          => v_student_pidm,
                              p_awardYear     => v_aidy_code,
                              p_verPayInd     => 'V',
                              p_verComplete   => 'Y');
          WHEN NVL (p_sfTransactionCategoryId, 0) = 2             --SAP Appeal
          THEN                         --update Banner RRRAREQ SAP requirement
            p_tracking_upd_api (p_pidm        => v_student_pidm,
                                p_awardYear   => v_aidy_code,
                                p_treqCode    => v_banner_sap_code,
                                p_status      => 'C',           --from RTVTRST
                                p_sysInd      => 'B');
          WHEN NVL (p_sfTransactionCategoryId, 0) IN (3, 4) --PJ Dependency Override Appeal
          THEN                          --update Banner RRRAREQ PJ requirement
            p_tracking_upd_api (p_pidm        => v_student_pidm,
                                p_awardYear   => v_aidy_code,
                                p_treqCode    => v_banner_pj_code,
                                p_status      => 'C',           --from RTVTRST
                                p_sysInd      => 'B');
        END CASE;
      WHEN (p_eventNotificationId IN (101, 107) AND p_sfDocumentName IS NULL)
      THEN
        --101 is Transaction Collect (see notes)
        --107 is Transaction ReCollect (see notes)
        CASE
          WHEN NVL (p_sfTransactionCategoryId, 0) = 1   --Student Verification
          THEN                      --update Banner RRRAREQ verify requirement
            p_tracking_upd_api (p_pidm        => v_student_pidm,
                                p_awardYear   => v_aidy_code,
                                p_treqCode    => v_banner_verify_code,
                                p_status      => 'N',           --from RTVTRST
                                p_sysInd      => 'B');
          WHEN NVL (p_sfTransactionCategoryId, 0) = 2             --SAP Appeal
          THEN                         --update Banner RRRAREQ SAP requirement
            p_tracking_upd_api (p_pidm        => v_student_pidm,
                                p_awardYear   => v_aidy_code,
                                p_treqCode    => v_banner_sap_code,
                                p_status      => 'N',           --from RTVTRST
                                p_sysInd      => 'B');
          WHEN NVL (p_sfTransactionCategoryId, 0) IN (3, 4) --PJ Dependency Override Appeal
          THEN                          --update Banner RRRAREQ PJ requirement
            p_tracking_upd_api (p_pidm        => v_student_pidm,
                                p_awardYear   => v_aidy_code,
                                p_treqCode    => v_banner_pj_code,
                                p_status      => 'N',           --from RTVTRST
                                p_sysInd      => 'B');
        END CASE;
      WHEN (p_eventNotificationId = 209)
      THEN                                --209 is Account Created (see notes)
        UPDATE ROBNYUD
           SET ROBNYUD_ACTIVITY_DATE = SYSDATE,
               ROBNYUD_VALUE_3 = v_banner_creation_code
         WHERE robnyud_pidm = v_student_pidm;
      ELSE
        NULL;
    END CASE;

    --EXTENDER LOGIC
    IF (    NVL (p_sfTransactionCategoryId, 0) >= 1
        AND p_eventNotificationId IS NOT NULL
        AND v_student_pidm IS NOT NULL)
    THEN
      --determine the status for tracking (see notes)
      IF NVL (p_eventNotificationId, 0) BETWEEN 400 AND 499
      THEN
        IF p_eventNotificationId = 403
        --Document Accepted (see notes)
        THEN
          v_status := 'C';
        ELSIF p_eventNotificationId = 401
        --Document Submitted (see notes)
        THEN
          v_status := 'R';
        ELSIF    p_eventNotificationId = 402
              OR p_eventNotificationId = 404
              OR p_eventNotificationId = 405
        --402 is Document Rejected (see notes)
        --404 is Document Recalled (see notes)
        --405 is Document Deleted (see notes)
        THEN
          v_status := 'N';
        END IF;

        IF (p_sfDocumentName IS NOT NULL AND v_status IS NOT NULL)
        --update BDMS document tracking field
        THEN
          --determine if there is a cross referenced document
          SELECT COUNT (*)
            INTO v_record_count
            FROM baninst1.zclxwlk
           WHERE     zclxwlk_aidy_code = v_aidy_code
                 AND UPPER (zclxwlk_document) = UPPER (p_sfDocumentName)
                 AND NVL (zclxwlk_treq_code, 'MINFO') <> 'MINFO';

          IF v_record_count = 1
          --get the tracking code if there is an associated tracking requirement
          THEN
            SELECT zclxwlk_treq_code
              INTO v_treq_code
              FROM baninst1.zclxwlk
             WHERE     zclxwlk_aidy_code = v_aidy_code
                   AND UPPER (zclxwlk_document) = UPPER (p_sfDocumentName)
                   AND NVL (zclxwlk_treq_code, 'MINFO') <> 'MINFO';
          ELSE
            v_treq_code := NULL;
          END IF;

          --update extender/banner tracking
          p_update_xtender (p_studentId             => p_studentId,
                            p_studentPidm           => v_student_pidm,
                            p_awardYear             => v_aidy_code,
                            p_documentName          => p_sfDocumentName,
                            p_treqCode              => v_treq_code,
                            p_status                => v_status,
                            p_eventNotificationId   => p_eventNotificationId);
        END IF;
      END IF;
    --end extender logic
    END IF;

    UPDATE baninst1.zclelog
    SET zclelog_processed = SYSDATE;
    COMMIT;

  EXCEPTION
      WHEN OTHERS THEN

          v_error_code := SQLCODE;
          v_error_message := trunc(SQLERRM, 511);

          INSERT INTO baninst1.zclerrm (zclerrm_eventid, zclerrm_code, zclerrm_message, zclerrm_create_date)
          VALUES(p_eventId, v_error_code, v_error_message, SYSDATE);
          COMMIT;

  END p_sf_transaction;

  /**
  * Procedure called from CL Connect for Scholarship Universe transactions
  *
  * In Web.config on the CL Connect server, populate the field dbCommandFieldValue
  * with the full path to this procedure, BANINST1.z_campuslogic_interface.p_su_transaction
  */
  PROCEDURE p_su_transaction (
    p_studentId               VARCHAR2,
    p_eventNotificationId     INTEGER,
    p_eventId                 VARCHAR2 DEFAULT NULL,
    p_eventNotificationName   VARCHAR2 DEFAULT NULL,
    p_eventDateTime           VARCHAR2 DEFAULT NULL,
    p_suTermName              VARCHAR2 DEFAULT NULL,
    p_suScholarshipAwardId    VARCHAR2 DEFAULT NULL,
    p_suScholarshipName       VARCHAR2 DEFAULT NULL,
    p_suScholarshipCode       VARCHAR2 DEFAULT NULL,
    p_suAmount                NUMBER DEFAULT NULL,
    p_suPostBatchUser         VARCHAR2 DEFAULT NULL,
    p_suPostType              VARCHAR2 DEFAULT NULL,
    p_suTermComments          VARCHAR2 DEFAULT NULL)
  AS
    v_student_pidm                   NUMBER := NULL;
    v_aidy_code                      VARCHAR2 (4) := NULL;
    v_term                           VARCHAR2 (6);
    v_exists                         VARCHAR2 (1) := 'N';

    v_error_code                     NUMBER := NULL;
    v_error_message                  VARCHAR2 (511) := NULL;

    --update these constants to your Banner specific needs
    v_awst_code_pending     CONSTANT VARCHAR2 (4) := 'P';
    v_awst_code_offered     CONSTANT VARCHAR2 (4) := 'O';        --703 offered
    v_awst_code_accepted    CONSTANT VARCHAR2 (4) := 'A';        --701 posted
    v_awst_code_cancelled   CONSTANT VARCHAR2 (4) := 'C';        --706 removed
    v_awst_code_declined    CONSTANT VARCHAR2 (4) := 'D';        --705 declined
  BEGIN
    --Determine if StudentID matches a single record in Banner
    BEGIN
      SELECT spriden_pidm
        INTO v_student_pidm
        FROM spriden
       WHERE spriden_change_ind IS NULL AND spriden_id = p_studentId;
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        DBMS_OUTPUT.PUT_LINE (
          'ERROR: student not found for studentID ' || p_studentId);
      WHEN TOO_MANY_ROWS
      THEN
        DBMS_OUTPUT.PUT_LINE (
          'ERROR: duplicate pidm issue for studentID ' || p_studentId);
    END;

    -- Determine if p_suTermName is valid and get aidy_code.
    IF p_suTermName IS NOT NULL
    THEN
      BEGIN
        SELECT stvterm_code, stvterm_fa_proc_yr
          INTO v_term, v_aidy_code
          FROM stvterm
         WHERE UPPER (stvterm_desc) = UPPER (p_suTermName);
      EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
          v_aidy_code := NULL;
          DBMS_OUTPUT.PUT_LINE (
            'ERROR: term desc is invalid: ' || p_suTermName);
      END;
    END IF;

    --log the incoming transaction
    BEGIN
      MERGE INTO baninst1.zclelog USING dual ON (zclelog_eventid = p_eventId)
      WHEN MATCHED THEN
          UPDATE SET zclelog_activity = SYSDATE,
                     zclelog_version = zclelog_version + 1
      WHEN NOT MATCHED THEN
          INSERT (zclelog_studentid,
                  zclelog_pidm,
                  zclelog_awardyear,
                  zclelog_eventid,
                  zclelog_eventnotificationname,
                  zclelog_eventdatetime,
                  zclelog_eventnotificationid,
                  zclelog_sftransactioncategoryid,
                  zclelog_sfdocumentname,
                  zclelog_sutermcode,
                  zclelog_suscholarshipawardid,
                  zclelog_suscholarshipname,
                  zclelog_suscholarshipcode,
                  zclelog_suamount,
                  zclelog_supostbatchuser,
                  zclelog_suposttype,
                  zclelog_sutermcomments,
                  zclelog_activity,
                  zclelog_processed,
                  zclelog_create_date)
           VALUES (p_studentId,
                   v_student_pidm,
                   v_aidy_code,
                   p_eventId,
                   p_eventNotificationName,
                   p_eventDateTime,
                   p_eventNotificationId,
                   NULL,
                   NULL,
                   v_term,
                   p_suScholarshipAwardId,
                   p_suScholarshipName,
                   p_suScholarshipCode,
                   p_suAmount,
                   p_suPostBatchUser,
                   p_suPostType,
                   p_suTermComments,
                   SYSDATE,
                   NULL,
                   SYSDATE);

      COMMIT;
    EXCEPTION
      WHEN OTHERS
      THEN
        DBMS_OUTPUT.PUT_LINE (
          'ERROR: failed to insert event notification into ZCLELOG');
    END;

    -- Custom Error Block
    IF v_student_pidm IS NULL
    THEN
      raise_application_error (
        -20404,
        'ERROR: student pidm not found for ' || p_studentId);
    ELSIF p_suTermName IS NULL
    THEN
      raise_application_error (
        -20400,
        'ERROR: aid year or term name is required to process transaction');
    END IF;

    v_exists := rp_award_schedule.f_exists(
        p_aidy_code => v_aidy_code,
        p_pidm => v_student_pidm,
        p_fund_code =>  p_suScholarshipCode,
        p_term_code => v_term);

    IF (v_exists = 'N')
    THEN
      rp_award_schedule.p_create (
              p_aidy_code   => v_aidy_code,
              p_pidm        => v_student_pidm,
              p_fund_code   => p_suScholarshipCode,
              p_period      => v_term,
              p_term_code   => v_term,
              p_offer_amt   => p_suAmount,
              p_offer_date  =>
                  TO_DATE (
                          SUBSTR (p_eventDateTime, 1, LENGTH (p_eventDateTime) - 3),
                          'MM/DD/YYYY HH24:MI:SS'),
              p_awst_code   => v_awst_code_pending,
              p_awst_date   =>
                  TO_DATE (
                          SUBSTR (p_eventDateTime, 1, LENGTH (p_eventDateTime) - 3),
                          'MM/DD/YYYY HH24:MI:SS'));
    END IF;

    --BANNER LOGIC
    CASE
      WHEN (p_eventNotificationId = 703)
      --703 offered 'O'
      THEN
          rp_award_schedule.p_update (
                  p_aidy_code   => v_aidy_code,
                  p_pidm        => v_student_pidm,
                  p_fund_code   => p_suScholarshipCode,
                  p_period      => v_term,
                  p_term_code   => v_term,
                  p_offer_amt   => p_suAmount,
                  p_awst_code   => v_awst_code_offered,
                  p_awst_date   =>
                      TO_DATE (
                              SUBSTR (p_eventDateTime, 1, LENGTH (p_eventDateTime) - 3),
                              'MM/DD/YYYY HH24:MI:SS'));
      WHEN (p_eventNotificationId = 701) AND p_suPostType = 'Add'
      --701 posted 'A'
      THEN
        rp_award_schedule.p_update (
          p_aidy_code    => v_aidy_code,
          p_pidm         => v_student_pidm,
          p_fund_code    => p_suScholarshipCode,
          p_period       => v_term,
          p_term_code    => v_term,
          p_offer_amt    => p_suAmount,
          p_accept_amt   => p_suAmount,
          p_accept_date  =>
            TO_DATE (
              SUBSTR (p_eventDateTime, 1, LENGTH (p_eventDateTime) - 3),
              'MM/DD/YYYY HH24:MI:SS'),
          p_awst_code    => v_awst_code_accepted,
          p_awst_date    =>
            TO_DATE (
              SUBSTR (p_eventDateTime, 1, LENGTH (p_eventDateTime) - 3),
              'MM/DD/YYYY HH24:MI:SS'));
      WHEN (p_eventNotificationId = 705)
      --705 declined 'D'
      THEN
        rp_award_schedule.p_update (
          p_aidy_code   => v_aidy_code,
          p_pidm        => v_student_pidm,
          p_fund_code   => p_suScholarshipCode,
          p_period      => v_term,
          p_term_code   => v_term,
          p_offer_amt   => 0,
          p_accept_amt  => 0,
          p_awst_code   => v_awst_code_declined,
          p_awst_date   =>
            TO_DATE (
              SUBSTR (p_eventDateTime, 1, LENGTH (p_eventDateTime) - 3),
              'MM/DD/YYYY HH24:MI:SS'));
      WHEN (p_eventNotificationId = 706)
      --706 removed 'C'
      THEN
        rp_award_schedule.p_update (
          p_aidy_code   => v_aidy_code,
          p_pidm        => v_student_pidm,
          p_fund_code   => p_suScholarshipCode,
          p_period      => v_term,
          p_term_code   => v_term,
          p_offer_amt   => 0,
          p_accept_amt  => 0,
          p_awst_code   => v_awst_code_cancelled,
          p_awst_date   =>
            TO_DATE (
              SUBSTR (p_eventDateTime, 1, LENGTH (p_eventDateTime) - 3),
              'MM/DD/YYYY HH24:MI:SS'));
    END CASE;

    UPDATE baninst1.zclelog
        SET zclelog_processed = SYSDATE;
    COMMIT;

    EXCEPTION
      WHEN OTHERS THEN

      v_error_code := SQLCODE;
      v_error_message := trunc(SQLERRM, 511);

      INSERT INTO baninst1.zclerrm (zclerrm_eventid, zclerrm_code, zclerrm_message, zclerrm_create_date)
      VALUES(p_eventId, v_error_code, v_error_message, SYSDATE);
      COMMIT;

  END p_su_transaction;
END z_campuslogic_interface;
/