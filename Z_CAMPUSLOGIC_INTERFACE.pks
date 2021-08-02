/* Formatted on 8/2/2021 12:44:47 PM (QP5 v5.371) */
CREATE OR REPLACE PACKAGE BANINST1.z_campuslogic_interface
AS
  PROCEDURE p_tracking_upd_api (p_pidm        VARCHAR2,
                                p_awardYear   VARCHAR2,
                                p_treqCode    VARCHAR2,
                                p_status      VARCHAR2,
                                p_sysInd      VARCHAR2);

  PROCEDURE p_transaction (p_studentId                 VARCHAR2,
                           p_awardYear                 VARCHAR2,
                           p_eventNotificationId       INTEGER,
                           p_eventId                   VARCHAR2:= NULL,
                           p_eventNotificationName     VARCHAR2:= NULL,
                           p_eventDateTime             VARCHAR2:= NULL,
                           p_sfTransactionCategoryId   INTEGER:= NULL,
                           p_sfDocumentName            VARCHAR2:= NULL,
                           p_suTermId                  VARCHAR2:= NULL,
                           p_suTermName                VARCHAR2:= NULL,
                           p_suScholarshipAwardId      VARCHAR2:= NULL,
                           p_suScholarshipName         VARCHAR2:= NULL,
                           p_suScholarshipCode         VARCHAR2:= NULL,
                           p_suAmount                  NUMBER:= NULL,
                           p_suPostBatchUser           VARCHAR2:= NULL,
                           p_suPostType                VARCHAR2:= NULL,
                           p_suTermComments            VARCHAR2:= NULL);
END z_campuslogic_interface;
/
