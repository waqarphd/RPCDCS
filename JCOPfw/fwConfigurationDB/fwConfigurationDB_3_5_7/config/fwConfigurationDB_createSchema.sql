
----------------------------------------------------------------------------
--
-- This file is a part of the JCOP Framework Configuration Database Tool
--  schema version 3.02
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
-- CERN EN/ICE-SCD
----------------------------------------------------------------------------

-- check if the schema alrady exists
declare
 num number;
 schemaVersion char(5);
begin
    SELECT count(*) into num from USER_VIEWS where VIEW_NAME='V_CONFDB';
    if num>0 then
	-- query what is the version; not to break the function, we use dynamic SQL
	execute immediate 'select SCHEMA_VERSION from V_CONFDB' into schemaVersion;
	RAISE_APPLICATION_ERROR(-20000,'fwConfigurationDB schema already exists, version: '||schemaVersion);
    end if;       
end;
/

  CREATE TABLE "HIERARCHIES"
   (	"HVER" NUMBER,
	"HTYPE" VARCHAR2(8) 
	    CONSTRAINT "HIERARCHIES_NN_HTYPE" NOT NULL ENABLE,
	"DESCR" VARCHAR2(128),
	"VALID_FROM" DATE,
	"VALID_TO" DATE,
	 CONSTRAINT "HIERARCHIES_PK" PRIMARY KEY ("HVER") ENABLE
   )
 ;

  CREATE TABLE "DEVICE_TYPES"
   (	"DPT_ID" NUMBER,
	"DPTYPE" VARCHAR2(64) 
	    CONSTRAINT "DEVICE_TYPES_NN_DPTYPE" NOT NULL ENABLE,
	"VALID_TO" DATE,
	 CONSTRAINT "DEVICE_TYPES_PK" PRIMARY KEY ("DPT_ID") ENABLE
   )
 ;

  CREATE TABLE "ITEMS"
   (	"HVER" NUMBER,
	"ID" NUMBER,
	"PARENT" NUMBER,
	"NAME" VARCHAR2(512) 
	    CONSTRAINT "ITEMS_NN_NAME" NOT NULL ENABLE,
	"TYPE" VARCHAR2(64) 
	    CONSTRAINT "ITEMS_NN_TYPE" NOT NULL ENABLE,
	"DETAIL" VARCHAR2(64),
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

  CREATE UNIQUE INDEX "ITEMS_DPNAME_IDX" ON "ITEMS" ("DPNAME");
  CREATE INDEX "ITEMS_PARENT_AND_ID" ON "ITEMS" ("PARENT", "ID");
  CREATE INDEX "ITEMS_PARENT_IDX" ON "ITEMS" ("PARENT");

  CREATE TABLE "RECIPES"
   (	"TAGID" NUMBER,
	"NAME" VARCHAR2(128) 
	    CONSTRAINT "RECIPES_NN_NAME" NOT NULL ENABLE,
	"HVER" NUMBER,
	"DESCRIPTION" VARCHAR2(128),
	"RECIPE_TYPE" VARCHAR2(128),
	 CONSTRAINT "RECIPES_PK" PRIMARY KEY ("TAGID") ENABLE,
	 CONSTRAINT "RECIPES_FK_HVER" FOREIGN KEY ("HVER")
	  REFERENCES "HIERARCHIES" ("HVER") ON DELETE CASCADE ENABLE
   )
 ;


  CREATE TABLE "RECIPE_VERSIONS"
   (	"RVER" NUMBER
	 CONSTRAINT "RECIPE_VERSIONS_NN_RVER" NOT NULL ENABLE,
	"DESCRIPTION" VARCHAR2(255),
	"USER_CREATED" VARCHAR2(16),
	"DATE_CREATED" DATE,
	 CONSTRAINT "RECIPE_VERSIONS_PK" PRIMARY KEY ("RVER") ENABLE
   )
 ;


  CREATE TABLE "RECIPE_DATA"
   (	"PROPID" NUMBER,
	"RVER" NUMBER 
	    CONSTRAINT "RECIPE_DATA_NN_RVER" NOT NULL ENABLE,
	"ID" NUMBER 
	    CONSTRAINT "RECIPE_DATA_NN_ID" NOT NULL ENABLE,
	"HAS_VALUE" NUMBER,
	"HAS_ALERT" NUMBER,
	"PROPVALUE" CLOB,
	"ALERT_TYPE" NUMBER,
	"ALERT_ACTIVE" NUMBER,
	"ALERT_CLASSES" VARCHAR2(256),
	"ALERT_TEXTS" VARCHAR2(1024),
	"ALERT_LIMITS" VARCHAR2(128),
	"DEVELEM_ID" NUMBER,
	 CONSTRAINT "RECIPE_DATA_PK" PRIMARY KEY ("PROPID") ENABLE,
	 CONSTRAINT "RECIPE_DATA_FK_ID" FOREIGN KEY ("ID")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "RECIPE_DATA_FK_VERSION" FOREIGN KEY ("RVER")
	  REFERENCES "RECIPE_VERSIONS" ("RVER") ON DELETE CASCADE ENABLE
   )
 ;

  CREATE INDEX "RECIPE_DATA_DEV_IDX" ON "RECIPE_DATA" ("ID","DEVELEM_ID");

  CREATE TABLE "RECIPE_TAGS"
   (	"TAGID" NUMBER 
	    CONSTRAINT "RECIPE_TAGS_NN_TAGID" NOT NULL ENABLE,
	"PROPID" NUMBER 
	    CONSTRAINT "RECIPE_TAGS_NN_PROPID" NOT NULL ENABLE,
	"VALID_FROM" DATE 
	    CONSTRAINT "RECIPE_TAGS_NN_VALID_FROM" NOT NULL ENABLE,
	"VALID_TO" DATE,
	"RVER" NUMBER,
	 CONSTRAINT "RECIPE_TAGS_FK_PROPID" FOREIGN KEY ("PROPID")
	  REFERENCES "RECIPE_DATA" ("PROPID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "RECIPE_TAGS_UK" UNIQUE ("PROPID","TAGID","VALID_FROM") ENABLE,
	 CONSTRAINT "RECIPE_TAGS_RK_RVER" FOREIGN KEY ("RVER") REFERENCES "RECIPE_VERSIONS"("RVER") ON DELETE CASCADE ENABLE
   )
 ;

  CREATE INDEX "RECIPE_TAGS_PROPID_IDX" ON "RECIPE_TAGS"  ("PROPID");
  CREATE INDEX "RECIPE_TAGS_VALIDTO_IDX" ON "RECIPE_TAGS"  ("VALID_TO");



  CREATE TABLE "DEVICE_ELEMENTS"
   (	"DEVELEM_ID" NUMBER,
	"DPT_ID" NUMBER CONSTRAINT 
	    "DEVICE_ELEMENTS_NN_DPT_ID" NOT NULL ENABLE,
	"ELEMENTNAME" VARCHAR2(128) 
	    CONSTRAINT "DEVICE_ELEMENTS_NN_ELEMENTNAME" NOT NULL ENABLE,
	"ELEMENTTYPE" NUMBER 
	    CONSTRAINT "DEVICE_ELEMENTS_NN_ELEMENTTYPE" NOT NULL ENABLE,
	 CONSTRAINT "DEVICE_ELEMENTS_PK" PRIMARY KEY ("DEVELEM_ID") ENABLE,
	 CONSTRAINT "DEVICE_ELEMENTS_FK_DPT_ID" FOREIGN KEY ("DPT_ID")
	  REFERENCES "DEVICE_TYPES" ("DPT_ID") ON DELETE CASCADE ENABLE
   )
 ;


CREATE TABLE config_items_new
( "TAG_ID" NUMBER,
  "CITEM_ID" NUMBER,
  "ITEM_ID" NUMBER
    CONSTRAINT CONFIG_ITEMS_NEW_NN_ITEM_ID NOT NULL ENABLE,
  "DPT_ID" NUMBER
    CONSTRAINT CONFIG_ITEMS_NEW_NN_DPT_ID NOT NULL ENABLE,
  "VALID_FROM" DATE
    CONSTRAINT CONFIG_ITEMS_NEW_NN_VALID_FROM NOT NULL ENABLE,
  "VALID_TO" DATE,
  CONSTRAINT "CONFIG_ITEMS_NEW_PK" PRIMARY KEY ("CITEM_ID") ENABLE
) ;

CREATE UNIQUE INDEX "CONFIG_ITEMS_NEW_IDX1" ON "CONFIG_ITEMS_NEW"
(
  "TAG_ID",
  "VALID_TO",
  "ITEM_ID"
);




  CREATE TABLE "CONFIG_ITEMPROPS"
   (	"IPROP_ID" NUMBER,
	"CITEM_ID" NUMBER
	    CONSTRAINT "CONFIG_ITEMPROPS_NN_CITEM_ID" NOT NULL,
	"DEVELEM_ID" NUMBER
	    CONSTRAINT "CONFIG_ITEMPROPS_NN_DEVELEM_ID" NOT NULL,
	"DPEALIAS" VARCHAR2(256),
	 CONSTRAINT "CONFIG_ITEMPROPS_PK" PRIMARY KEY ("IPROP_ID") ENABLE,
	 CONSTRAINT "CONFIG_ITEMPROPS_FK_CITEM_ID" FOREIGN KEY ("CITEM_ID")
	  REFERENCES "CONFIG_ITEMS_NEW" ("CITEM_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_ITEMPROPS_FK_DEVELEM_ID" FOREIGN KEY ("DEVELEM_ID")
	  REFERENCES "DEVICE_ELEMENTS" ("DEVELEM_ID") ON DELETE CASCADE ENABLE
   );

  CREATE INDEX "CONFIG_ITEMPROPS_CITEM_ID" ON "CONFIG_ITEMPROPS"(citem_id);


   CREATE TABLE "CONFIG_VALUES"
     (	"IPROP_ID" NUMBER,
	"PVALUE" VARCHAR2(32),
	CONSTRAINT "CONFIG_VALUES_FK_IPROPID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE
     );

   create unique index "CONFIG_VALUES_IPROP" on CONFIG_VALUES (iprop_id);

   CREATE TABLE "CONFIG_VALUES_BIG"
     (	"IPROP_ID" NUMBER,
	"CVALUE" CLOB,
	CONSTRAINT "CONFIG_VALUESBIG_FK_IPROPID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE
     );

   create unique index "CONFIG_VALUESBIG_IPROP" on config_values_big(iprop_id);


  CREATE TABLE "CONFIG_DESC"
   (	"CONF_ID" NUMBER,
	"CONF_TAG" VARCHAR2(32)
	    CONSTRAINT "CONFIG_DESC_NN_CONF_TAG" NOT NULL ENABLE,
	"DESCRIPTION" VARCHAR2(255),
	"HVER" NUMBER,
	 CONSTRAINT "CONFIG_DESC_PK" PRIMARY KEY ("CONF_ID") ENABLE,
	 CONSTRAINT "CONFIG_DESC_FK_HVER" FOREIGN KEY ("HVER")
	  REFERENCES "HIERARCHIES" ("HVER") ON DELETE CASCADE ENABLE
   )
 ;

  CREATE UNIQUE INDEX "CONFIG_DESC_CONF_TAG_IDX" ON "CONFIG_DESC" ("CONF_TAG");

  CREATE TABLE "REFERENCES"
   (	"REFVER" NUMBER
	    CONSTRAINT "REFERENCES_NN_REFVER" NOT NULL ENABLE,
	"ID" NUMBER
	    CONSTRAINT "REFERENCES_NN_ID" NOT NULL ENABLE,
	"REF_ID" NUMBER
	    CONSTRAINT "REFERENCES_NN_REF_ID" NOT NULL ENABLE,
	"VALID_FROM" DATE,
	"VALID_TO" DATE,
	 CONSTRAINT "REFERENCES_FK_REFVER" FOREIGN KEY ("REFVER")
	  REFERENCES "CONFIG_DESC" ("CONF_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "REFERENCES_FK_ID" FOREIGN KEY ("ID")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "REFERENCES_FK_REF_ID" FOREIGN KEY ("REF_ID")
	  REFERENCES "ITEMS" ("ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "REFERENCES_UK" UNIQUE ("REFVER","ID","VALID_FROM") ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ADDRESSES"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_ADDRESSES_NN_IPROP_ID" NOT NULL ENABLE,
	"TYPE" VARCHAR2(16),
	"DRIVER" NUMBER,
	"DIRECTION" NUMBER,
	"DATATYPE" NUMBER,
	"ACTIVE" NUMBER,
	"OPTIONS" VARCHAR2(255),
	 CONSTRAINT "CONFIG_ADDRESSES_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_ADDRESSES_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;


  CREATE TABLE "CONFIG_ALERTS"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_ALERTS_NN_IPROP_ID" NOT NULL ENABLE,
	"TYPE" NUMBER,
	"ACTIVE" NUMBER,
	"DISCRETE" NUMBER, 
	"IMPULSE" NUMBER,
	 CONSTRAINT "CONFIG_ALERTS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_ALERTS_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;




  CREATE TABLE "CONFIG_DPEALERTS"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_DPEALERTS_NN_IPROP_ID" NOT NULL ENABLE,
	"TEXTS" VARCHAR2(1024),
	"CLASSES" VARCHAR2(256),
	"LIMITS" VARCHAR2(128),
	"INCLUSIVE" VARCHAR2(40), 
	"NEGATED" VARCHAR2(40),
	 CONSTRAINT "CONFIG_DPEALERTS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_DPEALERTS_UK" UNIQUE ("IPROP_ID") ENABLE	  
   )
 ;


  CREATE TABLE "CONFIG_SUMALERTS"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_SUMALERTS_NN_IPROP_ID" NOT NULL ENABLE,
	"TEXTS" VARCHAR2(128),
	"CLASS" VARCHAR2(64),
	"SUMDPELIST" VARCHAR2(4000),
	"THRESHOLD" NUMBER,
	 CONSTRAINT "CONFIG_SUMALERTS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_SUMALERTS_UK" UNIQUE ("IPROP_ID") ENABLE	  
   )
 ;


  CREATE TABLE "CONFIG_ALERTS_MISC"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_ALERTS_MISC_NN_IPROP_ID" NOT NULL ENABLE,
	"PANEL" VARCHAR2(128),
	"PANELPARAMS" VARCHAR2(128),
	"HELP" VARCHAR2(128),
	"STATEBITS" VARCHAR2(64),
	"LIMITSSTATEBITS" VARCHAR2(1024),
	"TEXTSWENT" VARCHAR2(1024),
	 CONSTRAINT "CONFIG_ALERTS_MISC_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_ALERTS_MISC_UK" UNIQUE ("IPROP_ID") ENABLE	  
   )
 ;


  CREATE TABLE "CONFIG_ARCHIVING"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_ARCHIVING_NN_IPROP_ID" NOT NULL ENABLE,
	"CLASSNAME" VARCHAR2(32),
	"TYPE" NUMBER,
	"SMOOTHPROC" NUMBER,
	"DEADBAND" NUMBER,
	"TIMEINTVAL" NUMBER,
	"ACTIVE" NUMBER,
	 CONSTRAINT "CONFIG_ARCHIVING_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_ARCHIVING_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;


  CREATE TABLE "CONFIG_DPFUNCTIONS"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_DPFUNCTIONS_NN_IPROP_ID" NOT NULL ENABLE,
	"PARAMS" VARCHAR2(4000),
	"GLOBALS" VARCHAR2(1024),
	"DEFINITION" VARCHAR2(1024),
	"FUNCTYPE" NUMBER, 
	"STATFUNCTYPES" VARCHAR2(128), 
	"STATOPTS" VARCHAR2(64),
	 CONSTRAINT "CONFIG_DPFUNCTIONS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_DPFUNCTIONS_UK" UNIQUE ("IPROP_ID") ENABLE	  
   )
 ;


  CREATE TABLE "CONFIG_CONVERSIONS"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_CONVERSIONS_NN_IPROP_ID" NOT NULL ENABLE,
	"TYPE" NUMBER,
	"CONVTYPE" NUMBER,
	"CONVORDER" NUMBER,
	"ARGUMENTS" VARCHAR2(64),
	 CONSTRAINT "CONFIG_CONVERSIONS_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_CONVERSIONS_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;


  CREATE TABLE "CONFIG_PVRANGES"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_PVRANGES_NN_IPROP_ID" NOT NULL ENABLE,
	"MINVALUE" NUMBER,
	"MAXVALUE" NUMBER,
	"NEGRANGE" NUMBER,
	"IGNOUTSIDE" NUMBER,
	"INCLMIN" NUMBER,
	"INCLMAX" NUMBER,
	"PVRVALS" VARCHAR2(512),
	"PVRTYPE" NUMBER,
	 CONSTRAINT "CONFIG_PVRANGES_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_PVRANGES_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;


  CREATE TABLE "CONFIG_SMOOTHING"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_SMOOTHING_NN_IPROP_ID" NOT NULL ENABLE,
	"PROC" NUMBER,
	"DEADBAND" NUMBER,
	"TIMEINTVAL" NUMBER,
	 CONSTRAINT "CONFIG_SMOOTHING_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_SMOOTHING_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;


  CREATE TABLE "CONFIG_UF"
   (	"IPROP_ID" NUMBER
	     CONSTRAINT "CONFIG_UF_NN_IPROP_ID" NOT NULL ENABLE,
	"UNIT" VARCHAR2(16),
	"FMT" VARCHAR2(16),
	 CONSTRAINT "CONFIG_UF_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_UF_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;

  CREATE TABLE "CONFIG_GENERAL"
   (	"IPROP_ID" NUMBER
	    CONSTRAINT "CONFIG_GENERAL_NN_IPROP_ID" NOT NULL ENABLE,
        "NUM" NUMBER(1)
    	    CONSTRAINT "CONFIG_GENERAL_NN_NUM" NOT NULL ENABLE,
	"WHAT" VARCHAR2(20)
	    CONSTRAINT "CONFIG_GENERAL_NN_WHAT" NOT NULL ENABLE,
	"DATA" VARCHAR2(4000),
	 CONSTRAINT "CONFIG_GENERAL_FK_IPROP_ID" FOREIGN KEY ("IPROP_ID")
	  REFERENCES "CONFIG_ITEMPROPS" ("IPROP_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "CONFIG_GENERAL_UK" UNIQUE ("IPROP_ID") ENABLE
   )
 ;





CREATE OR REPLACE VIEW v_recipesall
(
    propid
  , proptype
  , item_id
  , develem_id
  , recipe_ver
  , valid_from
  , valid_to
  , tag
  , recipe_type
  , recipe_comment
  , "HIERARCHY"
  , dpname
  , property
  , dptype
  , detail
  , elementtype
  , has_value
  , has_alert
  , propvalue
  , alert_type
  , alert_active
  , alert_classes
  , alert_texts
  , alert_limits
)
AS
SELECT
	rt.propid,
	de.elementtype,
	i.id,
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
	i.type,
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
    FROM recipe_tags rt, recipes r, recipe_data rd ,items i,hierarchies h, device_elements de
    WHERE 	rt.propid=rd.propid
	AND 	r.tagid=rt.tagid
	AND 	h.hver=i.hver
	AND 	i.id=rd.id
	AND 	de.develem_id=rd.develem_id(+)
 ;

CREATE OR REPLACE VIEW v_references
(
    item_id
  , ref_id
  , config_id
  , dpname
  , refdpname
  , config_tag
)
AS
select 
	r.id, 
	r.ref_id, 
	r.refver,
	i.dpname, 
	j.dpname, 
	c.conf_tag
    from items i, items j, references r, config_desc c
    where 	r.id=i.id 
	and 	r.ref_id=j.id 
	and	r.refver=c.conf_id 
	and 	r.valid_to is null
 ;


CREATE OR REPLACE VIEW v_config_items
(
    item_id
  , citem_id
  , dpt_id
  , name
  , dpname
  , dptype
  , tag
  , hver
  , description
  , "TYPE"
  , model
  , parent_id
  , dpid
)
AS
select 
	i.id, 
	c.citem_id, 
	t.dpt_id,
	i.name,
	i.dpname,
	t.dptype,
	d.conf_tag,
	i.hver,
	i.description,
	i.type,
	i.detail,
	i.parent,
	i.dpid
    from   items i, config_items_new c, device_types t, config_desc d
    where  	i.id=c.item_id 
	and 	t.dpt_id=c.dpt_id 
	and 	d.conf_id=c.tag_id
	and 	c.valid_to is null
 ;


CREATE OR REPLACE FORCE VIEW "V_DEVICE_CONFIGS" 
    (	"DPT_ID", 
	"DEVELEM_ID", 
	"DPTYPE", 
	"ELEMENTNAME", 
	"ELEMENTTYPE"
    ) AS select 
	d.dpt_id, 
	e.develem_id, 
	d.dpType, 
	e.elementName, 
	e.elementType
    from device_types d, device_elements e
    where 	d.dpt_id=e.dpt_id(+) 
	and 	d.valid_to is null
 ;

CREATE OR REPLACE FORCE VIEW "V_DEVICE_CONFIGS_ALL" 
    (	"DPT_ID", 
	"DEVELEM_ID", 
	"DPTYPE", 
	"ELEMENTNAME", 
	"ELEMENTTYPE"
    ) AS select 
	d.dpt_id, 
	e.develem_id, 
	d.dpType, 
	e.elementName, 
	e.elementType
    from device_types d, device_elements e
    where 	d.dpt_id=e.dpt_id(+) 
 ;

CREATE OR REPLACE FORCE VIEW v_item_properties
(
    citem_id
  , iprop_id
  , develem_id
  , item_dpname
  , dpttype
  , prop_name
  , dpe_name
  , dpe_type
  , value
  , tag
)
AS
select 
	c.citem_id, 
	c.iprop_id, 
	c.develem_id,
	i.dpname, 
	i.dptype, 
	p.elementname,
	i.dpname||p.elementname,
	p.elementtype,
	V.VALUE VAL,
	i.tag
    from config_itemprops c, v_config_items i, v_device_configs_all p,
    (
	SELECT IPROP_ID IPROP_ID, PVALUE VALUE FROM CONFIG_VALUES
	UNION ALL
	SELECT IPROP_ID IPROP_ID, CAST( cvalue AS VARCHAR2(4000)) VALUE FROM CONFIG_VALUES_BIG
 ) V
    where 	p.develem_id=c.develem_id 
	and 	i.citem_id=c.citem_id
	and c.iprop_id=v.iprop_id(+);

CREATE OR REPLACE VIEW v_config_alerts
(
    iprop_id
  , "TYPE"
  , active
  , discrete
  , impulse
  , texts
  , textswent
  , classes
  , limits
  , inclusive
  , negated
  , sumdpelist
  , threshold
  , statebits
  , limitsstatebits
  , panel
  , panelparams
  , help
)
AS
select
	al.iprop_id,
	al.type,
	al.active,
	al.discrete,
	al.impulse,
	CASE al.type WHEN 59 THEN s.texts ELSE a.texts END,
	m.textswent,
	CASE al.type WHEN 59 THEN s.class ELSE a.classes END,
	a.limits,
	a.inclusive,
	a.negated,
	s.sumdpelist,
	s.threshold,
	m.statebits,
	m.limitsstatebits,
	m.panel,
	m.panelParams,
	m.help
    from config_alerts al, config_dpealerts a, config_sumalerts s, config_alerts_misc m
    where 	a.iprop_id(+)=al.iprop_id
	and	s.iprop_id(+)=al.iprop_id
	and  m.iprop_id(+)=al.iprop_id;

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
	"C1" CLOB
   ) ON COMMIT PRESERVE ROWS
 ;

CREATE GLOBAL TEMPORARY TABLE "TMP_ITEM_PROPS"
   (    "IPROP_ID" NUMBER,
        "DPENAME" VARCHAR2(512)
   ) ON COMMIT PRESERVE ROWS;

create unique index tip_dpe_idx    on TMP_ITEM_PROPS(DPEName);
CREATE UNIQUE INDEX tip_ipropd_idx ON tmp_item_props(iprop_id);

-----------------------------------------------------------------------------
--
-- The PL/SQL package containing fwConfigurationDB functions
--
-- Unofficial documentation is at
-- https://twiki.cern.ch/twiki/bin/view/Controls/ConfigurationDBTool#PlSqlApi
-----------------------------------------------------------------------------
 
----- PREPARE OBJECT TYPES ----------
-- replacing of object types is not trivial, if they depend on each other...
-- We get: ORA-02303: cannot drop or replace a type with type or table dependents
-- we do the cleanup inside the PL/SQL code block...
declare
 num number;
begin
    SELECT count(*) into num from USER_TYPES WHERE TYPE_NAME='SUMALERTTABLETYPE';
    if num>0 then
	execute immediate 'drop type sumalerttabletype';
    end if;

    SELECT count(*) into num from USER_TYPES WHERE TYPE_NAME='SUMALERTOBJECT';
    if num>0 then
	execute immediate 'drop type sumalertobject';
    end if;

    SELECT count(*) into num from USER_TYPES WHERE TYPE_NAME='LIST_AGG_TYPE';
    if num>0 then
	execute immediate 'drop type LIST_AGG_TYPE';
    end if;
end;
/

-- now re-create the types
create or replace type sumAlertObject
as object
(
    iprop_id NUMBER,
    isPattern NUMBER,
    sumdpelist varchar2(4000)
);
/

create or replace type sumAlertTableType as table of sumAlertObject;
/


-- implementation of custom aggregation function allowing to collapse a set or rows
-- into a |-separated string is based on STRAGG function implementation published at
-- http://asktom.oracle.com/pls/asktom/f?p=100:11:0::NO::P11_QUESTION_ID:2196162600402
CREATE OR REPLACE type list_agg_type as object
  (
     total varchar2(4000),
     static function
          ODCIAggregateInitialize(sctx IN OUT list_agg_type )
          return number,
  
     member function
          ODCIAggregateIterate(self IN OUT list_agg_type ,
                               value IN varchar2 )
          return number,

     member function
          ODCIAggregateIterate(self IN OUT list_agg_type ,
                               value IN number )
          return number,
  
     member function
          ODCIAggregateTerminate(self IN list_agg_type,
                                 returnValue OUT  varchar2,
                                 flags IN number)
          return number,
  
     member function
          ODCIAggregateMerge(self IN OUT list_agg_type,
                             ctx2 IN list_agg_type)
          return number
  );
/


CREATE OR REPLACE type body list_agg_type
  is
  
  static function ODCIAggregateInitialize(sctx IN OUT list_agg_type)
  return number
  is
  begin
      sctx := list_agg_type( null );
      return ODCIConst.Success;
  end;
  member function ODCIAggregateIterate(self IN OUT list_agg_type,
                                       value IN varchar2 )
  return number
  is
  begin
      self.total := self.total || '|' || value;
      return ODCIConst.Success;
  end;
  
  member function ODCIAggregateIterate(self IN OUT list_agg_type,
                                       value IN number )
  return number
  is
  begin
      self.total := self.total || '|' || value;
      return ODCIConst.Success;
  end;
  
  member function ODCIAggregateTerminate(self IN list_agg_type,
                                         returnValue OUT varchar2,
                                         flags IN number)
  return number
  is
  begin
      returnValue := ltrim(self.total,'|');
      return ODCIConst.Success;
  end;
  
  member function ODCIAggregateMerge(self IN OUT list_agg_type,
                                     ctx2 IN list_agg_type)
  return number
  is
  begin
      self.total := self.total || ctx2.total;
      return ODCIConst.Success;
  end;

end;
/

CREATE or replace FUNCTION lstagg   (input varchar2 ) RETURN varchar2 PARALLEL_ENABLE AGGREGATE USING list_agg_type;
/

CREATE or replace FUNCTION lstaggnum(input number )   RETURN varchar2 PARALLEL_ENABLE AGGREGATE USING list_agg_type;
/

----------- MAIN PACKAGE --------------

CREATE OR REPLACE PACKAGE fwConfigurationDB
AUTHID CURRENT_USER
IS

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

PROCEDURE getRecipe2(
	recipeName        IN VARCHAR2,
	validAt           IN DATE DEFAULT NULL,
	dataIntoClob      IN NUMBER DEFAULT 1)
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
	userCreated IN VARCHAR2 DEFAULT NULL)
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
FUNCTION checkInputTable(checkS2 number default 1) RETURN NUMBER;

PROCEDURE saveItems( hierarchyType IN VARCHAR2)
;
PROCEDURE saveStaticConfiguration(configurationName IN VARCHAR2,
	hierarchyType IN VARCHAR2)
;

FUNCTION getSummaryAlerts  return sumAlertTableType pipelined
;

FUNCTION checkSaveDpTypes  return number
;

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
	OR c1 is not null';
		
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


-- Backward compatible function: returns the recipe data
-- in the S8 column, rather than C1
-----------------------------------------------
PROCEDURE getRecipe(
	recipeName IN VARCHAR2,
	validAt IN DATE DEFAULT NULL)
IS
BEGIN
    getRecipe2(recipeName,validAt,0);
END;

-----------------------------------------------
PROCEDURE getRecipe2(
	recipeName        IN VARCHAR2,
	validAt           IN DATE DEFAULT NULL,
	dataIntoClob      IN NUMBER DEFAULT 1)
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
		    delete from CDB_API_PARAMS;
		    outTblReady:=1;
		end if;

		exit when recipesCur%notfound;
		if dataIntoClob IS NULL OR dataIntoClob=0 THEN
		  insert into CDB_API_PARAMS(
		    i1,i2,i3,i4,i5,i6,i7,i8,
		    s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,
		    d1,d2
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
		    SUBSTR(recipeData.propValue,1,4000),	-- s8 (4000)
		    recipeData.hierarchy,       --s9 (16)
		    NULL,                       --s10 (16)
		    recipeData.validFrom, 	--d1
		    recipeData.validTo  	--d2
		  );
		 ELSE
		  insert into CDB_API_PARAMS(
		    i1,i2,i3,i4,i5,i6,i7,i8,
		    s1,s2,s3,s4,s5,s6,s7,c1,s9,s10,
		    d1,d2
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
		    recipeData.propValue,	-- c1(!)
		    recipeData.hierarchy,       --s9 (16)
		    NULL,                       --s10 (16)
		    recipeData.validFrom, 	--d1
		    recipeData.validTo  	--d2
		 );
		 
		 END IF;

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
	
	-- we check if one can do insert into recipes...
	-- note the use of SYS_CONTEXT to get the currently used schema!
	IF SYS_CONTEXT('USERENV','CURRENT_SCHEMA') != USER THEN
	    SELECT count(*) into num from ALL_TAB_PRIVS WHERE TABLE_NAME='RECIPES' 
		AND TABLE_SCHEMA=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='INSERT';
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.createRecipe: Your DB account: '||USER||' does not allow to create recipes in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;

	    -- we also check if he 'sees' the sequence that we are going to use..
	    SELECT count(*) into num from ALL_SEQUENCES WHERE SEQUENCE_NAME='RECIPES_TAGID_SEQ' 
		AND SEQUENCE_OWNER=SYS_CONTEXT('USERENV','CURRENT_SCHEMA');
	    
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.createRecipe: Cannot draw numbers from sequences in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;
	END IF;
	
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
	-- check if the current user is allowed to store recipes in this schema...
	IF SYS_CONTEXT('USERENV','CURRENT_SCHEMA') != USER THEN
	    SELECT count(*) into num from ALL_TAB_PRIVS WHERE TABLE_NAME='RECIPES' 
		AND TABLE_SCHEMA=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='INSERT';
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.storeRecipe: Your DB account: '||USER||' does not allow to modify recipes in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;
	END IF;

	-- check the recipe name 
	open cur for SELECT tagid from RECIPES WHERE name=recipeName;
	fetch cur into recipeId;

	if (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20002, 'fwConfigurationDB.storeRecipe: no such recipe:'||recipeName);
	end if;
	close cur;
	
	-- get rid of the ones that are already OK...
	delete from CDB_API_PARAMS where I1 in 
	    (SELECT PROPID from RECIPE_TAGS where VALID_TO is NULL and TAGID=recipeId);


	--complete datapoint ID's:
	update cdb_api_params c set i8=(
	    select i.id from items i where i.dpname=c.s1)
	    where c.i1 is null;


	-- make sure that all the devices were resolved - otherwise report an error
	open cur for 
	    select s1 from cdb_api_params where i8 is null and i1 is null;
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
	    )
	    where c.i1 is null;

	-- make sure that all the properties were resolved - otherwise report an error
	open cur for 
	    select s1,s2 from cdb_api_params where i2 is null and i1 is null;
	fetch cur into devName,propName;
	if NOT (cur%notfound) then
	    RAISE_APPLICATION_ERROR(-20024, 'fwConfigurationDB.storeRecipe: Device element not found in database:'||devName||propName);
	end if;
	close cur;


	-- generate next ordinal number for Recipe Version, and store new version
	EXECUTE IMMEDIATE 'SELECT RECIPES_RVER_SEQ.NEXTVAL FROM DUAL' INTO rVer;

	insert into recipe_versions(rver,description,user_created,date_created)
	    values(rver,versionDescription,userCreated,curTime);

	update cdb_api_params set i3=rVer;


	-- STEP 1: for the elements, for which we already have PropId passed in I1,
	-- we simply do the manipulation with tags, and do not store the data again!


        -- *) firstly, let's check if we have some "roll-backs" to previous versions
        -- of the data.
        -- close the IOVs
    	update recipe_tags 
    	    set valid_to=curTime 
    	    where propid in (
    		select rd2.propid 
    		from recipe_data rd1, recipe_tags rt1, recipe_data rd2, recipe_tags rt2,
    		     cdb_api_params cdb
    		where cdb.i1=rd1.propid -- this implies cdb.i1 NOT NULL
    		and rd1.propid=rt1.propid 
    		and rt1.valid_to is not null
    		and rd1.id=rd2.id
    		and rd1.develem_id=rd2.develem_id
    		and rd2.propid=rt2.propid
    		and rt2.valid_to is null
    		and rt1.tagid=recipeId
    		and rt1.tagid=rt2.tagid
    		);

    	-- reopen IOVs for the case of no-copy;
		-- mark it by I7=99 (we do not need I7 anymore anyway...)
		update cdb_api_params c set c.i7=99 where
		c.i1 in (select cdb.i1 from cdb_api_params cdb,recipe_tags rt
	    where cdb.i1 is not null
	    and rt.propid=cdb.i1 
	    and rt.valid_to is not null
	    and rt.tagid=recipeId);
		
				
	insert into recipe_tags (tagid,rver,propid,VALID_FROM,VALID_TO) 
	    select recipeId,rver,i1,curTime,NULL 
	    from cdb_api_params cdb where i7=99;
		
	delete from cdb_api_params where i7=99;
		
	-- repen IOVs for the case of recipe-copy
	insert into recipe_tags (tagid,rver,propid,VALID_FROM,VALID_TO) 
	    select recipeId,rver,i1,curTime,NULL 
	    from cdb_api_params cdb
	    where cdb.i1 is not null
	    and cdb.i1 not in (select propid from recipe_tags where valid_to is null and tagid=recipeId);

	delete from cdb_api_params where i1 is not null;

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


	-- if the user used the old convention to pass property value in the S8
	-- column, rather that in C1, move the data appropriately
	update CDB_API_PARAMS SET C1=S8 WHERE C1 IS NULL and S8 IS NOT NULL;


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
	    c1,
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
		delete from CDB_API_PARAMS;
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
	myConfId number;
	errMsg VARCHAR2(2000);
	now cdb_api_params.d1%TYPE := SYSTIMESTAMP;
BEGIN
	

	-- check if the current user is allowed to set references
	IF SYS_CONTEXT('USERENV','CURRENT_SCHEMA') != USER THEN
	    SELECT count(*) into num from ALL_TAB_PRIVS WHERE TABLE_NAME='REFERENCES' 
		AND TABLE_SCHEMA=SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AND PRIVILEGE='INSERT';
	    if (num=0) then
		RAISE_APPLICATION_ERROR(-20020, 'fwConfigurationDB.setReferences: Your DB account: '||USER||' does not allow to modify references in schema '||SYS_CONTEXT('USERENV','CURRENT_SCHEMA'));
	    end if;
	END IF;

	-- check the configuration name, retrieve its ID
	BEGIN
	SELECT CONF_ID INTO myConfId FROM CONFIG_DESC WHERE CONF_TAG=configurationName;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
	    RAISE_APPLICATION_ERROR(-20005, 'fwConfigurationDB.setReferences: no such configuration:'||configurationName);
	END;

	-- device names are in S1, and corresponding references in S2
	-- make sure they are all correct...
	-- note: if called from saveStaticConfiguration, we should have item IDs already filled in
	SELECT count(unique(s1))  INTO numRefs FROM cdb_api_params where s1 is not null;
	SELECT count(unique(s2))  INTO numDevs FROM cdb_api_params where s2 is not null;
	
	if (num > numDevs) then
	    RAISE_APPLICATION_ERROR(-20021, 'fwConfigurationDB.setReferences: list of devices in S2 is not unique or contains NULLs');	
	end if;
	if (num > numRefs) then
	    RAISE_APPLICATION_ERROR(-20022, 'fwConfigurationDB.setReferences: list of references in S1 is not unique or contains NULLs');	
	end if;

	-- resolve ID's, if there are still unresolved ones...
	UPDATE CDB_API_PARAMS CDB SET cdb.i1=(SELECT i.ID FROM ITEMS i where i.dpname=cdb.s1) where cdb.i1 is null;
	-- check if all IDs resolved...
	errMsg:=null;
	for rec in ( select s1 DPNAME, s2 REFDPNAME FROM CDB_API_PARAMS where I1 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';REFDP='||rec.refdpname;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
		raise_application_error(-20014,'fwConfigurationDB.setReferences:Could not resolve devices:'||errMsg);
	end if;
	
	-- resolve RefIDs for all things of type FwNode: they should point to themselves
	UPDATE CDB_API_PARAMS CDB SET cdb.i5=cdb.i1, cdb.i3=myConfId, cdb.d1=now where cdb.s3='FwNode';
	-- resolve IDs of other referred DPs
	UPDATE CDB_API_PARAMS CDB SET cdb.i5=(SELECT i.ID FROM ITEMS i where i.dpname=cdb.s2),cdb.i3=MyConfId,cdb.d1=now where cdb.i5 is null;
		
	-- check if all references resolved...
	errMsg:=null;
	for rec in ( select s1 DPNAME, s2 REFDPNAME FROM CDB_API_PARAMS where I5 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';REFDP='||rec.refdpname;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
		raise_application_error(-20014,'fwConfigurationDB.setReferences:Could not resolve referenced devices:'||errMsg);
	end if;

	-- remove the ones for which mapping has not changed
	delete from CDB_API_PARAMS CDB
		where I1 IN (SELECT C1.I1 FROM REFERENCES rf,CDB_API_PARAMS c1 where rf.refver=myConfId
		and c1.i1=rf.id and c1.i5=rf.ref_id);

	-- close IOVs for the existing logical devices
	UPDATE REFERENCES SET VALID_TO=now 
		where valid_to is null and refver=myConfId 
		and id in (SELECT I1 FROM CDB_API_PARAMS);
		-- close IOVS for referenced devices
		UPDATE REFERENCES SET VALID_TO=now 
		where valid_to is null and refver=myConfId
		and ref_id in (SELECT I5 FROM CDB_API_PARAMS);

		-- insert new ones
		INSERT INTO REFERENCES(refver,id,ref_id,valid_from,valid_to) 
			(select myConfId,i1,i5,now,null from cdb_api_params);
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
	delete from CDB_API_PARAMS;

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
	    select unique i.dpname from items i, config_items_new ci, config_desc cd
		where cd.conf_tag=configurationName
	            AND cd.conf_id=ci.tag_id
	            and ci.valid_to is null
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
    delete from CDB_API_PARAMS;
    
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
	    whereClause:=whereClause||' and r.recipe_type like '''||rtFilter||''' ';
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
    delete from CDB_API_PARAMS;
    
    -- make sure the filter is right
    if nameFilter = '' then nameFilter:='%'; end if;
    if nameFilter IS NULL then nameFilter:='%'; end if;

    insert into cdb_api_params(s1,s2) 
	select c.conf_tag, c.description 
	    from config_desc c
	    where c.conf_tag like replace(nameFilter,'*','%');


END;

---------------------------------------------
-- Input/Output is through the CDB_API_PARAMS table
-- the layout is:
--   I1 -> ITEM_ID
--    I2 -> CITEM_ID
--    I3 -> PARENT_ID
--    I4 -> DPID (Hardware hierarchy)
--   I5 -> REF ID (Logical hierarchy)
--    I7 -> DPType ID
--    I8 -> Flags that a device is new
--
--    S1 -> DEVICE DPNAME
--    S2 -> REF DPNAME (Logical hierarchy)
--    S3 -> TYPE (DPTYPE)
--    S4 -> DETAIL (MODEL)
--    S5 -> DEVICE NAME (short)
--    S6 -> PARENT DPNAME
--    S7 -> COMMENT
-----------------------------------------------
PROCEDURE saveItems( hierarchyType IN VARCHAR2)
IS
 myhver NUMBER;
 cnt NUMBER;
 errMsg VARCHAR2(2000);
BEGIN
	-- resolve hierarchyType into hver
	BEGIN
	SELECT HVER INTO myhver  FROM HIERARCHIES WHERE HTYPE=hierarchyType AND VALID_TO IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20009,'Unknown hierarchy type:'||hierarchyType);
	END;

	-- check that we have complete information about devices...
	errMsg:=null;
	if (hierarchyType='HARDWARE') then
	for rec in (
		select s1 DPNAME, s3 DPTYPE,  S4 MODEL,  S5 NAME,  S6 PARENT,  I4 DPID FROM CDB_API_PARAMS
			where s1 is null or s3 is null or  s5 is null or s6 is null or I4 is null
	) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';DPTYPE='||rec.dptype||';MODEL='||rec.model;
		errMsg:=errMsg||';NAME='||rec.name||';PARENT='||rec.parent||';DPID='||rec.DPID;
			exit when length(errMsg)>1900;
	end loop;
	elsif (hierarchyType='LOGICAL') then
		for rec in (
			select s1 DPNAME, s2 REFDPNAME, s3 DPTYPE,  S4 MODEL,  S5 NAME,  S6 PARENT  FROM CDB_API_PARAMS
			where s1 is null or s2 is null or s3 is null or s5 is null
		) loop
			errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';REFDPNAME='||rec.refdpname||';DPTYPE='||rec.dptype||';MODEL='||rec.model;
			errMsg:=errMsg||';NAME='||rec.name||';PARENT='||rec.parent;
			exit when length(errMsg)>1900;
		end loop;
	else
		RAISE_APPLICATION_ERROR(-20009,'Unsupported hierarchy type:'||hierarchyType);
	end if;
	if (errMsg is not null) then
         raise_application_error(-20010,'Incomplete information about new devices:'||errMsg);
	end if;

	-- check that there is no repeated entries (dp name is unique)
	errMsg:=null;
	for rec in (
		SELECT DPNAME, CNT FROM (
			select s1 DPNAME, count(*) CNT FROM CDB_API_PARAMS GROUP BY S1
		) WHERE CNT>1
	) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||'  Occurences='||rec.CNT;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
         raise_application_error(-20010,'Some of devices listed more than once:'||errMsg);
	end if;
	

	-- complete the DPType identifier into I7
	UPDATE CDB_API_PARAMS CDB 
		SET CDB.I7=(SELECT DPT_ID FROM DEVICE_TYPES DPT WHERE CDB.S3=DPT.dptype AND DPT.valid_to is null);

	-- check that we have all dptypes resolved...
	errMsg:=null;
	for rec in ( select s1 DPNAME, s3 DPTYPE FROM CDB_API_PARAMS where I7 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';DPTYPE='||rec.dptype;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
         raise_application_error(-20011,'Could not resolve DPTypes for devices:'||errMsg);
	end if;
		
	-- match devices that are already saved
	UPDATE CDB_API_PARAMS CDB SET CDB.I1=(SELECT I.ID FROM ITEMS I WHERE CDB.S1=I.DPNAME);
	
	-- ... and mark the new (non-existing) devices
	update cdb_api_params set i8=1 where i1 is null;

	
	 -- verify that the existing ones did not change...
	 errMsg:= null;
        for rec in (
		select i.dpname DPNAME, cdb.s1 DPNAME_NEW, i.type TYPE,cdb.s3 TYPE_NEW, i.detail MODEL, cdb.s4 MODEL_NEW, i.name NAME, cdb.s5 NAME_NEW 
		 from items i,cdb_api_params cdb 
                 where i.id=cdb.i1 and ( i.dpname != cdb.s1 OR  i.TYPE   != cdb.s3 OR i.detail != cdb.s4 OR i.name  != cdb.s5 )
	) loop
		errMsg:=errMsg||chr(13)||'DPNAME:'||rec.DPNAME||';TYPE:'||rec.type||'|'||rec.type_new||';MODEL:'||rec.model||'|'||rec.model_new||';NAME:'||rec.name||'|'||rec.name_new;
		exit when length(errMsg)>1900;
        end loop;	
	if (errMsg is not null) then
         raise_application_error(-20012,'Inconsistend information about devices:'||errMsg);
	end if;

	-- make sure that "root" nodes (corresponding to system names) exist, for all the DPs
	if (hierarchyType='HARDWARE') then

	INSERT INTO ITEMS(HVER,ID,NAME,TYPE,DETAIL,DPNAME)  
		select myHVER,ITEMS_ID_SEQ.NextVal,S.sysname,'SYSTEM','SYSTEM',S.sysname from 
		    (select unique(substr(S1,0,INSTR(S1,':'))) sysname from CDB_API_PARAMS )S
		where S.sysname not in (select i.dpname from items i where i.hver=myhver and parent is null);
   elsif (hierarchyType='LOGICAL') then
	INSERT INTO ITEMS(HVER,ID,NAME,TYPE,DETAIL,DPNAME)  
			SELECT myhver, ITEMS_ID_SEQ.NextVal,'/','SYSTEM','SYSTEM','' from dual
		where not exists (select ID from items i where i.hver=myhver and parent is null);
   end if;
        --generate new ITEM_IDs for the new ones...
        UPDATE CDB_API_PARAMS CDB SET CDB.I1=ITEMS_ID_SEQ.NextVal WHERE I8=1;
	
        -- resolve parent pointers for the new ones, based on their names; local lookup
        UPDATE CDB_API_PARAMS CDB SET CDB.I3=(SELECT CDB2.I1 FROM CDB_API_PARAMS CDB2 WHERE CDB2.S1=CDB.S6);
        
		if (hierarchyType='HARDWARE') then
        -- resolve parent pointers for the non-FW devices (hook them to parent)
        UPDATE CDB_API_PARAMS CDB 
			SET CDB.I3=(SELECT I.ID FROM ITEMS I WHERE I.DPNAME=CDB.S6 and i.hver=myhver) 
			WHERE CDB.I3 IS NULL;
		elsif (hierarchyType='LOGICAL') then
		-- resolve the logical ones - hook them to the common root
			UPDATE CDB_API_PARAMS CDB 
			SET CDB.I3=(SELECT I.ID FROM ITEMS I WHERE I.PARENT IS NULL and i.hver=myhver) 
	WHERE CDB.I3 IS NULL;
		end if;

	-- verify that we resolved all parent ids
	errMsg:=null;
	for rec in ( select s1 DPNAME, s6 PARENT FROM CDB_API_PARAMS where I3 is null) loop
		errMsg:=errMsg||chr(13)||'DPNAME='||rec.dpname||';PARENT='||rec.parent;
		exit when length(errMsg)>1900;
	end loop;
	if (errMsg is not null) then
         raise_application_error(-20013,'Could not resolve parents for devices:'||errMsg);
	end if;
	
       -- now we insert the new ones into the ITEMS table; we assume that type info is coherent
        INSERT INTO ITEMS(HVER,ID,PARENT,NAME,TYPE,DETAIL,DESCRIPTION,DPID,DPNAME,DPT_ID) 
             (SELECT  myhVer,I1,I3,S5,S3,S4,S7,I4,S1,I7 FROM CDB_API_PARAMS WHERE I8=1);

END;
PROCEDURE saveStaticConfiguration(configurationName IN VARCHAR2,
	hierarchyType In VARCHAR2)
IS
	errMsg VARCHAR2(2000);
	confId NUMBER;
	now date;
	myhver NUMBER;
	cnt NUMBER;
BEGIN
	select sysdate into now from dual;

	-- resolve hierarchyType into hver
	BEGIN
	SELECT HVER INTO myhver  FROM HIERARCHIES WHERE HTYPE=hierarchyType AND VALID_TO IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20009,'Unknown hierarchy type:'||hierarchyType);
	END;
	-- check/create new configuration
	BEGIN
		SELECT CONF_ID INTO ConfId FROM CONFIG_DESC WHERE CONF_TAG=configurationName;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		SELECT CONF_ID_SEQ.NextVal INTO ConfId FROM DUAL;
		INSERT INTO CONFIG_DESC(CONF_ID,CONF_TAG) VALUES (ConfId,configurationName);
	END;
	if hierarchyType='LOGICAL' then
		setReferences(configurationName);
	
	elsif hierarchyType='HARDWARE' then
	-- treat "FwNode"
	DELETE FROM CDB_API_PARAMS WHERE S3='FwNode';
		
	-- Generate new CITEM_ID, set it in CDB_API_PARAMS
	UPDATE CDB_API_PARAMS CDB SET CDB.I2=CITEM_ID_SEQ.NextVal;
	-- close the interval of validity for the existing items that match the stored ones...
	UPDATE CONFIG_ITEMS_NEW SET VALID_TO=now 
		where valid_to is null and tag_id=confId 
		and item_id in (SELECT I1 FROM CDB_API_PARAMS);
	 
	 -- store new CITEMs in CONFIG_ITEMS_NEW
	INSERT INTO CONFIG_ITEMS_NEW(ITEM_ID,CITEM_ID,VALID_FROM,TAG_ID,DPT_ID) 
		(SELECT I1,I2,now,confId,I7 FROM CDB_API_PARAMS);


	-- generate the PROPERTIES (DPEs), and their IDs, and insert them into BOTH
	-- the TMP_ITEM_PROPS and into CONFIG_ITEMPROPS (!)
	INSERT ALL 
		INTO CONFIG_ITEMPROPS(IPROP_ID, CITEM_ID, DEVELEM_ID) 
			VALUES(IPROP_ID_SEQ.NextVal,CITEM_ID,DEVELEM_ID)
		INTO TMP_ITEM_PROPS(IPROP_ID, DPENAME) 
			VALUES(IPROP_ID_SEQ.CurrVal,DPENAME)
	SELECT CDB.I2 CITEM_ID, EL.DEVELEM_ID DEVELEM_ID, CDB.S1||EL.ELEMENTNAME DPENAME 
		FROM CDB_API_PARAMS CDB, DEVICE_ELEMENTS EL 
		WHERE EL.DPT_ID=CDB.I7;
	else
		raise_application_error(-20000,'Unsupported hierarchy type:'||hierarchyType);
	end if;
END;

function getSummaryAlerts return sumAlertTableType pipelined
as
PRAGMA AUTONOMOUS_TRANSACTION; -- this to be able to do inserts/updates
rc number;
idlist varchar2(4000);
dpelist varchar2(4000);
idx pls_integer;
begin
delete from cdb_api_params;
commit;
for rec in (select csa.iprop_id IPROP_ID, csa.sumdpelist SUMDPEIDS from config_sumalerts csa, tmp_item_props tip where csa.iprop_id=tip.iprop_id) loop
   idlist:=rec.SUMDPEIDS;
   if substr(idlist,1,8)='PATTERN:' then
   	-- note: we mark that it is a pattern in the I3 column
	insert into cdb_api_params(i1,i3,s4) values (rec.IPROP_ID,1,substr(idlist,9));
   elsif idlist is not null then
   loop
      idx :=instr(idlist,'|');
      if idx=0 then
      idx :=instr(idlist,',');
      end if;
      if idx > 0 then
        insert into cdb_api_params(i1,i5) values (rec.IPROP_ID,substr(idlist,1,idx-1));
	idlist:=substr(idlist,idx+1);
      else
        insert into cdb_api_params(i1,i5) values (rec.IPROP_ID,idlist);
	exit;
      end if;
  end loop;
  end if;
  end loop;
update cdb_api_params cda set cda.s2=(SELECT DPENAME FROM TMP_ITEM_PROPS TIP WHERE cda.i5=TIP.IPROP_ID) ;
commit;
 ----- firstly pipe rows with 'PATTERN:' dpelist
for rec in (select c1.i1 IPROPID, c1.s4 SUMDPELIST from cdb_api_params c1 where c1.i3=1) loop
    pipe row (sumAlertObject(rec.IPROPID,1,rec.SUMDPELIST));
end loop;
----- then pipe rows with translated list; note that we will not include unresolved ones 
 for rec2 in (select c1.i1 IPROPID, LSTAGG(S2) SUMDPELIST from cdb_api_params c1 where s2 is not null group by c1.i1) loop
 dpelist:=replace(rec2.SUMDPELIST,',','|');
  pipe row (sumAlertObject(rec2.IPROPID,0,dpelist));
 end loop;
commit;
 return;
end;

-- Everything goes via CDB_API_PARAMS
-- S1 -> DPType Name
-- S2 -> Element Name
-- I3 -> Element type
FUNCTION checkSaveDpTypes return number
IS
BEGIN

    --resolve known types
    update cdb_api_params cdb set i1=  (select dpt_id from DEVICE_TYPES where dptype=cdb.s1 and valid_to is null);

    --identify the types that have an element deleted; mark with i8=2
    update cdb_api_params set i8=2 where s1 in (
	select unique(dptype) from V_DEVICE_CONFIGS DC 
	WHERE DC.dptype in (
		select unique(s1) from cdb_api_params cdb1) 
	and not exists(select * from CDB_API_PARAMS CDB2 where cdb2.s1(+)=dc.dptype and cdb2.s2=dc.elementname));

    -- identify the elements(!) that are new or changed the type; identify the new ones as well; mark with i7=1
    update cdb_api_params cdb set i7=1 where not exists 
	(select * from v_device_configs dc where dc.dptype=cdb.s1 and dc.elementname=cdb.s2 and dc.elementtype=cdb.i3);
    -- propagate this info to all elements in the type (even those that match...)
    update cdb_api_params cdb set i7=1 where s1 in(select unique(s1) from CDB_API_PARAMS WHERE i7=1);

    -- clean up the ones that match
    delete from cdb_api_params where i1 is not null and i7 is null and i8 is null;

    -- invalidate the existing ones that have to be updated
    update device_types set valid_to=sysdate where dpt_id in (select unique(i1) from CDB_API_PARAMS);

    -- insert new types
    insert into device_types(DPTYPE,DPT_ID) 
	select S1 DPTYPE,DPT_ID_SEQ.NextVal DPT_ID from (select s1 from cdb_api_params group by s1);

    -- now complete the CDB_API_PARAMS with this info
    update cdb_api_params cdb set i1=(select dpt_id from device_types where dptype=cdb.s1 and valid_to is null);

    --generate element ids
    update cdb_api_params cdb set i2=DEVELEM_ID_SEQ.NextVal;

    -- transfer the data into DEVICE_ELEMENTS
    insert into device_elements(DEVELEM_ID,DPT_ID,ELEMENTNAME,ELEMENTTYPE) SELECT i2,i1,s2,i3 from cdb_api_params;
    
    return 0;
END;


END fwConfigurationDB;
/

CREATE or replace FUNCTION fwConfigurationDB_grant(userOrRole varchar2,
						   what varchar2,
						   revokeMode number default 0 )   RETURN number 
is
    stmt1 varchar2(128);
    stmt2 varchar2(128);
    already_granted exception;
    grant_to_self exception;
    PRAGMA EXCEPTION_INIT(already_granted,-1927);
    PRAGMA EXCEPTION_INIT(grant_to_self,-1749);

begin
    if ( what != 'READER' AND what != 'WRITER' AND what != 'ALL') then
	raise_application_error(-20010,'fwConfigurationDB_grant: bad value for the WHAT parameter:'||what);
	return 1;
    end if;

    if ( revokeMode != 0) then
	stmt1 := ' REVOKE ';
	stmt2 := ' FROM ';
    else
	stmt1 := ' GRANT ';
	stmt2 := ' TO ';
    end if;

    -- whether the WHAT is READER,WRITERor ALL we grant all the read-related grants...
	execute immediate stmt1||'SELECT  ON HIERARCHIES            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON DEVICE_TYPES           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON ITEMS                  '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPES                '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPE_VERSIONS        '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPE_DATA            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON RECIPE_TAGS            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON DEVICE_ELEMENTS        '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ITEMS_NEW       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ITEMPROPS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_DESC            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON REFERENCES             '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_VALUES          '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_VALUES_BIG      '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ADDRESSES       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ALERTS          '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_DPEALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_SUMALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ALERTS_MISC     '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_ARCHIVING       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_DPFUNCTIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_CONVERSIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_PVRANGES        '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_SMOOTHING       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_UF              '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON CONFIG_GENERAL         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_RECIPESALL           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_REFERENCES           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_CONFIG_ITEMS         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_DEVICE_CONFIGS       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_DEVICE_CONFIGS_ALL   '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_ITEM_PROPERTIES      '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  ON V_CONFIG_ALERTS        '||stmt2||userOrRole;
	execute immediate stmt1||'ALL     ON CDB_API_PARAMS         '||stmt2||userOrRole;
	execute immediate stmt1||'ALL     ON TMP_ITEM_PROPS         '||stmt2||userOrRole;
	execute immediate stmt1||'EXECUTE ON fwConfigurationDB      '||stmt2||userOrRole;
	execute immediate stmt1||'EXECUTE ON lstAgg                 '||stmt2||userOrRole;
	execute immediate stmt1||'EXECUTE ON lstAggNum              '||stmt2||userOrRole;

    if ( what = 'WRITER' OR what = 'ALL' ) then 

	execute immediate stmt1||'INSERT,UPDATE         ON HIERARCHIES            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON DEVICE_TYPES           '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON ITEMS                  '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPES                '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPE_VERSIONS        '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPE_DATA            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE,DELETE  ON RECIPE_TAGS            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON DEVICE_ELEMENTS        '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ITEMS_NEW       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ITEMPROPS      '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_DESC            '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON REFERENCES             '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_VALUES          '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_VALUES_BIG      '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ADDRESSES       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ALERTS          '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_DPEALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_SUMALERTS       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ALERTS_MISC     '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_ARCHIVING       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_DPFUNCTIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_CONVERSIONS     '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_PVRANGES        '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_SMOOTHING       '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_UF              '||stmt2||userOrRole;
	execute immediate stmt1||'INSERT,UPDATE         ON CONFIG_GENERAL         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON CITEM_ID_SEQ           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON CONF_ID_SEQ            '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON DEVELEM_ID_SEQ         '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON DPT_ID_SEQ             '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON IPROP_ID_SEQ           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON ITEMS_ID_SEQ           '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON RECIPES_RVER_SEQ       '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON RECIPES_TAGID_SEQ      '||stmt2||userOrRole;
	execute immediate stmt1||'SELECT  		ON RECIPE_DATA_PROPID_SEQ '||stmt2||userOrRole;

    end if;

    return 0;
exception
  when already_granted then
       -- we simply accept it
       return 0;
  when grant_to_self then
       -- we simply accept it
       return 0;
end;
/
----------------------------------------------------------------------------
-- as the last element we create our "internal" view, which
-- is used to determine if the schema exists.
----------------------------------------------------------------------------


DECLARE
    NOW VARCHAR2(32);
    VERS VARCHAR(32);
BEGIN
NOW:=TO_CHAR(SYSTIMESTAMP,'YYYY-MM-DD HH24:MI:SS');
VERS:=TO_CHAR(3.02,'9.99');
EXECUTE IMMEDIATE ' CREATE OR REPLACE VIEW v_confdb (SCHEMA_VERSION,SCHEMA_CREATED)'||
    ' AS SELECT '''||VERS||''', '''||NOW||''' FROM DUAL';
END;
/

GRANT SELECT  ON V_CONFDB TO PUBLIC;
