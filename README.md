# CampusLogic Banner Interface

This implemention consists of three CampusLogic applications; 
- Student Forms which is utilized to provide online verification document gathering to students working on FAFSA applications
- Scholarship Universe which is utilized to streamline and unify internal and external scholarship efforts
- Campus Communicator which is utilized to streamline related student communications

Originally implemented in 2016 as a standalone for Student Forms (simply called CampusLogic then), this solution was expanded to incorporate the additional integration needed to support Scholarship Universe in 2021, and Campus Communicator in 2022.

Multiple schools have contributed to this integration effort:
- Weber State University
- Utah State University
- City College of San Francisco
- Lake Michigan College
- University of the Pacific

---

## References

This integration consists of an intermediary server that sits within the local network. This server runs software provided by CampusLogic called CLCONNECT to commuinicate with the CampusLogic hosts and provide the web services required by the integration. Those web services call a custom built Oracle pacakage that resides within the local Banner Database. Due to the extensive use of APIs, the integration is near real time as the CLCONNECT servers make calls.

Banner Custom Package:
``` SQL
  BANINST1.z_campuslogic_interface
```
Primary procedures called from CLCONNECT:
``` SQL
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
    p_ccAwardYear             VARCHAR2 DEFAULT NULL);
```

The custom Oracle Package was created in collaboration with multiple schools to be shared with other schools facing a similar integration. As such, the package code is heavily documented including specification references at CampusLogic.

The package includes the scripts to build dependent tables in the file dependencies.sql.

CLCONNECT also provides an optional integration point to the Banner Document Management System (BDMS, also referred to as xtender). CLCONNECT downloads documentation images from CampusLogic hosts along with associated index files. Each document has an single index file. Multi-page documents consist of multiple images, one for each page. Powershell scripts on the CLCONNECT servers then parse though the download folder, cleans index files in preparation, and finally perform the import/index of each document into BDMS.

### From the Vendor

StudentForms / General Event Integration Documentation
- Event Notification Reference: https://campuslogicinc.freshdesk.com/support/solutions/articles/5000573254
- Event Notifications Guide: https://campuslogicinc.freshdesk.com/support/solutions/articles/5000868997-event-notifications-guide
- Web.config entries: https://github.com/campuslogic/CL-Connect/blob/master/Web.config

ScholarshipUniverse Integration Documentation
- SIS Integration Overview: https://campuslogicinc.freshdesk.com/support/solutions/articles/5000815420-sis-integration-overview
- Awards Flow Overview: https://campuslogicinc.freshdesk.com/support/solutions/articles/5000859239-awards-flow

CLCONNECT Integration Documentation
- CLCONNECT Checklist: https://campuslogicinc.freshdesk.com/support/solutions/5000165850
- CLCONNECT DataFile Upload Options: https://campuslogicinc.freshdesk.com/support/solutions/articles/5000790184-cl-connect-datafile-upload-documentation

---

## Technical Team

- Carl Ellsworth <carl.ellsworth@usu.edu> (IT, SIS Developer)
- Autumn Canfield <Autumn.canfield@usu.edu> (IT, Integration Developer)
- Steven Francom <steven.francom@usu.edu> (Financial Aid)
- Aaron Weitzell <aaron.weitzell@campuslogic.com> (Integration Manager)
- Vince Vaughn <vince.vaughn@campuslogic.com> (Progect Manager)

---

## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

- **[MIT license](http://opensource.org/licenses/mit-license.php)**
