/* Formatted on 8/31/2021 1:13:19 PM (QP5 v5.371) */
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

CREATE TABLE BANINST1.ZCLXWLK
(
  ZCLXWLK_AIDY_CODE       VARCHAR2 (4 CHAR) NOT NULL,
  ZCLXWLK_TREQ_CODE       VARCHAR2 (6 CHAR),
  ZCLXWLK_DOCUMENT        VARCHAR2 (100 CHAR) NOT NULL,
  ZCLXWLK_CAMPUS_LOGIC    VARCHAR2 (1 CHAR) NOT NULL,
  ZCLXWLK_YEAR_BASED      VARCHAR2 (1 CHAR) NOT NULL,
  ZCLXWLK_CROSSWALKED     VARCHAR2 (1 CHAR) NOT NULL
);

CREATE TABLE baninst1.ZCLERRM
(
  ZCLERRM_EVENTID        VARCHAR2 (100),
  ZCLERRM_CODE           INTEGER,
  ZCLERRM_MESSAGE        VARCHAR2 (300),
  ZCLERRM_CREATE_DATE    DATE DEFAULT SYSDATE
);
/