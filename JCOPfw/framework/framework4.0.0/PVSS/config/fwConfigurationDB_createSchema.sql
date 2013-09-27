----------------------------------------------------------------------------
--
-- This file is a part of the JCOP Framework Configuration Database Tool
--
-- it is to be used by this tool, and it is NOT guaranteed to work with
-- other tools (such as sqplus), even though it may work.
--
-- Note te following assumptions in the format of this SQL file
-- (not following this rules causes the "dummy" parser of ConfDB fail)
-- *) each command needs to be ended by semicolon followed by an empty
--   newline. There must be no characters after the semicolon!
-- *) PL/SQL block needs to be ended by double semicolon followed by
--    an empty line 
--
-- (c) CERN IT/CO-BE
----------------------------------------------------------------------------



  CREATE TABLE "HIERARCHIES"
   (	"HVER" NUMBER NOT NULL ENABLE,
	"HTYPE" VARCHAR2(8),
	"DESCR" VARCHAR2(128),
	"VALID_FROM" DATE,
	"VALID_TO" DATE,
	 CONSTRAINT "HVER_PK" PRIMARY KEY ("HVER") ENABLE
   )
 ;

  CREATE TABLE "DEVICE_TYPES"
   (	"DPT_ID" NUMBER NOT NULL ENABLE,
	"DPTYPE" VARCHAR2(32) NOT NULL ENABLE,
	"VALID_TO" DATE,
	 CONSTRAINT "DEVICE_TYPES_PK" PRIMARY KEY ("DPT_ID") ENABLE
   )
 ;

  CREATE TABLE "ITEMS"
   (	"HVER" NUMBER,
	"ID" NUMBER NOT NULL ENABLE,
	"PARENT" NUMBER,
	"NAME" VARCHAR2(64) NOT NULL ENABLE,
	"TYPE" VARCHAR2(32) NOT NULL ENABLE,
	"DETAIL" VARCHAR2(32),
	"DESCRIPTION" VARCHAR2(128),
	"DPID" NUMBER,
	"DPNAME" VARCHAR2(512),
	"DPT_ID" NUMBER,
	 CONSTRAINT "ITEMS_PK" PRIMARY KEY ("ID") ENABLE,
	 CONSTRAINT "ITEMS_FK_HVER" FOREIGN KEY ("HVER")
	  REFERENCES "HIERARCHIES" ("HVER") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "ITEMS_FK_PARRENT" FOREIGN KEY ("PARENT")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "ITEMS_FK_DPTID" FOREIGN KEY ("DPT_ID")
	  REFERENCES "DEVICE_TYPES" ("DPT_ID") ENABLE
   )
 ;


  CREATE TABLE "RECIPES"
   (	"TAGID" NUMBER NOT NULL ENABLE,
	"NAME" VARCHAR2(64) NOT NULL ENABLE,
	"HVER" NUMBER,
	"DESCRIPTION" VARCHAR2(128),
	"RECIPE_TYPE" VARCHAR2(128),
	 CONSTRAINT "RECIPES_PK" PRIMARY KEY ("TAGID") ENABLE,
	 CONSTRAINT "RECIPES_FK_HVER" FOREIGN KEY ("HVER")
	  REFERENCES "HIERARCHIES" ("HVER") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "RECIPE_VERSIONS"
   (	"RVER" NUMBER NOT NULL ENABLE,
	"DESCRIPTION" VARCHAR2(255),
	"USER_CREATED" VARCHAR2(16),
	"DATE_CREATED" DATE,
	 CONSTRAINT "RECIPE_VERSIONS_PK" PRIMARY KEY ("RVER") ENABLE
   )
 ;


  CREATE TABLE "RECIPE_DATA"
   (	"PROPID" NUMBER NOT NULL ENABLE,
	"RVER" NUMBER NOT NULL ENABLE,
	"ID" NUMBER NOT NULL ENABLE,
	"HAS_VALUE" NUMBER,
	"HAS_ALERT" NUMBER,
	"PROPVALUE" VARCHAR2(4000),
	"BVALUE" BLOB,
	"ALERT_TYPE" NUMBER,
	"ALERT_ACTIVE" NUMBER,
	"ALERT_CLASSES" VARCHAR2(256),
	"ALERT_TEXTS" VARCHAR2(1024),
	"ALERT_LIMITS" VARCHAR2(128),
	"DEVELEM_ID" NUMBER,
	 CONSTRAINT "RECIPE_DATA_PK" PRIMARY KEY ("PROPID") ENABLE,
	 CONSTRAINT "RD_FK_ID" FOREIGN KEY ("ID")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "RECIPE_FK_VERSION" FOREIGN KEY ("RVER")
	  REFERENCES "RECIPE_VERSIONS" ("RVER") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "RECIPE_TAGS"
   (	"TAGID" NUMBER NOT NULL ENABLE,
	"PROPID" NUMBER NOT NULL ENABLE,
	"VALID_FROM" DATE,
	"VALID_TO" DATE,
	 CONSTRAINT "RT_FK_PROPID" FOREIGN KEY ("PROPID")
	  REFERENCES "RECIPE_DATA" ("PROPID") ON DELETE CASCADE ENABLE
   )
 ;




  CREATE TABLE "DEVICE_ELEMENTS"
   (	"DEVELEM_ID" NUMBER NOT NULL ENABLE,
	"DPT_ID" NUMBER NOT NULL ENABLE,
	"ELEMENTNAME" VARCHAR2(128) NOT NULL ENABLE,
	"ELEMENTTYPE" NUMBER NOT NULL ENABLE,
	 CONSTRAINT "DEVICE_ELEMENTS_PK" PRIMARY KEY ("DEVELEM_ID") ENABLE,
	 CONSTRAINT "DEVICE_ELEMENTS_FK_DPT_ID" FOREIGN KEY ("DPT_ID")
	  REFERENCES "DEVICE_TYPES" ("DPT_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ITEMS"
   (	"CITEM_ID" NUMBER NOT NULL ENABLE,
	"DPT_ID" NUMBER NOT NULL ENABLE,
	"ITEM_ID" NUMBER NOT NULL ENABLE,
	 CONSTRAINT "CONFIG_ITEMS_PK" PRIMARY KEY ("CITEM_ID") ENABLE,
	 CONSTRAINT "CONFIG_ITEMS_FK_ITEM_ID" FOREIGN KEY ("ITEM_ID")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_ITEMS_FK_DPT_ID" FOREIGN KEY ("DPT_ID")
	  REFERENCES "DEVICE_TYPES" ("DPT_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ITEM_PROPERTIES"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"CITEM_ID" NUMBER NOT NULL ENABLE,
	"DEVELEM_ID" NUMBER NOT NULL ENABLE,
	"VALUE" VARCHAR2(4000),
	"BVALUE" BLOB,
	 CONSTRAINT "CONF_IPROP_PK" PRIMARY KEY ("IPROP_ID") ENABLE,
	 CONSTRAINT "CONF_IPROP_FK_CITEM_ID" FOREIGN KEY ("CITEM_ID")
	  REFERENCES "CONFIG_ITEMS" ("CITEM_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONF_IPROP_FK_DEVELEM_ID" FOREIGN KEY ("DEVELEM_ID")
	  REFERENCES "DEVICE_ELEMENTS" ("DEVELEM_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_DESC"
   (	"CONF_ID" NUMBER NOT NULL ENABLE,
	"CONF_TAG" VARCHAR2(32) NOT NULL ENABLE,
	"DESCRIPTION" VARCHAR2(255),
	"HVER" NUMBER,
	 CONSTRAINT "CONFIG_DESC_PK" PRIMARY KEY ("CONF_ID") ENABLE,
	 CONSTRAINT "CONFIG_DESC_FK_HVER" FOREIGN KEY ("HVER")
	  REFERENCES "HIERARCHIES" ("HVER") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_TAGS"
   (	"CONF_ID" NUMBER NOT NULL ENABLE,
	"CITEM_ID" NUMBER NOT NULL ENABLE,
	"VALID_FROM" DATE NOT NULL ENABLE,
	"VALID_TO" DATE,
	 CONSTRAINT "CONFIG_TAGS_FK_CONF_ID" FOREIGN KEY ("CONF_ID")
	  REFERENCES "CONFIG_DESC" ("CONF_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_TAGS_FK_CITEM_ID" FOREIGN KEY ("CITEM_ID")
	  REFERENCES "CONFIG_ITEMS" ("CITEM_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "REFERENCES"
   (	"REFVER" NUMBER NOT NULL ENABLE,
	"ID" NUMBER NOT NULL ENABLE,
	"REF_ID" NUMBER NOT NULL ENABLE,
	"VALID_FROM" DATE,
	"VALID_TO" DATE,
	 CONSTRAINT "REFERENCES_FK_REFVER" FOREIGN KEY ("REFVER")
	  REFERENCES "CONFIG_DESC" ("CONF_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "REFERENCES_FK_ID" FOREIGN KEY ("ID")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "REFERENCES_FK_REF_ID" FOREIGN KEY ("REF_ID")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ADDRESSES"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"TYPE" VARCHAR2(16),
	"DRIVER" NUMBER,
	"DIRECTION" NUMBER,
	"DATATYPE" NUMBER,
	"ACTIVE" NUMBER,
	"OPTIONS" VARCHAR2(255),
	 CONSTRAINT "CONFIG_ADDRESSES_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ALERTS"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"TYPE" NUMBER,
	"ACTIVE" NUMBER,
	 CONSTRAINT "CONFIG_ALERTS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_DPEALERTS"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"TEXTS" VARCHAR2(1024),
	"CLASSES" VARCHAR2(256),
	"LIMITS" VARCHAR2(64),
	 CONSTRAINT "CONFIG_DPEALERTS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_SUMALERTS"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"TEXTS" VARCHAR2(128),
	"CLASS" VARCHAR2(64),
	"SUMDPELIST" VARCHAR2(4000),
	 CONSTRAINT "CONFIG_SUMALERTS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ALERTS_MISC"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"PANEL" VARCHAR2(64),
	"PANELPARAMS" VARCHAR2(128),
	"HELP" VARCHAR2(64),
	 CONSTRAINT "CONFIG_AMISC_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ARCHIVING"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"CLASSNAME" VARCHAR2(32),
	"TYPE" NUMBER,
	"SMOOTHPROC" NUMBER,
	"DEADBAND" NUMBER,
	"TIMEINTVAL" NUMBER,
	"ACTIVE" NUMBER,
	 CONSTRAINT "CONFIG_ARCHIVING_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_DPFUNCTIONS"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"PARAMS" VARCHAR2(255),
	"GLOBALS" VARCHAR2(255),
	"DEFINITION" VARCHAR2(255),
	 CONSTRAINT "CONFIG_DPFUNCTIONS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_CONVERSIONS"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"TYPE" NUMBER,
	"CONVTYPE" NUMBER,
	"CONVORDER" NUMBER,
	"ARGUMENTS" VARCHAR2(64),
	 CONSTRAINT "CONFIG_CONVERSIONS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_PVRANGES"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"MINVALUE" NUMBER,
	"MAXVALUE" NUMBER,
	"NEGRANGE" NUMBER,
	"IGNOUTSIDE" NUMBER,
	"INCLMIN" NUMBER,
	"INCLMAX" NUMBER,
	"PVRVALS" VARCHAR2(512),
	"PVRTYPE" NUMBER,
	 CONSTRAINT "CONFIG_PVRANGES_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_SMOOTHING"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"PROC" NUMBER,
	"DEADBAND" NUMBER,
	"TIMEINTVAL" NUMBER,
	 CONSTRAINT "CONFIG_SMOOTHING_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "CONFIG_UF"
   (	"IPROP_ID" NUMBER NOT NULL ENABLE,
	"UNIT" VARCHAR2(16),
	"FMT" VARCHAR2(16),
	 CONSTRAINT "CONFIG_UF_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEM_PROPERTIES" ("IPROP_ID") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE INDEX "ITEMS_DPNAME_IDX" ON "ITEMS" ("DPNAME");
  CREATE INDEX "ITEMS_PARENT_AND_ID" ON "ITEMS" ("PARENT", "ID");
  CREATE INDEX "ITEMS_PARENT_IDX" ON "ITEMS" ("PARENT");
  CREATE UNIQUE INDEX "CONFIG_DESC_CONF_TAG_IDX" ON "CONFIG_DESC" ("CONF_TAG");
  CREATE UNIQUE INDEX "CONFIG_ADDRESSES_IPROP_ID_IDX" ON "CONFIG_ADDRESSES" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_ALERTS_IPROP_ID_IDX" ON "CONFIG_ALERTS" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_DPEALERTS_IPROP_ID_IDX" ON "CONFIG_DPEALERTS" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_SUMALERTS_IPROP_ID_IDX" ON "CONFIG_SUMALERTS" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_AMISC_IPROP_ID_IDX" ON "CONFIG_ALERTS_MISC" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_ARCHIVING_IPROP_ID_IDX" ON "CONFIG_ARCHIVING" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_DPF_IPROP_ID_IDX" ON "CONFIG_DPFUNCTIONS" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_CONV_IPROP_ID_IDX" ON "CONFIG_CONVERSIONS" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_PVR_IPROP_ID_IDX" ON "CONFIG_PVRANGES" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_SMOOTHING_IPROP_ID_IDX" ON "CONFIG_SMOOTHING" ("IPROP_ID");
  CREATE UNIQUE INDEX "CONFIG_UF_IPROP_ID_IDX" ON "CONFIG_UF" ("IPROP_ID");

  CREATE OR REPLACE FORCE VIEW "V_ITEM_NAMES" ("HVER", "ID", "NAME", "DPNAME") AS
  SELECT
    hver,
    id,
    name,
    dpname
FROM ITEMS i
 ;


  CREATE OR REPLACE FORCE VIEW "V_ITEMS" ("ITEM_ID", "PARENT_ID", "HVER", "NAME", "DPNAME", "PARENT_DPNAME", "DPTYPE", "TYPE", "DETAIL", "DESCRIPTION", "DPID") AS
  SELECT
    i.id,
    i.parent,
    i.hver,
    i.name,
    i.dpname,
    (select dpname from v_item_names p where p.id=i.parent),
    (select dptype from device_types where dpt_id=i.dpt_id),
    i.type,
    i.detail,
    i.description,
    i.dpid
FROM items i
 ;


  CREATE OR REPLACE FORCE VIEW "V_RECIPESALL" ("PROPID", "PROPTYPE", "ITEM_ID", "DEVELEM_ID", "RECIPE_VER", "VALID_FROM", "VALID_TO", "TAG", "RECIPE_TYPE", "RECIPE_COMMENT", "HIERARCHY", "DPNAME", "PROPERTY", "DPTYPE", "DETAIL", "ELEMENTTYPE", "HAS_VALUE", "HAS_ALERT", "PROPVALUE", "ALERT_TYPE", "ALERT_ACTIVE", "ALERT_CLASSES", "ALERT_TEXTS", "ALERT_LIMITS") AS
  SELECT
rt.propid,
de.elementtype,
i.item_id,
rd.develem_id,
rd.rver,
rt.valid_from,
rt.valid_to,
r.name,
r.recipe_type,
r.description,
h.htype,
i.dpname,
de.elementname,
i.dptype,
i.detail,
de.elementtype,
rd.has_value,
rd.has_alert,
rd.propvalue,
rd.alert_type,
rd.alert_active,
rd.alert_classes,
rd.alert_texts,
rd.alert_limits
FROM recipe_tags rt, recipes r, recipe_data rd ,v_items i,hierarchies h, device_elements de
WHERE rt.propid=rd.propid
AND r.tagid=rt.tagid
AND h.hver=i.hver
AND i.item_id=rd.id
AND de.develem_id=rd.develem_id(+)

 ;


  CREATE OR REPLACE FORCE VIEW "V_REFERENCES" ("ITEM_ID", "REF_ID", "CONFIG_ID", "DPNAME", "REFDPNAME", "CONFIG_TAG") AS
  select r.id, r.ref_id, r.refver,i.dpname, j.dpname, c.conf_tag
from v_item_names i, v_item_names j, references r, config_desc c
where r.id=i.id and r.ref_id=j.id and
    r.refver=c.conf_id and r.valid_to is null
 ;


  CREATE OR REPLACE FORCE VIEW "V_CONFIG_ITEMS" ("ITEM_ID", "CITEM_ID", "DPT_ID", "NAME", "DPNAME", "DPTYPE", "TAG", "HVER", "DESCRIPTION", "TYPE", "MODEL", "PARENT_ID", "DPID") AS
  select i.item_id, c.citem_id, t.dpt_id,i.name, i.dpname,t.dptype, d.conf_tag,
	i.hver, i.description,i.type,i.detail,i.parent_id, i.dpid
from   v_items i, config_items c, device_types t, config_desc d, config_tags v
where  i.item_id=c.item_id and t.dpt_id=c.dpt_id and d.conf_id=v.conf_id
  and v.citem_id=c.citem_id and v.valid_to is null
 ;


  CREATE OR REPLACE FORCE VIEW "V_DEVICE_CONFIGS" ("DPT_ID", "DEVELEM_ID", "DPTYPE", "ELEMENTNAME", "ELEMENTTYPE") AS
  select d.dpt_id, e.develem_id, d.dpType, e.elementName, e.elementType
from device_types d, device_elements e
where d.dpt_id=e.dpt_id(+) and d.valid_to is null
 ;


  CREATE OR REPLACE FORCE VIEW "V_ITEM_PROPERTIES" ("CITEM_ID", "IPROP_ID", "DEVELEM_ID", "ITEM_DPNAME", "DPTTYPE", "PROP_NAME", "DPE_NAME", "DPE_TYPE", "VALUE", "TAG") AS
  select c.citem_id, c.iprop_id, c.develem_id,i.dpname, i.dptype, p.elementname,
	i.dpname||p.elementname,p.elementtype,c.value, i.tag
from config_item_properties c, v_config_items i, v_device_configs p
where p.develem_id=c.develem_id and i.citem_id=c.citem_id
 ;


  CREATE OR REPLACE FORCE VIEW "V_CONFIG_ALERTS" ("IPROP_ID", "TYPE", "ACTIVE", "TEXTS", "CLASSES", "LIMITS", "SUMDPELIST", "PANEL", "PANELPARAMS", "HELP") AS
  select
al.iprop_id,
al.type,
al.active,
CASE al.type WHEN 59 THEN s.texts ELSE a.texts END,
CASE al.type WHEN 59 THEN s.class ELSE a.classes END,
a.limits,
s.sumdpelist,
m.panel,
m.panelParams,
m.help
from config_alerts al, config_dpealerts a, config_sumalerts s, config_alerts_misc m
where a.iprop_id(+)=al.iprop_id
and   s.iprop_id(+)=al.iprop_id
and   m.iprop_id(+)=al.iprop_id
 ;



   CREATE SEQUENCE  "CITEM_ID_SEQ"   INCREMENT BY 1 START WITH 1 CACHE 10 NOORDER  NOCYCLE;
   CREATE SEQUENCE  "CONF_ID_SEQ"  INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;
   CREATE SEQUENCE  "DEVELEM_ID_SEQ"  INCREMENT BY 1 START WITH 1 CACHE 10 NOORDER  NOCYCLE;
   CREATE SEQUENCE  "DPT_ID_SEQ"  INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;
   CREATE SEQUENCE  "IPROP_ID_SEQ"  INCREMENT BY 1 START WITH 1 CACHE 100 NOORDER  NOCYCLE;
   CREATE SEQUENCE  "ITEMS_ID_SEQ"  INCREMENT BY 1 START WITH 1 CACHE 10 NOORDER  NOCYCLE;
   CREATE SEQUENCE  "RECIPES_RVER_SEQ"  INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;
   CREATE SEQUENCE  "RECIPES_TAGID_SEQ"  INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;
   CREATE SEQUENCE  "RECIPE_DATA_PROPID_SEQ"  INCREMENT BY 1 START WITH 1 CACHE 10 NOORDER  NOCYCLE;


  CREATE GLOBAL TEMPORARY TABLE "CDB_API_PARAMS"
   (	"I1" NUMBER,
	"I2" NUMBER,
	"I3" NUMBER,
	"I4" NUMBER,
	"I5" NUMBER,
	"I6" NUMBER,
	"I7" NUMBER,
	"I8" NUMBER,
	"S1" VARCHAR2(512),
	"S2" VARCHAR2(512),
	"S3" VARCHAR2(256),
	"S4" VARCHAR2(256),
	"S5" VARCHAR2(256),
	"S6" VARCHAR2(256),
	"S7" VARCHAR2(4000),
	"S8" VARCHAR2(4000),
	"S9" VARCHAR2(16),
	"S10" VARCHAR2(16),
	"D1" DATE,
	"D2" DATE,
	"B1" BLOB
   ) ON COMMIT PRESERVE ROWS
 ;


  CREATE GLOBAL TEMPORARY TABLE "TMP_ITEM_PROPS"
   (	"IPROP_ID" NUMBER,
	"DPENAME" VARCHAR2(128)
   ) ON COMMIT DELETE ROWS
 ;


-----------------------------------------------------------------------------
--
-- The PL/SQL package containing fwConfigurationDB functions
--
-- Unofficial documentation is at
-- https://twiki.cern.ch/twiki/bin/view/Controls/ConfigurationDBTool#PlSqlApi
-----------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE fwConfigurationDB
IS

PROCEDURE t_getSequenceNumbers(
	sequenceName      IN VARCHAR2,
	n                 IN NUMBER DEFAULT 1)
;

PROCEDURE getDevicesInRecipe(
	recipeName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL,
	validAt IN DATE DEFAULT NULL)
;

PROCEDURE getDevicesInConfiguration(
	configurationName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL)
;

PROCEDURE getRecipe(
	recipeName        IN VARCHAR2,
	validAt           IN DATE DEFAULT NULL)
;

PROCEDURE getRecipesList(
    recipeNameFilter IN varchar2 default null,
    deviceFilter IN varchar2 default null,
    recipeCommentFilter IN varchar2 default '*',
    recipeTypeFilter IN varchar2 default '*')
;

PROCEDURE getConfigurationsList(
    configurationNameFilter IN varchar2 default null)
;

PROCEDURE createRecipe(
	recipeName        IN VARCHAR2,
	recipeDescription IN VARCHAR2 default null)
;

PROCEDURE storeRecipe(
	recipeName        IN VARCHAR2,
	versionDescription IN VARCHAR2 DEFAULT NULL,
	userCreated IN VARCHAR2 DEFAULT NULL )
;


PROCEDURE getReferences(
	configurationName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
;

PROCEDURE setReferences(
	configurationName IN VARCHAR2)
;

PROCEDURE getReferenceHistory(
	configurationName IN VARCHAR2,
	startDate IN DATE DEFAULT NULL,
	endDate IN DATE DEFAULT NULL)
;


-- this one is for private use
FUNCTION checkInputTable(checkS2 number default 1) RETURN NUMBER;

END fwConfigurationDB;
/


CREATE OR REPLACE PACKAGE BODY fwConfigurationDB

IS

TYPE recipeRecordType is RECORD (
	    device	v_recipesAll.dpname%type,
	    property  	v_recipesAll.property%type,
	    deviceId	v_recipesAll.item_id%type,
	    propId 	v_recipesAll.propid%type,
	    propType 	v_recipesAll.proptype%type,
	    recipeVer	v_recipesAll.recipe_Ver%type,
	    dpType	v_recipesAll.dptype%type,
	    deviceModel	v_recipesAll.detail%type,
	    validFrom 	v_recipesAll.valid_from%type,
	    validTo 	v_recipesAll.valid_to%type,
	    hasValue 	v_recipesAll.has_Value%type,
	    hasAlert 	v_recipesAll.has_Alert%type,
	    propValue 	v_recipesAll.propvalue%type,
	    hierarchy 	v_recipesAll.hierarchy%type,
	    alertType 	v_recipesAll.alert_Type%type,
	    alertActive v_recipesAll.alert_Active%type,
	    alertClasses v_recipesAll.alert_Classes%type,
	    alertTexts 	v_recipesAll.alert_Texts%type,
	    alertLimits v_recipesAll.alert_Limits%type

);

-----------------------------------------------
PROCEDURE t_getSequenceNumbers(
	sequenceName IN varchar2,
	n            IN NUMBER)
IS
	idx number:=1;
	val NUMBER;
	NoSuchSequence exception;
BEGIN
	EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
	LOOP
	    EXECUTE IMMEDIATE 'SELECT '||sequenceName||'.NEXTVAL FROM DUAL' INTO val;
	    INSERT INTO cdb_api_params(i1) VALUES (val);
	    idx:=idx+1;
	    exit when idx>n;
	END LOOP;

	EXCEPTION
	    WHEN NoSuchSequence
	    THEN
		RAISE_APPLICATION_ERROR(-20001, 'Bad sequence name:'||TO_CHAR(sequenceName));
END t_getSequenceNumbers;


-----------------------------------------------------------------------------
-- This is a private function that checks the consistency of input in the  
-- CDB_API_PARAMS table. We assume that input data is only in column S1    
-- or - optionally if checkS2 parameter is  null - also in column S2.      
-- All other columns MUST be empty - otherwise we interpret this situation 
-- as the user forgot to cleanup the table after the previous use, and     
-- we report an error                                                      
-----------------------------------------------------------------------------
FUNCTION checkInputTable(checkS2 number default 1) RETURN NUMBER
IS
    numEntries NUMBER;
    checkStmt  varchar2(2000);
BEGIN

    checkStmt := 'SELECT count(*) from CDB_API_PARAMS
	where I1 is not null 
	OR i2 is not null
	OR i3 is not null
	OR i4 is not null
	OR i5 is not null
	OR i6 is not null
	OR i7 is not null
	OR i8 is not null
	OR s3 is not null
	OR s4 is not null
	OR s5 is not null
	OR s6 is not null
	OR s7 is not null
	OR s8 is not null
	OR s9 is not null
	OR s10 is not null
	OR d1 is not null
	OR d2 is not null
	OR b1 is not null';
		
    if (checkS2 is not null) then
	checkStmt := checkStmt || ' or S2 is not null';
    end if;

    execute immediate checkStmt INTO numEntries;

    if (numEntries > 0) THEN
	RAISE_APPLICATION_ERROR(-20001,'fwConfigurationDB: Input table CDB_API_PARAM not consistent. Forgot to TRUNC it before use?');
    END IF;
    
    -- count the number of data rows and return it
    SELECT count(*) INTO numEntries from CDB_API_PARAMS;


    RETURN numEntries;
END;


-----------------------------------------------------------
-- finds the devices that are present in a recipe        
-- note that it appends the result to CDB_API_PARAMS(s1) 
-- note also that is accepts "*" as wildcard character   
--   and not only the Oracle-specific "%"                
-----------------------------------------------------------
PROCEDURE getDevicesInRecipe(
	recipeName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL,
	validAt IN DATE DEFAULT NULL)
IS

	num number;
	devFilter varchar2(128) := deviceFilter;
	TYPE recCurType IS REF CURSOR;
	recipesCur recCurType;

BEGIN
	-- check recipe name
	SELECT count(*)  INTO num from RECIPES WHERE name=recipeName;
	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getDevicesInRecipe: no such recipe:'||recipeName);
	end if;

	-- verify that input table is correct (no entries apart from - maybe - S1)
	SELECT checkInputTable() INTO num from DUAL;    

	-- make sure the filter is right
	if devFilter = '' then devFilter:='%'; end if;
	if devFilter IS NULL then devFilter:='%'; end if;
	

	IF validAt IS NULL THEN 
	    insert into cdb_api_params(s1) select unique dpname from v_recipesAll r
		where r.tag=recipeName
		and r.valid_to is null
		and r.dpname like replace(devFilter,'*','%');		
	else 
	    insert into cdb_api_params(s1) select unique dpname from v_recipesAll r
		where r.tag=recipeName
		AND VALID_FROM <= validAt
		AND ( (VALID_TO IS NULL) OR (VALID_TO >= validAt ) )
		and r.dpname like replace(devFilter,'*','%');
	end if;
	


END;


PROCEDURE getRecipe(
	recipeName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
IS

	num number;
	
	recipeData recipeRecordType;
	outTblReady NUMBER := NULL;

	TYPE recCurType IS REF CURSOR return recipeRecordType;
	recipesCur recCurType;

BEGIN

	-- check the recipe name 
	SELECT count(*)  INTO num from RECIPES WHERE name=recipeName;
	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getRecipe: no such recipe:'||recipeName);
	end if;

	-- verify that the input in the CDB_API_PARAMS is right
	-- checkInputTable() will throw ORA -20001 if the table is not OK
	-- otherwise it will return the number of entries
	SELECT checkInputTable() INTO num from DUAL;
	
	-- prepare the cursor. If validTo is null the actual SELECT is much simpler...
	IF validAt IS NULL THEN 

	
	    if num = 0 then 
		--  no device list specified
		open recipesCur FOR 
		    select dpname,
			property,
			item_id,
			propid,
			proptype,
			recipe_Ver,
			dptype,
			detail,
			valid_from,
			valid_to,
			has_value,
			has_alert,
			propvalue,
			hierarchy,
			alert_Type,
			alert_Active,
			alert_Classes,
			alert_Texts,
		    alert_Limits 
		    from v_recipesAll
		    where tag=recipeName
		    and valid_to is null
		    ORDER BY ITEM_ID;
	    else 
		open recipesCur FOR 
		    select dpname,
			property,
			item_id,
			propid,
			proptype,
			recipe_Ver,
			dptype,
			detail,
			valid_from,
			valid_to,
			has_value,
			has_alert,
			propvalue,
			hierarchy,
			alert_Type,
			alert_Active,
			alert_Classes,
			alert_Texts,
			alert_Limits 
		    from v_recipesAll rec
		    where rec.tag=recipeName
		    and rec.valid_to is null
		    and rec.dpname in (select S1 from cdb_api_params)
		    ORDER BY rec.ITEM_ID;
	    end if;

	ELSE
	    if num = 0 then 
		--  no device list specified
		open recipesCur FOR 
		    select dpname,property,item_id,propid,proptype,recipe_Ver,
			dptype,
			detail,
			valid_from,valid_to,
			has_value,
			has_alert,
		    propvalue,hierarchy,alert_Type,alert_Active,alert_Classes,alert_Texts,alert_Limits 
		    from v_recipesAll 
		    where tag=recipeName
		    AND VALID_FROM <= validAt
		    AND ( (VALID_TO IS NULL) OR (VALID_TO >= validAt ) )
		    ORDER BY ITEM_ID;
	    else 
		open recipesCur FOR 
		    select dpname,property,item_id,propid,proptype,recipe_Ver,
			dptype,
			detail,
			valid_from,valid_to,
			has_value,
			has_alert,
		    propvalue,hierarchy,alert_Type,alert_Active,alert_Classes,alert_Texts,alert_Limits 
		    from v_recipesAll rec
		    where tag=recipeName
		    and dpname in (select s1 from cdb_api_params)
		    AND VALID_FROM <= validAt
		    AND ( (VALID_TO IS NULL) OR (VALID_TO >= validAt ) )
		    ORDER BY ITEM_ID;
	    end if;


	END IF;


	loop
		fetch recipesCur into recipeData;

		-- only here we should clean the input table! i.e. after the first fetch!
		if outTblReady IS NULL then
		    EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
		    outTblReady:=1;
		end if;

		exit when recipesCur%notfound;

		 insert into CDB_API_PARAMS(
		    i1,i2,i3,i4,i5,i6,i7,i8,
		    s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,
		    d1,d2,b1
		 ) values( 
		    recipeData.propId, 		--i1
		    recipeData.propType, 	--i2
		    recipeData.recipeVer, 	--i3
		    recipeData.hasValue, 	--i4
		    recipeData.hasAlert, 	--i5
		    recipeData.alertType, 	--i6
		    recipeData.alertActive, 	--i7
		    recipeData.deviceId,	--i8
		    recipeData.device, 		--s1 (512)
		    recipeData.property,	--s2 (512)
		    recipeData.dpType, 	--s3 (256)
		    recipeData.deviceModel, 	--s4 (256)
		    recipeData.alertLimits, 	--s5 (256)
		    recipeData.alertClasses, 	--s6 (256)
		    recipeData.alertTexts, 	--s7 (4000)
		    recipeData.propValue,	--s8 (4000)
		    recipeData.hierarchy,       --s9 (16)
		    NULL,                       --s10 (16)
		    recipeData.validFrom, 	--d1
		    recipeData.validTo, 	--d2
		    NULL  			--b1
		 );

	end loop;

	close recipesCur;

END;

-------------------------------------
PROCEDURE createRecipe(
	recipeName        IN VARCHAR2,
	recipeDescription IN VARCHAR2 DEFAULT NULL)
IS
	num number;

BEGIN

	-- check the recipe name 
	SELECT count(tagid) INTO num from RECIPES WHERE name=recipeName;

	if (num > 0) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.createRecipe: recipe already exists:'||recipeName);
	end if;
	
	insert into recipes(tagid, name,hver,description,recipe_type)
	    values(RECIPES_TAGID_SEQ.NEXTVAL,recipeName,NULL,recipeDescription,NULL);


END;


-------------------------------------
PROCEDURE storeRecipe(
	recipeName        IN VARCHAR2,
	versionDescription IN VARCHAR2 DEFAULT NULL,
	userCreated	IN VARCHAR2 DEFAULT NULL)
IS
	num number;

	curTime cdb_api_params.d1%TYPE := SYSDATE;
	recipeId recipes.tagid%TYPE;

	rVer number;
	devName cdb_api_params.s1%TYPE;
	propName cdb_api_params.s2%TYPE;
	
	TYPE refCurType IS REF CURSOR;
	cur refCurType;

BEGIN

	-- check the recipe name 
	open cur for SELECT tagid from RECIPES WHERE name=recipeName;
	fetch cur into recipeId;

	if (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.storeRecipe: no such recipe:'||recipeName);
	end if;
	close cur;
	
	--complete datapoint ID's:
	update cdb_api_params c set i8=(
	    select i.id from items i where i.dpname=c.s1);


	-- make sure that all the devices were resolved - otherwise report an error
	open cur for 
	    select s1 from cdb_api_params where i8 is null;
	fetch cur into devName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20023, 'fwConfigurationDB.storeRecipe: Device not found in database:'||devName);
	end if;
	close cur;



	-- complete DpElement's ID
	update cdb_api_params c set i2=(
	    select vdc.develem_id from v_device_configs vdc, items i
		where vdc.elementname=c.s2
		AND vdc.dpt_id=i.dpt_id
		and i.id=i8
	    );

	-- make sure that all the properties were resolved - otherwise report an error
	open cur for 
	    select s1,s2 from cdb_api_params where i2 is null;
	fetch cur into devName,propName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20024, 'fwConfigurationDB.storeRecipe: Device element not found in database:'||devName||propName);
	end if;
	close cur;


	-- generate next ordinal numver for Recipe Version, and store new version
	EXECUTE IMMEDIATE 'SELECT RECIPES_RVER_SEQ.NEXTVAL FROM DUAL' INTO rVer;

	insert into recipe_versions(rver,description,user_created,date_created)
	    values(rver,versionDescription,userCreated,curTime);

	update cdb_api_params set i3=rVer;


	-- STEP 1: for the elements, for which we already have PropId passed in I1,
	-- we simply do the manipulation with tags, and do not store the data again!
	
	-- *) remove the entries from CDB_API_PARAMS which are already up to date
	--    we do not need to do anything there!

	delete from cdb_api_params 
	    where i1 in (select propid from recipe_tags where valid_to is null and tagid=recipeId);
	    
	-- *) invalidate previous tags
    	update recipe_tags rt set valid_to=curTime where
	    propid IN (SELECT i1 FROM CDB_API_PARAMS c where (c.i1 is not null) ) and tagid=recipeId;

	-- *) insert the new tags into the tags table
        insert into recipe_tags(tagid,propid,valid_from,valid_to)
            select REC_ID,cdb.i1,CUR_TIM,NULL
            from (select recipeId REC_ID, curtime CUR_TIM  from dual), CDB_API_PARAMS cdb
            where cdb.i1 is not null;


	-- *) HACK! We need to mark the devices, for which we do not need to invalidate
        --    all the elements; say, you only update one element out of 5, these remaining
        --    four are treated above, the fifth is treated below, and at the end
        --    the tags to the four are closed... We therefore mark the entries by setting
        --    i4 to 1; Then, in the final "tag closing" step we will need to invalidate
        --    only the properties being modified, and not all the properties that
        --    belong to the device...
	update cdb_api_params set i4=1
	    where i1 in (select propid from recipe_tags where valid_to is null and tagId=recipeId);
        

	-- *) already processed, so delete these entries
	delete from cdb_api_params where i1 is not null;



	-- STEP 2: process the entries that did not have I1
	--         i.e. the data "that has changed"

	-- assign property id's, drawing them from sequence
	-- note that we cannot group this update statement with other updates,
	-- due to use of sequence
	update cdb_api_params set i1=RECIPE_DATA_PROPID_SEQ.NEXTVAL;

	-- insert recipe data
	insert into recipe_data(
	    propid,
	    rver,
	    id,
	    develem_id,
	    has_value,
	    has_alert,
	    propvalue,
	    alert_type,
	    alert_active,
	    alert_classes,
	    alert_texts,
	    alert_limits
	    ) 
	select 	
	    i1,
	    i3,
	    i8,
	    i2,
	    i4,
	    i5,
	    s8,
	    i6,
	    i7,
	    s6,
	    s7,
	    s5
	 from cdb_api_params;


	-- invalidate existing recipe data
	-- *) at first all the things with i4 being NULL
	--    (i.e. invalidate the whole device) - see comments above
	update recipe_tags set valid_to=curTime where
	    propid IN (SELECT PROPID FROM V_RECIPESALL r, CDB_API_PARAMS c 
			WHERE r.TAG=recipeName 
			AND r.ITEM_ID=c.i8 
			AND c.i4 IS NULL
			and r.valid_to is null)
	    and tagId=recipeId;
	-- *) then all the ones that have i5 set to 1
	update recipe_tags set valid_to=curTime where
	    propid IN (SELECT PROPID FROM V_RECIPESALL r, CDB_API_PARAMS c 
			WHERE r.TAG=recipeName 
			AND r.ITEM_ID=c.i8 
			AND r.develem_id=c.i2
			AND c.i4 IS NOT NULL
			and r.valid_to is null)
	    and tagId=recipeId;
	

	-- insert the new tags into tags table
        insert into recipe_tags(tagid,propid,valid_from,valid_to)
            select REC_ID,cdb.i1,CUR_TIM,NULL
            from (select recipeId REC_ID, curtime CUR_TIM  from dual), CDB_API_PARAMS cdb;

END;

-------------------------------------
PROCEDURE getReferences(
	configurationName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
IS


	num number;
	
	outTblReady NUMBER := NULL;

	TYPE cfgCurType IS REF CURSOR;
	configCur cfgCurType;

	devId references.id%TYPE;
	refId references.ref_id%TYPE;
	device items.dpname%TYPE;
	refdevice items.dpname%TYPE;
	
	hierarchy hierarchies.htype%TYPE;
	refhierarchy hierarchies.htype%TYPE;
	validFrom references.valid_from%TYPE;
	validTo references.valid_to%TYPE;
BEGIN

	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20005, 'fwConfigurationDB.getReferences: no such configuration:'||configurationName);
	end if;


	-- verify that the input in the CDB_API_PARAMS is right
	-- checkInputTable() will throw ORA -20001 if the table is not OK
	-- otherwise it will return the number of entries
	SELECT checkInputTable() INTO num from DUAL;

	-- prepare the cursor. If validTo is null the actual SELECT is much simpler...
	IF validAt IS NULL THEN

	    if num = 0 then 
		open configCur FOR 
		    SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE  cd.conf_id=r.refver 
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_TO IS NULL;
	    else
		open configCur FOR 
		    SELECT   r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE  cd.conf_id=r.refver 
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_TO IS NULL
			AND i.dpname in (select S1 from cdb_api_params);
	    end if;
	ELSE
	    if num = 0 then 

		open configCur FOR 
		    SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE 
			cd.conf_id=r.refver
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_FROM <= validAt
			AND ( (r.VALID_TO IS NULL) OR (r.VALID_TO >= validAt ) );
	    else
		open configCur FOR 
		    SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
		    FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
		    WHERE 
			cd.conf_id=r.refver
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
	    		AND cd.conf_tag=configurationName
			AND r.VALID_FROM <= validAt
			AND ( (r.VALID_TO IS NULL) OR (r.VALID_TO >= validAt ) )
			AND i.dpname in (select S1 from cdb_api_params);
	    end if;
	END IF;

	loop
	    fetch configCur into devId,refId,device,refDevice,hierarchy,refHierarchy,validFrom,validTo;
	    -- only here we should clean the input table! i.e. after the first fetch!
	    if outTblReady IS NULL then
		EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
		outTblReady:=1;
	    end if;

	    exit when configCur%notfound;

	    insert into CDB_API_PARAMS(i1,i2,s1,s2,s3,s4,d1,d2)
		 values( 
		    devId, --i1
		    refId, --i2
		    device, --s1
		    refdevice, --s2
		    hierarchy, --s3
		    refhierarchy, --s4
		    validFrom, --d1
		    validTo --d2
		 );

	end loop;

	close configCur;

END;

-------------------------------------
PROCEDURE setReferences(
	configurationName IN VARCHAR2)
IS

	num number;
	numDevs number;
	numRefs number;
	
	curTime cdb_api_params.d1%TYPE := SYSDATE;

	refName cdb_api_params.s1%TYPE;
	devName cdb_api_params.s2%TYPE;

	TYPE refCurType IS REF CURSOR;
	cur refCurType;

BEGIN
	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20005, 'fwConfigurationDB.setReferences: no such configuration:'||configurationName);
	end if;

	-- device names are in S1, and corresponding references in S2
	-- make sure they are all correct...

	SELECT checkInputTable(NULL) INTO num from DUAL;
	SELECT count(unique(s1))  INTO numRefs FROM cdb_api_params where s1 is not null;
	SELECT count(unique(s2))  INTO numDevs FROM cdb_api_params where s2 is not null;
	
	if (num > numDevs) then
	    RAISE_APPLICATION_ERROR(-20021, 'fwConfigurationDB.setReferences: list of devices in S2 is not unique or contains NULLs');	
	end if;
	if (num > numRefs) then
	    RAISE_APPLICATION_ERROR(-20022, 'fwConfigurationDB.setReferences: list of references in S1 is not unique or contains NULLs');	
	end if;

	-- check if there are entries that match the mapping already in DB
	-- and remove them, if needed
	DELETE FROM (
	    select * from cdb_api_params 
	    where s1 in (
		select s1 from cdb_api_params c , v_references r where 
		    c.s1=r.dpname and c.s2=r.refdpname and r.config_tag=configurationName
	    )
	);
	
	-- resolve ID's of devices and references, set also the conf_id
	update cdb_api_params c set i1=(
	    select i.item_id from v_config_items i
		where i.dpname=c.s1 and tag=configurationName 
		and hver=(select hver from hierarchies where htype='LOGICAL' and valid_to is null)
	    );
		
	update cdb_api_params c set i2=(
	    select i.item_id from v_config_items i
		where i.dpname=c.s2 and tag=configurationName
		and hver=(select hver from hierarchies where htype='HARDWARE' and valid_to is null)		
		);

	update cdb_api_params set i3=(select CONF_ID from CONFIG_DESC where conf_tag=configurationName);
		
	
	-- make sure that all the devices were resolved - otherwise report an error
	
	-- firstly check the references
	open cur for 
	    select s1 from cdb_api_params where i1 is null;
	fetch cur into refName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20023, 'fwConfigurationDB.setReferences: Logical device not found in this configuration:'||refName);
	end if;
	close cur;

	-- then check the devices
	open cur for 
	    select s2 from cdb_api_params where i2 is null;
	fetch cur into devName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20024, 'fwConfigurationDB.setReferences: Device not found in this configuration:'||devName);
	end if;
	close cur;

	-- close the IOV for the previous mapping
	UPDATE REFERENCES SET VALID_TO=curTime
	     where (ref_id in (select i2 from cdb_api_params) 
	    	    or id in (select i1 from cdb_api_params) 
	    	    )
	    and valid_to is null
	    and refver=(select conf_id from config_desc where conf_tag=configurationName);

	insert into references(refver,id,ref_id,valid_from,valid_to) 
	    select i3,i1,i2,curTime,NULL from CDB_API_PARAMS ;
	

	EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';

END;

-------------------------------------
PROCEDURE getReferenceHistory(
	configurationName IN VARCHAR2,
	startDate IN DATE DEFAULT NULL,
	endDate IN DATE DEFAULT NULL)

IS

	outTblReady NUMBER := NULL;

	num number;
	queryStmt  varchar2(2000);
	whereClause varchar2(2000) := NULL;

BEGIN
	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getReferenceHistory: no such configuration:'||configurationName);
	end if;


	-- verify that input table is correct, check if there are devices specified
	SELECT checkInputTable() INTO num from DUAL;    

	queryStmt := 'insert into cdb_api_params(i1,i2,s1,s2,s3,s4,d1,d2)
			SELECT  r.id,r.ref_id,i.dpname, j.dpname, g.htype, h.htype, r.valid_from, r.valid_to
			FROM config_desc cd,references r,items i, items j, hierarchies g,hierarchies h
			WHERE  cd.conf_id=r.refver 
			AND r.id=i.id
			AND r.ref_id=j.id
			AND i.hver=g.hver
    			AND j.hver=h.hver
			AND cd.conf_tag='''||configurationName||''' ';

	if (num > 0) then  whereClause:=whereClause||' AND i.dpname in (select s1 from cdb_api_params) '; end if;
	if (startDate is not null) then 
	    whereClause:=whereClause||' AND ( r.valid_to >= TO_DATE('''||startDate||''') OR r.valid_to is null) '; 
	end if;
	if (endDate is not null) then 
	    whereClause:=whereClause||' AND r.valid_from <= TO_DATE('''||endDate||''')  '; 
	end if;

	if whereClause IS NOT NULL then queryStmt:=queryStmt||whereClause;end if;
	
	queryStmt:=queryStmt||' ORDER BY i.dpname, r.valid_from';
	execute immediate queryStmt;

	-- the input data (if present) is still in the table - clear it
	delete from cdb_api_params where s2 is null;
	

END;

-------------------------------------
PROCEDURE getDevicesInConfiguration(
	configurationName IN VARCHAR2,
	deviceFilter IN VARCHAR2 DEFAULT NULL)
IS

	num number;
	devFilter varchar2(128) := deviceFilter;
	TYPE cfgCurType IS REF CURSOR;
	configCur cfgCurType;


BEGIN
	-- cleanup i/o table
	EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';

	-- check the configuration name 
	SELECT count(*)  INTO num FROM CONFIG_DESC WHERE conf_tag=configurationName;

	if (num<1) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.getDevicesInConfiguration: no such configuration:'||configurationName);
	end if;

	-- verify that input table is correct (no entries apart from - maybe - S1)
	SELECT checkInputTable() INTO num from DUAL;    

	-- make sure the filter is right
	if devFilter = '' then devFilter:='%'; end if;
	if devFilter IS NULL then devFilter:='%'; end if;
	

	insert into cdb_api_params(s1) 
	    select unique i.dpname from items i, config_items ci, config_desc cd, config_tags ct
		where cd.conf_tag=configurationName
	            AND cd.conf_id=ct.conf_id
	            and ct.valid_to is null
	            and ct.citem_id=ci.citem_id
	            AND ci.item_id=i.id
	            and i.dpname like replace(devFilter,'*','%')
	            order by dpname;	


END;



PROCEDURE getRecipesList(recipeNameFilter IN varchar2 default null,
			 deviceFilter IN varchar2 default null,
			 recipeCommentFilter IN varchar2 default '*',
			 recipeTypeFilter IN varchar2 default '*')
IS

    nameFilter varchar2(128) := recipeNameFilter;
    devFilter varchar2(128) := deviceFilter;
    cmtFilter varchar2(512) := recipeCommentFilter;
    rtFilter  varchar2(128) := recipeTypeFilter;

    queryStmt  varchar2(2000);
    whereClause varchar2(2000) := NULL;

BEGIN
    -- cleanup i/o table
    EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
    
    -- make sure the filter is right
    if nameFilter = '' then nameFilter:='%'; end if;
    if nameFilter IS NULL then nameFilter:='%'; end if;
    nameFilter:=replace(nameFilter,'*','%');


    queryStmt := 'insert into cdb_api_params(s1,s2,s3) 
	    select r.name ,r.description,r.recipe_type
		from recipes r where r.name like '''||nameFilter||''' ';

    if devFilter = '' then devFilter:=NULL; end if;
    if devFilter = '*' then devFilter:=NULL; end if;
    if devFilter is not null then
	devFilter:=replace(devFilter,'*','%');
	whereClause:=whereClause||' and r.name in (
		    select unique vra.tag from v_recipesall vra
			where dpname like '''||devFilter||'''
		    )';
    end if;

    if cmtFilter is null then
	whereClause:=whereClause||' and r.description is null ';
    else
	if cmtFilter!='*' then
	    cmtFilter:=replace(cmtFilter,'*','%');
	    whereClause:=whereClause||' and r.description like '''||cmtFilter||''' ';
	end if;
    end if;


    if rtFilter is null then
    	whereClause:=whereClause||' and r.recipe_type is null ';
    else 
	if rtFilter!='*' then
	    rtFilter:=replace(rtFilter,'*','%');
	    whereClause:=whereClause||' and r.recipe_type like '''||'Test'||''' ';
	end if;
    end if;

    

    if whereClause IS NOT NULL then queryStmt:=queryStmt||whereClause;end if;

    execute immediate queryStmt;


END;

PROCEDURE getConfigurationsList(configurationNameFilter IN varchar2 default null)
IS

    nameFilter varchar2(128) := configurationNameFilter;

BEGIN
    -- cleanup i/o table
    EXECUTE IMMEDIATE 'truncate table CDB_API_PARAMS';
    
    -- make sure the filter is right
    if nameFilter = '' then nameFilter:='%'; end if;
    if nameFilter IS NULL then nameFilter:='%'; end if;

    insert into cdb_api_params(s1,s2) 
	select c.conf_tag, c.description 
	    from config_desc c
	    where c.conf_tag like replace(nameFilter,'*','%');


END;


END fwConfigurationDB;
/

----------------------------------------------------------------------------
-- as the last element we create our "internal" view, which
-- is used to determine if the schema exists.
----------------------------------------------------------------------------

CREATE OR REPLACE VIEW v_confdb (
    SCHEMA_VERSION,
    TABLES,
    VIEWS,
    SEQUENCES,
    INTERNAL)
AS SELECT
    '2.05',
    'HIERARCHIES,DEVICE_TYPES,ITEMS,RECIPES,RECIPE_VERSIONS,RECIPE_DATA,RECIPE_TAGS,DEVICE_ELEMENTS,CONFIG_ITEMS,CONFIG_ITEM_PROPERTIES,CONFIG_DESC,CONFIG_TAGS,REFERENCES,CONFIG_ADDRESSES,CONFIG_ALERTS,CONFIG_DPEALERTS,CONFIG_SUMALERTS,CONFIG_ALERTS_MISC,CONFIG_ARCHIVING,CONFIG_DPFUNCTIONS,CONFIG_CONVERSIONS,CONFIG_PVRANGES,CONFIG_SMOOTHING,CONFIG_UF',
    'V_ITEM_NAMES,V_ITEMS,V_RECIPESALL,V_REFERENCES,V_CONFIG_ITEMS,V_DEVICE_CONFIGS,V_ITEM_PROPERTIES,V_CONFIG_ALERTS',
    'CITEM_ID_SEQ,CONF_ID_SEQ,DEVELEM_ID_SEQ,DPT_ID_SEQ,IPROP_ID_SEQ,ITEMS_ID_SEQ,RECIPES_RVER_SEQ,RECIPES_TAGID_SEQ,RECIPE_DATA_PROPID_SEQ',
    'CDB_API_PARAMS,TMP_ITEM_PROPS' FROM DUAL;
