/* Formatted on 10/31/2022 1:05:38 PM (QP5 v5.388) */
CREATE OR REPLACE PACKAGE BANINST1.z_campuslogic_interface
AS
  PROCEDURE p_tracking_upd_api (p_pidm        VARCHAR2,
                                p_awardYear   VARCHAR2,
                                p_treqCode    VARCHAR2,
                                p_status      VARCHAR2,
                                p_sysInd      VARCHAR2);

  PROCEDURE p_sf_transaction (
    p_studentId                 VARCHAR2,
    p_eventNotificationId       INTEGER,
    p_eventId                   VARCHAR2 DEFAULT NULL,
    p_eventNotificationName     VARCHAR2 DEFAULT NULL,
    p_sfAwardYear               VARCHAR2 DEFAULT NULL,
    p_sfTransactionCategoryId   INTEGER DEFAULT NULL,
    p_sfDocumentName            VARCHAR2 DEFAULT NULL);

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
    p_suTermComments          VARCHAR2 DEFAULT NULL);

  PROCEDURE p_cc_transaction (
    p_studentId               VARCHAR2,
    p_eventNotificationId     INTEGER,
    p_eventId                 VARCHAR2 DEFAULT NULL,
    p_eventNotificationName   VARCHAR2 DEFAULT NULL,
    p_ccAwardYear             VARCHAR2 DEFAULT NULL,
    p_alTemplateType          VARCHAR2 DEFAULT NULL);
END z_campuslogic_interface;
/
