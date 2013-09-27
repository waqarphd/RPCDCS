declare 
 type table_varchar is table of varchar2(1024);
 type table_errnum is table of number;
 stmts table_varchar;
 stmt varchar2(1024);
 errStmts table_varchar:=table_varchar();
 errMsgs table_varchar:=table_varchar();
procedure throwErrorMessages IS
nErr number;
errMsg varchar2(4000);
BEGIN
nErr:=errStmts.COUNT;
if (nErr=0) then return; end if;
errMsg:='Errors ('||nErr||'):';
for i in 1 .. nErr loop
errMsg:=errMsg||chr(10)||i||'#';
errMsg:=errMsg||errMsgs(i)||' @ '||errStmts(i);
end loop;
RAISE_APPLICATION_ERROR(-20000,errMsg);
END;   
procedure executeStatements(statements in table_varchar,
			    ignoredErrors in table_errnum,
			    raiseException in boolean default false) IS
nErr number;
BEGIN
for i in 1 .. statements.count loop
    stmt:=statements(i);
    begin
      execute immediate stmt;
    exception      
      when others then 
	if SQLCODE member of ignoredErrors then null; 
	else 
		errStmts.EXTEND;
		errMsgs.extend;
		nErr:=errStmts.COUNT;
		errStmts(nErr):=stmt;
		errMsgs(nErr):=SQLERRM;
		
		if raiseException then throwErrorMessages;
		
		end if;
	end if;
     end;
  end loop;
END;   
begin

-------- DROP SCHEMA COMMANDS START HERE:

-- firstly make sure that temp tables are empty, and then drop them
executeStatements(
  table_varchar(
    'truncate table cdb_api_params',
    'truncate table tmp_item_props',
    'drop index tip_dpe_idx',
    'drop INDEX tip_ipropd_idx',
    'delete from tmp_item_props',
    'delete from CDB_API_PARAMS')
      ,table_errnum(-942,-1418),false);

-- drop roles
executeStatements(
  table_varchar(
    'drop role '||'r_fwConfR_'||USER,
    'drop role '||'r_fwConfW_'||USER
  ),table_errnum(-1919,-1031),false);

-- drop the code
executeStatements(
  table_varchar(
    'DROP PACKAGE fwConfigurationDB',
    'DROP FUNCTION fwConfigurationDB_grant'
  ),table_errnum(-4043),false);

-- drop types
executeStatements(
  table_varchar(
    'drop type sumAlertTableType',
    'drop type sumAlertObject'
  ),table_errnum(-4043),false);

-- drop views
executeStatements(
  table_varchar(
    'DROP VIEW  v_recipesAll CASCADE CONSTRAINTS',
    'DROP TABLE recipe_tags CASCADE CONSTRAINTS',
    'DROP TABLE recipe_data CASCADE CONSTRAINTS',
    'DROP TABLE recipe_versions CASCADE CONSTRAINTS',
    'DROP TABLE recipes CASCADE CONSTRAINTS',
    'DROP TABLE references CASCADE CONSTRAINTS',
    'DROP TABLE tmp_item_props',
    'DROP TABLE CDB_API_PARAMS',
    'DROP VIEW V_REFERENCES',
    'DROP VIEW V_CONFIG_ITEMS',
    'DROP VIEW V_CONFIG_ALERTS',
    'DROP VIEW V_DEVICE_CONFIGS',
    'DROP VIEW V_DEVICE_CONFIGS_ALL',
    'DROP VIEW V_ITEM_PROPERTIES'
  ),table_errnum(-942),false);

-- drop comma-separated-list functions
executeStatements(
  table_varchar(
    'DROP FUNCTION LSTAGG',
    'DROP FUNCTION LSTAGGNUM',
    'DROP TYPE LIST_AGG_TYPE'
  ),table_errnum(-4043),false);

-- drop tables
executeStatements(
  table_varchar(
    'DROP TABLE CONFIG_GENERAL CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_UF CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_SMOOTHING CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_PVRANGES CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_CONVERSIONS CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_DPFUNCTIONS CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ARCHIVING CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ADDRESSES CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_SUMALERTS CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_DPEALERTS CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ALERTS_MISC CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ALERTS CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_VALUES_BIG CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_VALUES CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_DESC CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ITEMPROPS CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ITEMS_NEW CASCADE CONSTRAINTS',
    'DROP TABLE DEVICE_TYPES CASCADE CONSTRAINTS',
    'DROP TABLE DEVICE_ELEMENTS CASCADE CONSTRAINTS',
    'DROP TABLE OLD_CONFIG_ITEM_PROPERTIES CASCADE CONSTRAINTS',
    'DROP TABLE OLD_CONFIG_TAGS CASCADE CONSTRAINTS',
    'DROP TABLE OLD_CONFIG_ITEMS CASCADE CONSTRAINTS',
    -- eventually, if there is some remnant from non-clean update...
    'DROP VIEW V_ITEMS CASCADE CONSTRAINTS',
    'DROP VIEW V_ITEM_NAMES CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_TAGS CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ITEM_PROPERTIES CASCADE CONSTRAINTS',
    'DROP TABLE CONFIG_ITEMS CASCADE CONSTRAINTS'
  ),table_errnum(-942),false);

-- drop sequences
executeStatements(
  table_varchar(
    'DROP SEQUENCE CONF_ID_SEQ',
    'DROP SEQUENCE CITEM_ID_SEQ',
    'DROP SEQUENCE DEVELEM_ID_SEQ',
    'DROP SEQUENCE DPT_ID_SEQ',
    'DROP SEQUENCE IPROP_ID_SEQ',
    'DROP SEQUENCE items_id_seq',
    'DROP SEQUENCE RECIPES_RVER_SEQ',
    'DROP SEQUENCE RECIPES_TAGID_SEQ',
    'DROP SEQUENCE recipe_data_propid_seq'
  ),table_errnum(-2289),false);

-- drop the final part of tables
executeStatements(
  table_varchar(
    'DROP TABLE items CASCADE CONSTRAINTS',
    'DROP TABLE hierarchies CASCADE CONSTRAINTS'
  ),table_errnum(-942),false);


-- drop the view that identifies the fwConfigurationDB version
executeStatements(
  table_varchar(
    'DROP VIEW  v_confdb CASCADE CONSTRAINTS'
  ),table_errnum(-942),false);

-- handle all error messages:
throwErrorMessages;
end;

/
